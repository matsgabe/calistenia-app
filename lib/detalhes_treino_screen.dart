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
  bool _concluindo = false;

  Future<void> _concluirTreino() async {
    setState(() => _concluindo = true);
    try {
      final repository = UsuarioRepository();
      await repository.registrarTreinoConcluido(widget.usuarioId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino concluído com sucesso! Bom descanso 🏆'),
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
        widget.dadosPlano['treino_sugerido_nome'] ?? 'Treino Personalizado';
    final descricaoTreino =
        widget.dadosPlano['treino_descricao'] ??
        'Série focada em calistenia segura.';
    final analiseTreino =
        widget.dadosPlano['analise_treino'] ??
        widget.dadosPlano['resumo_analise'] ??
        'Diretrizes de treino estruturadas.';
    final exercicios = (widget.dadosPlano['exercicios'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(nomeTreino, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Diretrizes do Personal IA',
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              descricaoTreino,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
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
                          'Como executar:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ex['instrucoes'] ??
                              'Execute o movimento mantendo a postura firme.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _concluindo ? null : _concluirTreino,
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
                        'CONCLUIR TREINO DE HOJE 🏆',
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
      ),
    );
  }
}
