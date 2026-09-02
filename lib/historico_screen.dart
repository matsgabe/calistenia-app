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
  List<Map<String, dynamic>> _historico = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    try {
      final response = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', widget.usuarioId);

      if (mounted) {
        setState(() {
          _historico = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    final totalTreinos = _historico.length;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
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
                    '$totalTreinos',
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
                    totalTreinos > 0 ? 'Em Chamas 🔥' : 'Iniciando',
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
          'Jornada de Calistenia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _historico.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Nenhum treino concluído ainda. Conclua o seu primeiro na Home! 🏆',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historico.length,
                itemBuilder: (context, index) {
                  final item = _historico[index];
                  final rawDate =
                      item['data_registro'] ?? item['created_at'] ?? '';
                  String dataFormatada = 'Data recente';

                  if (rawDate.isNotEmpty) {
                    try {
                      final parsedDate = DateTime.parse(rawDate.toString());
                      final dia = parsedDate.day.toString().padLeft(2, '0');
                      final mes = parsedDate.month.toString().padLeft(2, '0');
                      final ano = (parsedDate.year % 100).toString().padLeft(
                        2,
                        '0',
                      );
                      dataFormatada = '$dia/$mes/$ano';
                    } catch (_) {
                      dataFormatada = rawDate.toString();
                    }
                  }

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.greenAccent,
                        child: Icon(Icons.check, color: Colors.black),
                      ),
                      title: const Text(
                        'Sessão de Calistenia Concluída',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Data: $dataFormatada',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
