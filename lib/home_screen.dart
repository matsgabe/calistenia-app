import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'app_cache.dart';
import 'dieta_screen.dart';
import 'treino_screen.dart';
import 'usuario_repository.dart';
import 'historico_screen.dart';
import 'dieta_repository.dart';
import 'detalhes_treino_screen.dart';
import 'conquistas_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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
  int _totalTreinosConcluidos = 0; // Adicionado para calcular o progresso real

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
      final totaisDieta = await _dietaRepository.buscarTotaisDiarios(
        widget.usuarioId,
      );

      // 1. Total de treinos já realizados na vida (para a barra de progresso)
      final treinosRealizados = await Supabase.instance.client
          .from('treinos_realizados')
          .select('id')
          .eq('usuario_id', widget.usuarioId);

      // 2. Verifica se algum treino foi realizado especificamente HOJE
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final treinosHoje = await Supabase.instance.client
          .from('treinos_realizados')
          .select('id')
          .eq('usuario_id', widget.usuarioId)
          .gte(
            'data_realizacao',
            '$hoje 00:00:00',
          ); // Pega treinos de hoje em diante

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
          _treinoConcluidoHoje = treinosHoje.isNotEmpty;
          _totaisConsumidos = totaisDieta;
          _totalTreinosConcluidos = treinosRealizados.length;
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

  Future<void> _deslogar() async {
    // Desloga do Supabase
    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      // Navega de volta para a tela de Login e limpa o histórico de navegação
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
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
            color: Colors.black26,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade800, width: 3),
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
    final bool temPlano = _planoData != null && _planoData!.isNotEmpty;

    final caloriasAlvo = _planoData?['calorias_alvo'] ?? 0;
    final protAlvo = _planoData?['proteinas_g_alvo'] ?? 0;
    final carbAlvo = _planoData?['carboidratos_g_alvo'] ?? 0;
    final gordAlvo = _planoData?['gorduras_g_alvo'] ?? 0;

    final kcalAtual = _totaisConsumidos['calorias'] ?? 0;
    final protAtual = _totaisConsumidos['proteinas'] ?? 0;
    final carbAtual = _totaisConsumidos['carboidratos'] ?? 0;
    final gordAtual = _totaisConsumidos['gorduras'] ?? 0;

    final planoCache = AppCache.planoAtual;

    // Tratamento para usuários novos não puxarem o cache indevidamente
    final resumoAnalise = temPlano
        ? (_planoData?['resumo_analise'] ??
              planoCache?['resumo_analise'] ??
              'Seu plano inteligente está ativo e estruturado sob medida.')
        : 'Plano pendente. A IA gerará seu plano no seu primeiro treino/refeição.';

    final nomeTreinoIA = temPlano
        ? (_planoData?['treino_sugerido_nome'] ??
              planoCache?['treino_sugerido_nome'] ??
              'Treino do Dia: Calistenia')
        : 'Pronto para começar?';

    // Progresso 100% Real baseado no Banco de Dados
    final double progressoNivel = _totalTreinosConcluidos == 0
        ? 0.0
        : (_totalTreinosConcluidos % 5) / 5.0;
    final String patamarAtual = _totalTreinosConcluidos >= 15
        ? 'Patamar: Elite (Avançado)'
        : _totalTreinosConcluidos >= 10
        ? 'Patamar: Intermediário'
        : 'Patamar: Fundacional (Iniciante)';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- CARD DE ANÁLISE NUTRI & PERSONAL IA ---
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: temPlano ? Colors.greenAccent : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Análise Nutri & Personal IA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: temPlano ? Colors.greenAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                resumoAnalise,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- RESUMO DIÁRIO ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo Diário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Consumido: $kcalAtual / Meta: $caloriasAlvo kcal',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
        const SizedBox(height: 20),

        // --- DICA DO DIA ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blueAccent, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dica do Dia: Mantenha-se hidratado! Beba cerca de 500ml de água a cada 2 horas de treino calistênico.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- BARRA DE PROGRESSÃO ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        patamarAtual,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(progressoNivel * 100).toInt()}%',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressoNivel,
                  minHeight: 10,
                  backgroundColor: Colors.black26,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete mais treinos para desbloquear variações avançadas e progressões de força.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- CARD DE TREINO DO DIA (MODERNIZADO) ---
        Container(
          decoration: BoxDecoration(
            color: _treinoConcluidoHoje
                ? Colors.green.withOpacity(0.05)
                : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _treinoConcluidoHoje
                  ? Colors.greenAccent.withOpacity(0.5)
                  : Colors.greenAccent.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _treinoConcluidoHoje
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesTreinoScreen(
                            dadosPlano: AppCache.planoAtual ?? _planoData ?? {},
                            usuarioId: widget.usuarioId,
                          ),
                        ),
                      );
                      _carregarDashboard();
                    },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _treinoConcluidoHoje
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.greenAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _treinoConcluidoHoje
                            ? Icons.check_circle
                            : Icons.fitness_center,
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
                                ? 'Treino Concluído Hoje! 🏆'
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
                            _treinoConcluidoHoje
                                ? 'Meta diária batida. Bom descanso!'
                                : 'Toque para ver o guia de exercícios e instruções',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_treinoConcluidoHoje)
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- CARD DE GALERIA DE CONQUISTAS (MODERNIZADO) ---
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ConquistasScreen(usuarioId: widget.usuarioId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Galeria de Conquistas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toque para ver suas insígnias e marcos',
                            style: TextStyle(
                              color: Colors.grey.shade400,
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
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
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

    final nomeCompleto = _usuarioData?['nome']?.toString().trim() ?? '';
    final primeiroNome = nomeCompleto.isNotEmpty
        ? nomeCompleto.split(' ').first
        : 'Atleta';

    String tituloAppBar = 'Bora treinar, $primeiroNome!';
    if (_abaAtual == 1) tituloAppBar = 'Sua Dieta';
    if (_abaAtual == 2) tituloAppBar = 'Seu Histórico';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          tituloAppBar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => _deslogar(),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: _abaAtual == 0
          ? _buildAbaHome()
          : (_abaAtual == 2
                ? HistoricoScreen(usuarioId: widget.usuarioId)
                : DietaScreen(usuarioId: widget.usuarioId)),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _abaAtual,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.grey.shade600,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Dieta',
            ),
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
      ),
    );
  }
}
