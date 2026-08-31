import 'package:flutter/material.dart';
import 'usuario_repository.dart';
import 'treino_screen.dart';

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

  Future<void> _carregarDashboard() async {
    try {
      final user = await _repository.buscarUsuario(widget.usuarioId);
      final plano = await _repository.buscarPlanoAtivo(widget.usuarioId);

      if (mounted) {
        setState(() {
          _usuarioData = user;
          _planoData = plano;
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

  Widget _buildMacroIndicator(
    String titulo,
    int valorAlvo,
    Color cor,
    Key key,
  ) {
    // Como ainda não temos o consumo do dia, assumimos 0 para o MVP visual
    double progresso = 0.0;

    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                key: key,
                value: progresso,
                backgroundColor: Colors.grey.shade800,
                color: cor,
                strokeWidth: 6,
              ),
              Center(
                child: Text(
                  '0\n/$valorAlvo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
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

    final nomeUsuario = _usuarioData?['nome'] ?? 'Atleta';
    final caloriasAlvo = _planoData?['calorias_alvo'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bora treinar, $nomeUsuario!'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {}, // Futuro acesso ao perfil
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Card de Macros Metabólicos
            Card(
              key: const Key('card_macros'),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo Diário',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meta: $caloriasAlvo kcal',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroIndicator(
                          'Prot',
                          _planoData?['proteinas_g_alvo'] ?? 0,
                          Colors.blue,
                          const Key('ring_prot'),
                        ),
                        _buildMacroIndicator(
                          'Carb',
                          _planoData?['carboidratos_g_alvo'] ?? 0,
                          Colors.green,
                          const Key('ring_carb'),
                        ),
                        _buildMacroIndicator(
                          'Gord',
                          _planoData?['gorduras_g_alvo'] ?? 0,
                          Colors.orange,
                          const Key('ring_gord'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card do Treino de Calistenia do Dia
            Card(
              key: const Key('card_treino_dia'),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                title: const Text(
                  'Treino do Dia: Push',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Peito, Ombro e Tríceps\nNível: Iniciante',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TreinoScreen(usuarioId: widget.usuarioId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Dieta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
