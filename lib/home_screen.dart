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
import 'calendario_screen.dart';
import 'editar_perfil_screen.dart';
import 'agua_repository.dart';

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
  bool _expandirAnaliseIA = false;

  final _repository = UsuarioRepository();
  final _aguaRepository = AguaRepository();

  Map<String, dynamic>? _usuarioData;
  Map<String, dynamic>? _planoData;
  bool _isLoading = true;
  bool _treinoConcluidoHoje = false;

  int _totalTreinosConcluidos = 0;
  int _sequenciaAtual = 0;

  int _consumoAguaAtual = 0;
  int _metaAguaMl = 2500;

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
    _carregarDadosAgua();
  }

  Future<void> _carregarDadosAgua() async {
    try {
      final historico = await _repository.buscarHistoricoRecente(
        widget.usuarioId,
      );
      double peso = 75.0;
      if (historico.isNotEmpty && historico.first['peso_kg'] != null) {
        peso = (historico.first['peso_kg'] as num).toDouble();
      }

      final meta = _aguaRepository.calcularMetaAguaMl(peso);
      final consumido = await _aguaRepository.buscarConsumoHoje(
        widget.usuarioId,
      );

      if (mounted) {
        setState(() {
          _metaAguaMl = meta;
          _consumoAguaAtual = consumido;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados de água: $e');
    }
  }

  int _calcularSequencia(List<dynamic> treinos) {
    if (treinos.isEmpty) return 0;

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

    if (!datasOrdenadas.contains(hojeStr) &&
        !datasOrdenadas.contains(ontemStr)) {
      return 0;
    }

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
        break;
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
          _sequenciaAtual = _calcularSequencia(treinosRealizados);
          _planoExpirado = expirado;
          _isLoading = false;
        });
      }

      _carregarDadosAgua();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogEvolucao() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              'Nível Concluído! 🚀',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Incrível! Você alcançou uma sequência impecável de $_sequenciaAtual dias ininterruptos.\n\nSua disciplina está moldando um novo corpo. A IA vai elevar o nível do seu próximo desafio!',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BORA PRO PRÓXIMO!',
              style: TextStyle(
                color: Colors.green,
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

  Widget _buildMacroCircle(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.black12,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAbaHome(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    final planoCache = AppCache.planoAtual;
    final bool temPlano =
        (_planoData != null && _planoData!.isNotEmpty) ||
        (planoCache != null && planoCache.isNotEmpty);

    final caloriasAlvo =
        _planoData?['calorias_alvo'] ?? planoCache?['calorias_alvo'] ?? 2000;
    final protAlvo =
        _planoData?['proteinas_g_alvo'] ??
        planoCache?['proteinas_g_alvo'] ??
        150;
    final carbAlvo =
        _planoData?['carboidratos_g_alvo'] ??
        planoCache?['carboidratos_g_alvo'] ??
        200;
    final gordAlvo =
        _planoData?['gorduras_g_alvo'] ?? planoCache?['gorduras_g_alvo'] ?? 60;

    final kcalAtual = _totaisConsumidos['calorias'] ?? 0;
    final protAtual = _totaisConsumidos['proteinas'] ?? 0;
    final carbAtual = _totaisConsumidos['carboidratos'] ?? 0;
    final gordAtual = _totaisConsumidos['gorduras'] ?? 0;

    final resumoAnalise = temPlano
        ? (_planoData?['dados_ia']?['resumo_analise'] ??
              planoCache?['resumo_analise'] ??
              'Plano inteligente ativo.')
        : 'Plano pendente. Vá em "Seu Histórico" para configurar o perfil ou refaça o Anamnese.';

    final nomeTreinoIA = temPlano
        ? (_planoData?['dados_ia']?['treino_sugerido_nome'] ??
              planoCache?['treino_sugerido_nome'] ??
              'Treino de Calistenia')
        : 'Treino Padrão';

    double progressoNivel = _sequenciaAtual == 0
        ? 0.0
        : (_sequenciaAtual % 10 == 0 ? 1.0 : (_sequenciaAtual % 10) / 10.0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- CARD DE ANÁLISE NUTRI & PERSONAL IA ---
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.greenAccent.withOpacity(0.05)
                : Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandirAnaliseIA,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandirAnaliseIA = expanded;
                });
              },
              leading: Icon(
                Icons.psychology,
                color: temPlano ? Colors.green : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Análise Nutri & Personal IA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: temPlano ? Colors.green : Colors.grey,
                ),
              ),
              subtitle: Text(
                _expandirAnaliseIA
                    ? 'Toque para recolher'
                    : 'Toque aqui para ver explicação',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    resumoAnalise,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- RESUMO DIÁRIO ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo Diário',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consumido: $kcalAtual / Meta: $caloriasAlvo kcal',
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroCircle(
                    'Prot',
                    '$protAtual\n/ $protAlvo',
                    textColor,
                  ),
                  _buildMacroCircle(
                    'Carb',
                    '$carbAtual\n/ $carbAlvo',
                    textColor,
                  ),
                  _buildMacroCircle(
                    'Gord',
                    '$gordAtual\n/ $gordAlvo',
                    textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- CARD DE HIDRATAÇÃO (ÁGUA) ---
        buildCardAgua(
          _consumoAguaAtual,
          _metaAguaMl,
          cardColor,
          textColor,
          subtitleColor,
          (quantidadeAdicionar) async {
            final novoTotal = await _aguaRepository.adicionarAgua(
              usuarioId: widget.usuarioId,
              quantidadeAdicionarMl: quantidadeAdicionar,
            );
            setState(() {
              _consumoAguaAtual = novoTotal;
            });
          },
        ),
        const SizedBox(height: 20),

        // --- BARRA DE PROGRESSÃO DA CONSTÂNCIA (STREAK) ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orangeAccent,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sequência: 0 dias', // ou $_sequenciaAtual
                        style: TextStyle(
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
                      color: subtitleColor,
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
                  backgroundColor: Colors.black12,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Treine todos os dias para fechar a barra e evoluir. Se você pular um dia, a sequência zera!',
                style: TextStyle(
                  color: subtitleColor,
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
                : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _treinoConcluidoHoje
                  ? Colors.green.withOpacity(0.5)
                  : Colors.green.withOpacity(0.2),
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
                                  dadosPlano:
                                      _planoData?['dados_ia'] ??
                                      AppCache.planoAtual ??
                                      {},
                                  usuarioId: widget.usuarioId,
                                ),
                              ),
                            );

                            if (finalizou == true) {
                              await _carregarDashboard();
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
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.1)),
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
                                  : Colors.green,
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
                                        ? Colors.green
                                        : textColor),
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
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_treinoConcluidoHoje && !_isGeneratingDaily)
                      Icon(Icons.chevron_right, color: subtitleColor),
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
            color: cardColor,
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
                          Text(
                            'Galeria de Conquistas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toque para ver suas insígnias e marcos',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: subtitleColor),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : Colors.grey.shade100;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          tituloAppBar,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        elevation: 0,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.green),
            tooltip: 'Ver Calendário e Histórico',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CalendarioScreen(usuarioId: widget.usuarioId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.green),
            tooltip: 'Configurações e Perfil',
            onPressed: () async {
              final atualizou = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditarPerfilScreen(usuarioId: widget.usuarioId),
                ),
              );
              if (atualizou == true) {
                _carregarDashboard();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => _deslogar(),
          ),
        ],
      ),
      body: _abaAtual == 0
          ? _buildAbaHome(cardColor, textColor, subtitleColor, isDarkMode)
          : (_abaAtual == 2
                ? HistoricoScreen(usuarioId: widget.usuarioId)
                : DietaScreen(usuarioId: widget.usuarioId)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _abaAtual,
          backgroundColor: backgroundColor,
          selectedItemColor: Colors.green,
          unselectedItemColor: subtitleColor,
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

  Widget buildCardAgua(
    int consumidoMl,
    int metaMl,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Function(int) onAdicionar,
  ) {
    double progresso = (consumidoMl / metaMl).clamp(0.0, 1.0);
    String consumidoLitros = (consumidoMl / 1000).toStringAsFixed(2);
    String metaLitros = (metaMl / 1000).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Hidratação Diária',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Text(
                '0.00 L / 2.69 L', // ou dados dinâmicos
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => onAdicionar(250),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  foregroundColor: Colors.blueAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '250 ml',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => onAdicionar(500),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  foregroundColor: Colors.blueAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '500 ml',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
