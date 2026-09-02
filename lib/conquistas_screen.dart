import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConquistasScreen extends StatefulWidget {
  final int usuarioId;
  const ConquistasScreen({super.key, required this.usuarioId});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  int _totalTreinos = 0;
  int _sequenciaDias = 0;

  @override
  void initState() {
    super.initState();
    _carregarDadosConquistas();
  }

  Future<void> _carregarDadosConquistas() async {
    try {
      final response = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', widget.usuarioId);

      final historico = List<Map<String, dynamic>>.from(response);
      _totalTreinos = historico.length;

      // Lógica simples de cálculo de dias únicos consecutivos ou total
      _sequenciaDias =
          _totalTreinos; // Pode ser refinado para dias únicos se desejar

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    // Definição das Badges/Conquistas
    final conquistas = [
      {
        'titulo': 'Primeiro Passo',
        'descricao': 'Conclua o seu primeiro treino de calistenia.',
        'icone': Icons.emoji_events,
        'desbloqueada': _totalTreinos >= 1,
      },
      {
        'titulo': 'Ritmo Constante',
        'descricao': 'Acumule 5 treinos concluídos na jornada.',
        'icone': Icons.local_fire_department,
        'desbloqueada': _totalTreinos >= 5,
      },
      {
        'titulo': 'Patamar Intermediário',
        'descricao': 'Chegue a 10 treinos de calistenia finalizados.',
        'icone': Icons.military_tech,
        'desbloqueada': _totalTreinos >= 10,
      },
      {
        'titulo': 'Mestre da Calistenia',
        'descricao': 'Alcance a marca de 15 treinos registrados.',
        'icone': Icons.workspace_premium,
        'desbloqueada': _totalTreinos >= 15,
      },
      {
        'titulo': 'Lenda do Bodyweight',
        'descricao': 'Complete 30 treinos e domine o peso corporal.',
        'icone': Icons.verified,
        'desbloqueada': _totalTreinos >= 30,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Conquistas e Insígnias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Banner Resumo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.military_tech,
                      color: Colors.amber,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalTreinos',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total de Treinos',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade800),
                Column(
                  children: [
                    const Icon(Icons.star, color: Colors.greenAccent, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      '${conquistas.where((c) => c['desbloqueada'] == true).length}/${conquistas.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Desbloqueadas',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Suas Insígnias',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...conquistas.map((c) {
            final desbloqueada = c['desbloqueada'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: desbloqueada
                    ? Colors.grey.shade900
                    : Colors.grey.shade900.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: desbloqueada
                      ? Colors.amber.withOpacity(0.5)
                      : Colors.grey.shade800,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: desbloqueada
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      c['icone'] as IconData,
                      color: desbloqueada ? Colors.amber : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['titulo'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: desbloqueada ? Colors.white : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['descricao'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: desbloqueada
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    desbloqueada ? Icons.check_circle : Icons.lock,
                    color: desbloqueada
                        ? Colors.greenAccent
                        : Colors.grey.shade700,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
