import 'package:flutter/material.dart';

import 'app_cache.dart';
import 'dieta_repository.dart';
import 'nutricao_ia_service.dart'; // Ajuste caso seu serviço de IA de refeições esteja em outro arquivo

class DietaScreen extends StatefulWidget {
  final int usuarioId;
  const DietaScreen({super.key, required this.usuarioId});

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> {
  final _dietaRepository = DietaRepository();
  final _descricaoController = TextEditingController();

  List<Map<String, dynamic>> _refeicoes = [];
  bool _isLoading = true;
  bool _analisandoIA = false;

  @override
  void initState() {
    super.initState();
    _carregarRefeicoes();
  }

  Future<void> _carregarRefeicoes() async {
    try {
      final refeicoes = await _dietaRepository.buscarRefeicoesDoDia(
        widget.usuarioId,
      );
      if (mounted) {
        setState(() {
          _refeicoes = refeicoes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar refeições: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adicionarRefeicaoComIA() async {
    final texto = _descricaoController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _analisandoIA = true);

    try {
      // Chama a IA para analisar os macros do que foi digitado (ex: "2 ovos e 1 banana")
      final resultadoIA = await NutricaoIAService.analisarRefeicao(
        descricao: texto,
      );

      if (resultadoIA != null) {
        await _dietaRepository.salvarRefeicao(
          usuarioId: widget.usuarioId,
          nome: texto,
          calorias: resultadoIA['calorias'] ?? 0,
          proteinas: resultadoIA['proteinas_g'] ?? 0,
          carboidratos: resultadoIA['carboidratos_g'] ?? 0,
          gorduras: resultadoIA['gorduras_g'] ?? 0,
        );

        _descricaoController.clear();
        await _carregarRefeicoes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refeição registrada com sucesso! 🥗'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar refeição com IA: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _analisandoIA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recupera a análise nutricional gerada pela IA no onboarding
    final planoCache = AppCache.planoAtual;
    final analiseNutricional =
        planoCache?['analise_nutricional'] ??
        planoCache?['resumo_analise'] ??
        'Diretrizes nutricionais estruturadas para o seu objetivo.';

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- CARD DE PARECER DA NUTRICIONISTA IA ---
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
                    Icon(
                      Icons.restaurant_menu,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Diretrizes da Nutricionista IA',
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
                  analiseNutricional,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- CAMPO PARA REGISTRAR REFEIÇÃO COM IA ---
          const Text(
            'Registrar Refeição',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 200g de frango e 1 batata doce',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _analisandoIA ? null : _adicionarRefeicaoComIA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                child: _analisandoIA
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- LISTA DE REFEIÇÕES DO DIA ---
          const Text(
            'Refeições de Hoje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _refeicoes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'Nenhuma refeição registrada hoje.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _refeicoes.length,
                  itemBuilder: (context, index) {
                    final ref = _refeicoes[index];
                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          ref['nome'] ?? 'Refeição',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'P: ${ref['proteinas_g']}g | C: ${ref['carboidratos_g']}g | G: ${ref['gorduras_g']}g',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          '${ref['calorias']} kcal',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
