import 'package:flutter/material.dart';

import 'treino_screen.dart';
import 'usuario_repository.dart';

class HomeScreen extends StatefulWidget {
  final int usuarioId;
  const HomeScreen({super.key, required this.usuarioId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = UsuarioRepository();
  Map<String, dynamic>? _usuarioData;
  Map<String, dynamic>? _planoData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  bool _treinoConcluidoHoje = false;

  Future<void> _carregarDashboard() async {
    try {
      final user = await _repository.buscarUsuario(widget.usuarioId);
      final plano = await _repository.buscarPlanoAtivo(widget.usuarioId);
      final treinoHoje = await _repository.verificarTreinoConcluidoHoje(
        widget.usuarioId,
      ); // Busca o status

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
          _treinoConcluidoHoje = treinoHoje; // Atualiza o estado
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nome = _usuarioData?['nome'] ?? 'Atleta';
    final caloriasAlvo = _planoData?['calorias_alvo'] ?? 0;
    final protAlvo = _planoData?['proteinas_g_alvo'] ?? 0;
    final carbAlvo = _planoData?['carboidratos_g_alvo'] ?? 0;
    final gordAlvo = _planoData?['gorduras_g_alvo'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bora treinar, $nome!'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
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
                    // O 0 é fixo por enquanto, pois o consumo virá do registro de refeições futuramente
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
              // Navega para a tela de treino e aguarda o retorno
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TreinoScreen(usuarioId: widget.usuarioId),
                ),
              );
              // Quando o usuário voltar (após finalizar o treino), recarrega a Home
              _carregarDashboard();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                // Adiciona uma borda sutil verde se concluído
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
                        // Círculo de progresso por fora
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: _treinoConcluidoHoje
                                ? 1.0
                                : 0.0, // 100% se concluído, 0% se pendente
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade800,
                            color: Colors.greenAccent,
                          ),
                        ),
                        // Ícone por dentro
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
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
          // TODO: Adicionar lógica para trocar de aba
        },
      ),
    );
  }
}
