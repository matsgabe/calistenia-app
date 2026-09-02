import 'dart:async';

import 'package:flutter/material.dart';

import 'usuario_repository.dart';

class DetalhesTreinoScreen extends StatefulWidget {
  final Map<String, dynamic> dadosPlano;
  final int usuarioId;

  const DetalhesTreinoScreen({
    super.key,
    required this.dadosPlano,
    required this.usuarioId,
  });

  @override
  State<DetalhesTreinoScreen> createState() => _DetalhesTreinoScreenState();
}

class _DetalhesTreinoScreenState extends State<DetalhesTreinoScreen> {
  bool _treinoIniciado = false;
  bool _emDescanso = false;
  bool _concluindo = false;

  // Conjunto para armazenar os índices dos exercícios já concluídos
  final Set<int> _exerciciosConcluidos = {};

  // Timers
  Timer? _timerSessao;
  int _segundosTotais = 0;

  Timer? _timerDescanso;
  int _segundosDescansoRestantes = 45;

  @override
  void dispose() {
    _timerSessao?.cancel();
    _timerDescanso?.cancel();
    super.dispose();
  }

  void _iniciarTreino() {
    setState(() {
      _treinoIniciado = true;
    });
    _timerSessao = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segundosTotais++;
      });
    });
  }

  void _concluirExercicio(int index) {
    setState(() {
      _exerciciosConcluidos.add(index);
    });
    _iniciarDescanso();
  }

  void _iniciarDescanso() {
    setState(() {
      _emDescanso = true;
      _segundosDescansoRestantes = 45;
    });

    _timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosDescansoRestantes > 0) {
        setState(() {
          _segundosDescansoRestantes--;
        });
      } else {
        _timerDescanso?.cancel();
        setState(() {
          _emDescanso = false;
        });
      }
    });
  }

  String _formatarTempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  Future<void> _finalizarTreinoCompleto() async {
    _timerSessao?.cancel();
    setState(() => _concluindo = true);

    try {
      final repository = UsuarioRepository();
      await repository.registrarTreinoConcluido(widget.usuarioId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sessão de Calistenia finalizada com sucesso! Vitória 🏆',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao registrar treino: $e')));
      }
    } finally {
      if (mounted) setState(() => _concluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeTreino =
        widget.dadosPlano['treino_sugerido_nome'] ??
        'Treino de Calistenia Corporal';
    final descricaoTreino =
        widget.dadosPlano['treino_descricao'] ??
        'Treino focado exclusivamente no peso corporal.';
    final analiseTreino =
        widget.dadosPlano['analise_treino'] ??
        widget.dadosPlano['resumo_analise'] ??
        'Diretrizes de biomecânica.';
    final exercicios = (widget.dadosPlano['exercicios'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(nomeTreino, style: const TextStyle(fontSize: 15)),
        backgroundColor: Colors.transparent,
        actions: [
          if (_treinoIniciado)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '⏱️ ${_formatarTempo(_segundosTotais)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Calistenia Corporal (Sem Equipamentos)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analiseTreino,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                nomeTreino,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descricaoTreino,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              if (!_treinoIniciado)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _iniciarTreino,
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text(
                      'INICIAR SESSÃO DE CALISTENIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Text(
                'Exercícios do Dia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercicios.length,
                itemBuilder: (context, index) {
                  final ex = exercicios[index];
                  final bool jaConcluido = _exerciciosConcluidos.contains(
                    index,
                  );

                  return Card(
                    color: jaConcluido
                        ? Colors.grey.shade900.withOpacity(0.6)
                        : Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: jaConcluido
                          ? BorderSide(
                              color: Colors.greenAccent.withOpacity(0.4),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${index + 1}. ${ex['nome'] ?? 'Exercício'}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: jaConcluido
                                        ? Colors.grey
                                        : Colors.greenAccent,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${ex['series'] ?? '3'} séries × ${ex['repeticoes'] ?? '10'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Como executar (Peso Corporal):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ex['instrucoes'] ??
                                'Mantenha a postura e contração abdominal.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: Colors.white70,
                            ),
                          ),

                          if (_treinoIniciado) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: jaConcluido
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.greenAccent,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Concluído',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: _emDescanso
                                          ? null
                                          : () => _concluirExercicio(index),
                                      icon: const Icon(Icons.timer, size: 16),
                                      label: const Text(
                                        'Concluir Série / Descansar',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.greenAccent,
                                        side: const BorderSide(
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              if (_treinoIniciado)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _concluindo ? null : _finalizarTreinoCompleto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _concluindo
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'FINALIZAR TREINO E SALVAR 🏆',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),

          if (_emDescanso)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_bottom,
                      size: 64,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TEMPO DE DESCANSO',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_segundosDescansoRestantes}s',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _timerDescanso?.cancel();
                        setState(() => _emDescanso = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pular Descanso'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
