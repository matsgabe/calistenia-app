import 'dart:async';

import 'package:flutter/material.dart';

import 'treino_repository.dart'; // Import do novo repositório

class TreinoScreen extends StatefulWidget {
  final int usuarioId;
  const TreinoScreen({super.key, required this.usuarioId});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  // Timers
  int _segundosTotais = 0;
  Timer? _timerGlobal;

  int _tempoDescanso = 0;
  Timer? _timerDescanso;
  bool _emDescanso = false;

  bool _isLoading = false;

  // Mock de dados: O treino puxado do banco virá neste formato
  final List<Map<String, dynamic>> _exercicios = [
    {
      'id': 1,
      'nome': 'Flexão com Joelhos',
      'series': 3,
      'reps': '10 a 12',
      'concluidas': [false, false, false],
    },
    {
      'id': 2,
      'nome': 'Prancha Alta',
      'series': 3,
      'reps': '30 seg',
      'concluidas': [false, false, false],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarTimerGlobal();
  }

  @override
  void dispose() {
    _timerGlobal?.cancel();
    _timerDescanso?.cancel();
    super.dispose();
  }

  void _iniciarTimerGlobal() {
    _timerGlobal = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _segundosTotais++);
    });
  }

  void _iniciarDescanso() {
    _timerDescanso?.cancel();
    setState(() {
      _tempoDescanso = 60; // 60 segundos de descanso padrão
      _emDescanso = true;
    });

    _timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_tempoDescanso > 0) {
          _tempoDescanso--;
        } else {
          _emDescanso = false;
          timer.cancel();
        }
      });
    });
  }

  String _formatarTempo(int segundos) {
    final m = (segundos / 60).floor().toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _marcarSerie(int exercicioIndex, int serieIndex, bool? value) {
    setState(() {
      _exercicios[exercicioIndex]['concluidas'][serieIndex] = value ?? false;
    });

    if (value == true) {
      _iniciarDescanso();
    }
  }

  // NOVO: Função que orquestra a gravação no Supabase
  Future<void> _finalizarTreino() async {
    setState(() => _isLoading = true);

    try {
      final repository = TreinoRepository();

      // 1. Grava a sessão (cabeçalho)
      final treinoId = await repository.salvarSessaoTreino(
        usuarioId: widget.usuarioId,
        tipoTreino: 'Push', // Fixo neste momento, será dinâmico depois
        duracaoSegundos: _segundosTotais,
      );

      // 2. Grava as linhas de cada exercício
      await repository.salvarDetalhesExercicios(
        treinoId: treinoId,
        exercicios: _exercicios,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino salvo com sucesso! 💪')),
        );
        Navigator.pop(context); // Volta para a Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar treino: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 20),
            const SizedBox(width: 8),
            Text(
              _formatarTempo(_segundosTotais),
              key: const Key('timer_global_treino'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // NOVO: Substitui o botão por um indicador de carregamento se estiver salvando
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.redAccent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  key: const Key('btn_finalizar_treino'),
                  onPressed: _finalizarTreino,
                  child: const Text(
                    'FINALIZAR',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          if (_emDescanso)
            Container(
              key: const Key('painel_descanso'),
              width: double.infinity,
              color: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Text(
                    'DESCANSO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatarTempo(_tempoDescanso),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercicios.length,
              itemBuilder: (context, index) {
                final exercicio = _exercicios[index];
                final idExercicio = exercicio['id'];

                return Card(
                  key: Key('card_exercicio_$idExercicio'),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    title: Text(
                      exercicio['nome'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Meta: ${exercicio['series']}x ${exercicio['reps']}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: List.generate(exercicio['series'], (
                            serieIndex,
                          ) {
                            final isConcluida =
                                exercicio['concluidas'][serieIndex];
                            return CheckboxListTile(
                              key: Key(
                                'check_exercicio_${idExercicio}_serie_$serieIndex',
                              ),
                              title: Text('Série ${serieIndex + 1}'),
                              subtitle: Text(exercicio['reps']),
                              value: isConcluida,
                              activeColor: Colors.deepPurpleAccent,
                              tileColor: isConcluida
                                  ? Colors.white10
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged: (value) =>
                                  _marcarSerie(index, serieIndex, value),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
