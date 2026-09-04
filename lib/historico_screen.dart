import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoricoScreen extends StatefulWidget {
  final int usuarioId;
  const HistoricoScreen({super.key, required this.usuarioId});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _historicoCombinado = [];
  int _totalTreinos = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    try {
      // 1. Busca os TREINOS REAIS
      final treinosResponse = await _supabase
          .from('treinos_realizados')
          .select()
          .eq('usuario_id', widget.usuarioId);

      // 2. Busca as REFEIÇÕES
      final refeicoesResponse = await _supabase
          .from('consumo_alimentar')
          .select()
          .eq('usuario_id', widget.usuarioId);

      List<Map<String, dynamic>> tempHistorico = [];

      // Adiciona os treinos à lista combinada
      for (var t in treinosResponse) {
        tempHistorico.add({
          'tipo': 'treino',
          'data': t['data_realizacao'] ?? t['created_at'],
          'titulo': 'Sessão de Calistenia Concluída',
          'subtitulo': 'Duração: ${(t['duracao_segundos'] ?? 1800) ~/ 60} min',
          'icone': Icons.fitness_center,
          'cor': Colors.greenAccent,
        });
      }

      // Adiciona as refeições à lista combinada
      for (var r in refeicoesResponse) {
        tempHistorico.add({
          'tipo': 'refeicao',
          'data': r['data_registro'] ?? r['created_at'],
          'titulo': r['nome_refeicao'] ?? 'Refeição Registrada',
          'subtitulo': '${r['calorias']} kcal consumidas',
          'icone': Icons.restaurant,
          'cor': Colors.orangeAccent,
        });
      }

      // Ordena a lista da data mais recente para a mais antiga
      tempHistorico.sort((a, b) {
        final dateA = a['data']?.toString() ?? '';
        final dateB = b['data']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _historicoCombinado = tempHistorico;
          _totalTreinos =
              treinosResponse.length; // O contador usa APENAS treinos
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatarData(String rawDate) {
    if (rawDate.isEmpty) return 'Data recente';
    try {
      final parsedDate = DateTime.parse(rawDate);
      final dia = parsedDate.day.toString().padLeft(2, '0');
      final mes = parsedDate.month.toString().padLeft(2, '0');
      final ano = (parsedDate.year % 100).toString().padLeft(2, '0');
      final hora = parsedDate.hour.toString().padLeft(2, '0');
      final min = parsedDate.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$ano às $hora:$min';
    } catch (_) {
      return rawDate.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- BANNER DE ESTATÍSTICAS ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.military_tech,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalTreinos',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Treinos Concluídos',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade800),
              Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalTreinos > 0 ? 'Em Chamas 🔥' : 'Iniciando',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Status de Constância',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Timeline de Atividades',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // --- LISTAGEM DO HISTÓRICO ---
        _historicoCombinado.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Nenhuma atividade ainda. Faça um treino ou registre uma refeição! 🏆',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historicoCombinado.length,
                itemBuilder: (context, index) {
                  final item = _historicoCombinado[index];

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: item['cor'].withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item['cor'].withOpacity(0.2),
                        child: Icon(item['icone'], color: item['cor']),
                      ),
                      title: Text(
                        item['titulo'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item['subtitulo'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatarData(item['data'].toString()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
