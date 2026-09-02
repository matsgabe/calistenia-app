import 'dart:async';
import 'package:flutter/material.dart';
import 'treino_repository.dart';

class TreinoScreen extends StatefulWidget {
  final int usuarioId;
  const TreinoScreen({super.key, required this.usuarioId});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  int _segundosTotais = 0;
  Timer? _timerGlobal;

  int _tempoDescanso = 0;
  Timer? _timerDescanso;
  bool _emDescanso = false;

  bool _isLoading = false;

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
      _tempoDescanso = 60;
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

  bool get _treinoCompleto {
    for (var exercicio in _exercicios) {
      List<bool> concluidas = exercicio['concluidas'];
      if (concluidas.contains(false)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _finalizarTreino() async {
    setState(() => _isLoading = true);

    try {
      final repository = TreinoRepository();

      final treinoId = await repository.salvarSessaoTreino(
        usuarioId: widget.usuarioId,
        tipoTreino: 'Push',
        duracaoSegundos: _segundosTotais,
      );

      await repository.salvarDetalhesExercicios(
        treinoId: treinoId,
        exercicios: _exercicios,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino salvo com sucesso! 💪')),
        );
        Navigator.pop(context);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text('Cancelar treino?'),
            content: const Text(
              'Se você voltar para a Home agora, perderá as marcações que fez neste treino.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  false,
                ),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text(
                  'SAIR',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );

        if (sair == true && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize
                .min,
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
          centerTitle: true,
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                                activeColor: Colors.greenAccent,
                                checkColor: Colors.black,
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              key: const Key('btn_finalizar_treino'),
              onPressed: (_treinoCompleto && !_isLoading)
                  ? _finalizarTreino
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'FINALIZAR TREINO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ), 
          ), 
        ), 
      ), 
    ); 
  }
}
