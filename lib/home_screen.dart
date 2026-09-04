import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'app_cache.dart';
import 'dieta_screen.dart';
import 'usuario_repository.dart';
import 'historico_screen.dart';
import 'dieta_repository.dart';
import 'detalhes_treino_screen.dart';
import 'conquistas_screen.dart';
import 'nutricao_ia_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final int usuarioId;
  const HomeScreen({super.key, required this.usuarioId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;
  bool _isGeneratingDaily = false;
  bool _planoExpirado = false;

  final _repository = UsuarioRepository();
  Map<String, dynamic>? _usuarioData;
  Map<String, dynamic>? _planoData;
  bool _isLoading = true;
  bool _treinoConcluidoHoje = false;

  int _totalTreinosConcluidos = 0;
  int _sequenciaAtual = 0; // <-- Nova variável para guardar os dias seguidos

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

  // --- NOVA LÓGICA: CALCULA DIAS SEGUIDOS ---
  int _calcularSequencia(List<dynamic> treinos) {
    if (treinos.isEmpty) return 0;

    // Extrai apenas as datas únicas no formato YYYY-MM-DD
    Set<String> datasUnicas = {};
    for (var t in treinos) {
      final data = t['data_realizacao']?.toString().split('T')[0];
      if (data != null) datasUnicas.add(data);
    }
    List<String> datasOrdenadas = datasUnicas.toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime dataVerificacao = DateTime.now();
    String hojeStr = dataVerificacao.toIso8601String().split('T')[0];
    String ontemStr = dataVerificacao
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];

    // Se não treinou hoje e nem ontem, perdeu a sequência (zera a barra)
    if (!datasOrdenadas.contains(hojeStr) &&
        !datasOrdenadas.contains(ontemStr)) {
      return 0;
    }

    // Conta quantos dias para trás existem na lista
    DateTime currentDate = datasOrdenadas.contains(hojeStr)
        ? dataVerificacao
        : dataVerificacao.subtract(const Duration(days: 1));
    for (int i = 0; i < datasOrdenadas.length; i++) {
      String expectedDateStr = currentDate
          .subtract(Duration(days: i))
          .toIso8601String()
          .split('T')[0];
      if (datasOrdenadas.contains(expectedDateStr)) {
        streak++;
      } else {
        break; // Buraco na sequência encontrado
      }
    }
    return streak;
  }

  Future<void> _carregarDashboard() async {
    try {
      final user = await _repository.buscarUsuario(widget.usuarioId);
      final totaisDieta = await _dietaRepository.buscarTotaisDiarios(
        widget.usuarioId,
      );
      final treinoHoje = await _repository.verificarTreinoConcluidoHoje(
        widget.usuarioId,
      );

      final treinosRealizados = await Supabase.instance.client
          .from('treinos_realizados')
          .select()
          .eq('usuario_id', widget.usuarioId);

      // BUSCA O PLANO SALVO NO BANCO E VERIFICA A VALIDADE (MEIA NOITE)
      final plano = await _repository.buscarPlanoAtivo(widget.usuarioId);
      final hoje = DateTime.now().toIso8601String().split('T')[0];

      bool expirado = true;
      if (plano != null) {
        final dataPlano = plano['data_registro']?.toString() ?? '';
        if (dataPlano == hoje) {
          expirado = false;
          if (plano['dados_ia'] != null) {
            AppCache.planoAtual = plano['dados_ia'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
          _treinoConcluidoHoje = treinoHoje;
          _totaisConsumidos = totaisDieta;
          _totalTreinosConcluidos = treinosRealizados.length;
          _sequenciaAtual = _calcularSequencia(
            treinosRealizados,
          ); // Atualiza o Streak
          _planoExpirado = expirado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NOVO POP-UP DE SUBIR DE NÍVEL ---
  void _mostrarDialogEvolucao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Nível Concluído! 🚀',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Incrível! Você alcançou uma sequência impecável de $_sequenciaAtual dias ininterruptos.\n\nSua disciplina está moldando um novo corpo. A IA vai elevar o nível do seu próximo desafio!',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BORA PRO PRÓXIMO!',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarNovoTreinoDiario() async {
    setState(() => _isGeneratingDaily = true);

    try {
      final historico = await _repository.buscarHistoricoRecente(
        widget.usuarioId,
      );
      final pesoAtual = historico.isNotEmpty
          ? (historico.first['peso_kg'] ?? 75.0)
          : 75.0;
      final objetivoAtual = historico.isNotEmpty
          ? (historico.first['objetivo'] ?? 'Hipertrofia')
          : 'Hipertrofia';

      String nivelDinamico = 'Iniciante';
      if (_totalTreinosConcluidos >= 15) {
        nivelDinamico = 'Avançado';
      } else if (_totalTreinosConcluidos >= 10) {
        nivelDinamico = 'Intermediário';
      }

      final novoPlanoIA = await NutricaoIAService.gerarPlanoCompleto(
        peso: (pesoAtual as num).toDouble(),
        consomeCarne: true,
        objetivo: objetivoAtual.toString(),
        nivel: nivelDinamico,
        lesaoLombar: false,
        lesaoOmbro: false,
        historicoRecente: historico,
      );

      if (novoPlanoIA != null) {
        await _repository.gravarPlanoDiario(
          usuarioId: widget.usuarioId,
          dadosIA: novoPlanoIA,
        );
        AppCache.planoAtual = novoPlanoIA;
      }

      _carregarDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao gerar plano: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDaily = false);
    }
  }

  Future<void> _deslogar() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
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
    final planoCache = AppCache.planoAtual;
    final bool temPlano = planoCache != null && planoCache.isNotEmpty;

    final caloriasAlvo = planoCache?['calorias_alvo'] ?? 2000;
    final protAlvo = planoCache?['proteinas_g_alvo'] ?? 150;
    final carbAlvo = planoCache?['carboidratos_g_alvo'] ?? 200;
    final gordAlvo = planoCache?['gorduras_g_alvo'] ?? 60;

    final kcalAtual = _totaisConsumidos['calorias'] ?? 0;
    final protAtual = _totaisConsumidos['proteinas'] ?? 0;
    final carbAtual = _totaisConsumidos['carboidratos'] ?? 0;
    final gordAtual = _totaisConsumidos['gorduras'] ?? 0;

    final resumoAnalise = temPlano
        ? planoCache['resumo_analise']
        : 'Plano pendente. Vá em "Seu Histórico" para configurar o perfil ou refaça o Anamnese.';

    final nomeTreinoIA = temPlano
        ? planoCache['treino_sugerido_nome']
        : 'Treino de Calistenia (Padrão)';

    // A barra agora mede a STREAK a cada 10 dias (10 dias = 100%)
    double progressoNivel = _sequenciaAtual == 0
        ? 0.0
        : (_sequenciaAtual % 10 == 0 ? 1.0 : (_sequenciaAtual % 10) / 10.0);

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

        // --- BARRA DE PROGRESSÃO DA CONSTÂNCIA (STREAK) ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
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
                        Icons.local_fire_department,
                        color: Colors.orangeAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sequência: $_sequenciaAtual dias',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(progressoNivel * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressoNivel,
                  minHeight: 12,
                  backgroundColor: Colors.black45,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Treine todos os dias para fechar a barra e evoluir. Se você pular um dia, a sequência zera!',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- CARD DE TREINO DO DIA ---
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
              onTap: _planoExpirado
                  ? _gerarNovoTreinoDiario
                  : (_treinoConcluidoHoje
                        ? null
                        : () async {
                            final finalizou = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalhesTreinoScreen(
                                  dadosPlano: AppCache.planoAtual ?? {},
                                  usuarioId: widget.usuarioId,
                                ),
                              ),
                            );

                            // Ao voltar do treino com sucesso, recarrega e verifica se bateu os 10 dias!
                            if (finalizou == true) {
                              await _carregarDashboard();
                              // Mostra a celebração se for múltiplo de 10 dias seguidos!
                              if (_sequenciaAtual > 0 &&
                                  _sequenciaAtual % 10 == 0) {
                                _mostrarDialogEvolucao();
                              }
                            }
                          }),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _planoExpirado
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : (_treinoConcluidoHoje
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.greenAccent.withOpacity(0.1)),
                        shape: BoxShape.circle,
                      ),
                      child: _isGeneratingDaily
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.orangeAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _planoExpirado
                                  ? Icons.auto_awesome
                                  : (_treinoConcluidoHoje
                                        ? Icons.check_circle
                                        : Icons.fitness_center),
                              color: _planoExpirado
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _planoExpirado
                                ? 'Gerar Treino de Hoje 🤖'
                                : (_treinoConcluidoHoje
                                      ? 'Treino Concluído Hoje! 🏆'
                                      : nomeTreinoIA),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _planoExpirado
                                  ? Colors.orangeAccent
                                  : (_treinoConcluidoHoje
                                        ? Colors.greenAccent
                                        : Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _planoExpirado
                                ? 'Um novo dia! Toque para a IA avaliar seu progresso e montar o treino.'
                                : (_treinoConcluidoHoje
                                      ? 'Meta diária batida. Bom descanso!'
                                      : 'Toque para ver o guia de exercícios'),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_treinoConcluidoHoje && !_isGeneratingDaily)
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- CARD DE GALERIA DE CONQUISTAS ---
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
            setState(() => _abaAtual = index);
            if (index == 0 || index == 1) {
              _carregarDashboard();
            }
          },
        ),
      ),
    );
  }
}
