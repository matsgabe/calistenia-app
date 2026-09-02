import 'package:flutter/material.dart';
import 'treino_repository.dart';

class HistoricoScreen extends StatefulWidget {
  final int usuarioId;
  const HistoricoScreen({super.key, required this.usuarioId});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _repository = TreinoRepository();
  List<Map<String, dynamic>> _historico = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    try {
      final dados = await _repository.buscarHistoricoTreinos(widget.usuarioId);
      if (mounted) {
        setState(() {
          _historico = dados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatarData(String dataString) {
    final data = DateTime.parse(dataString).toLocal();
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDuracao(int segundos) {
    final m = (segundos / 60).floor();
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    if (_historico.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino concluído ainda.\nBora treinar!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historico.length,
      itemBuilder: (context, index) {
        final treino = _historico[index];
        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.greenAccent),
            ),
            title: Text(
              'Treino: ${treino['tipo_treino'] ?? 'Geral'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatarData(treino['data_realizacao']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatarDuracao(treino['duracao_segundos'] ?? 0),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
