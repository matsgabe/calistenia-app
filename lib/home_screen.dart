import 'package:flutter/material.dart';

import 'app_cache.dart';
import 'dieta_screen.dart';
import 'treino_screen.dart';
import 'usuario_repository.dart';
import 'historico_screen.dart';
import 'dieta_repository.dart';
import 'detalhes_treino_screen.dart'; // Import da tela de detalhes do treino

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
  final _dietaRepository = DietaRepository();
  Map<String, int> _totaisConsumidos = {
    'calorias': 0,
    'proteinas': 0,
    'carboidratos': 0,
    'gorduras': 0,
  };

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
      // Busca os totais da dieta do dia
      final totaisDieta = await _dietaRepository.buscarTotaisDiarios(
        widget.usuarioId,
      );

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
          _treinoConcluidoHoje = treinoHoje;
          _totaisConsumidos = totaisDieta;
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

    final kcalAtual = _totaisConsumidos['calorias'] ?? 0;
    final protAtual = _totaisConsumidos['proteinas'] ?? 0;
    final carbAtual = _totaisConsumidos['carboidratos'] ?? 0;
    final gordAtual = _totaisConsumidos['gorduras'] ?? 0;

    // Recupera dados adicionais gerados pela IA (se salvos no plano ou em cache)
    final planoCache = AppCache.planoAtual;
    final resumoAnalise =
        planoCache?['resumo_analise'] ??
        _planoData?['resumo_analise'] ??
        'Seu plano inteligente está ativo e estruturado sob medida.';
    final nomeTreinoIA =
        planoCache?['treino_sugerido_nome'] ??
        _planoData?['treino_sugerido_nome'] ??
        'Treino do Dia: Calistenia';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- CARD DE PARECER DA NUTRI & PERSONAL IA ---
        Container(
          padding: const EdgeInsets.all(16.0),
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
                  Icon(Icons.psychology, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Análise Nutri & Personal IA',
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
                resumoAnalise,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- RESUMO DIÁRIO (METAS E MACROS) ---
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
                'Consumido: $kcalAtual / Meta: $caloriasAlvo kcal',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroCircle('Prot', '$protAtual\n/ $protAlvo'),
                  _buildMacroCircle('Carb', '$carbAtual\n/ $carbAlvo'),
                  _buildMacroCircle('Gord', '$gordAtual\n/ $gordAlvo'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- CARD DE TREINO DO DIA (COM GUIA INTERATIVO) ---
        InkWell(
          onTap: () async {
            // Se o usuário quiser ver os detalhes da IA ou executar o treino
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalhesTreinoScreen(
                  dadosPlano: AppCache.planoAtual ?? _planoData ?? {},
                  usuarioId: widget.usuarioId, // Adicionado aqui
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _treinoConcluidoHoje
                            ? 'Treino Concluído! 🏆'
                            : nomeTreinoIA,
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
                        _treinoConcluidoHoje ? 'Bom descanso. Até amanhã!' : 'Toque para ver o guia de exercícios e instruções',
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
                : DietaScreen(usuarioId: widget.usuarioId)),

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
