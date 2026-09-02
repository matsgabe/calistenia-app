import 'package:flutter/material.dart';

import 'treino_screen.dart';
import 'usuario_repository.dart';
import 'historico_screen.dart';

class HomeScreen extends StatefulWidget {
  final int usuarioId;
  const HomeScreen({super.key, required this.usuarioId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;

  final _repository = UsuarioRepository();
  Map<String, dynamic>? _usuarioData;
  Map<String, dynamic>? _planoData;
  bool _isLoading = true;
  bool _treinoConcluidoHoje = false;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    try {
      final user = await _repository.buscarUsuario(widget.usuarioId);
      final plano = await _repository.buscarPlanoAtivo(widget.usuarioId);
      final treinoHoje = await _repository.verificarTreinoConcluidoHoje(
        widget.usuarioId,
      );

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
          _treinoConcluidoHoje = treinoHoje;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMacroCircle(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade800, width: 4),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAbaHome() {
    final caloriasAlvo = _planoData?['calorias_alvo'] ?? 0;
    final protAlvo = _planoData?['proteinas_g_alvo'] ?? 0;
    final carbAlvo = _planoData?['carboidratos_g_alvo'] ?? 0;
    final gordAlvo = _planoData?['gorduras_g_alvo'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo Diário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Meta: $caloriasAlvo kcal',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroCircle('Prot', '0\n/ $protAlvo'),
                  _buildMacroCircle('Carb', '0\n/ $carbAlvo'),
                  _buildMacroCircle('Gord', '0\n/ $gordAlvo'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- CARD DE TREINO DO DIA ---
        InkWell(
          onTap: () async {
            if (_treinoConcluidoHoje) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Você já concluiu o treino de hoje! Bom descanso. 🏆',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              return;
            }

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TreinoScreen(usuarioId: widget.usuarioId),
              ),
            );
            _carregarDashboard();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: _treinoConcluidoHoje
                  ? Border.all(color: Colors.green.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                // ÍCONE COM PROGRESSO CIRCULAR
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: _treinoConcluidoHoje ? 1.0 : 0.0,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey.shade800,
                          color: Colors.greenAccent,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _treinoConcluidoHoje
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.deepPurple.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _treinoConcluidoHoje
                              ? Icons.check
                              : Icons.fitness_center,
                          color: _treinoConcluidoHoje
                              ? Colors.greenAccent
                              : Colors.deepPurpleAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // TEXTOS DO TREINO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _treinoConcluidoHoje
                            ? 'Treino Concluído! 🏆'
                            : 'Treino do Dia: Push',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _treinoConcluidoHoje
                              ? Colors.greenAccent
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _treinoConcluidoHoje
                            ? 'Bom descanso. Até amanhã!'
                            : 'Peito, Ombro e Tríceps\nNível: Iniciante',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nome = _usuarioData?['nome'] ?? 'Atleta';

    // Título dinâmico da AppBar
    String tituloAppBar = 'Bora treinar, $nome!';
    if (_abaAtual == 1) tituloAppBar = 'Dieta';
    if (_abaAtual == 2) tituloAppBar = 'Histórico';

    return Scaffold(
      appBar: AppBar(
        title: Text(tituloAppBar),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _abaAtual == 0
          ? _buildAbaHome()
          : (_abaAtual == 2
                ? HistoricoScreen(usuarioId: widget.usuarioId)
                : const Center(child: Text('Aba Dieta em construção...'))),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaAtual,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Dieta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
        onTap: (index) {
          setState(() {
            _abaAtual = index;
          });
        },
      ),
    );
  }
}
