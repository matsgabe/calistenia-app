import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_cache.dart';
import 'dieta_repository.dart';
import 'nutricao_ia_service.dart';

class DietaScreen extends StatefulWidget {
  final int usuarioId;
  const DietaScreen({super.key, required this.usuarioId});

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> {
  final _dietaRepository = DietaRepository();
  final _descricaoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _refeicoes = [];
  List<dynamic> _sugestoesCardapio = [];
  bool _isLoading = true;
  bool _processandoIA = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final refeicoes = await _dietaRepository.buscarRefeicoesDoDia(
        widget.usuarioId,
      );

      // Gera sugestões baseadas no cache do onboarding se disponíveis
      final planoCache = AppCache.planoAtual;
      final cardapioIA = await NutricaoIAService.gerarCardapioDiario(
        peso: planoCache?['peso'] ?? 78.0,
        consomeCarne: planoCache?['consome_carne'] ?? true,
        objetivo: planoCache?['objetivo'] ?? 'Hipertrofia',
      );

      if (mounted) {
        setState(() {
          _refeicoes = refeicoes;
          _sugestoesCardapio = cardapioIA?['sugestoes'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarPorTexto() async {
    final texto = _descricaoController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _processandoIA = true);
    try {
      final res = await NutricaoIAService.analisarRefeicao(descricao: texto);
      if (res != null) {
        await _dietaRepository.salvarRefeicao(
          usuarioId: widget.usuarioId,
          nome: texto,
          calorias: res['calorias'] ?? 0,
          proteinas: res['proteinas_g'] ?? 0,
          carboidratos: res['carboidratos_g'] ?? 0,
          gorduras: res['gorduras_g'] ?? 0,
        );
        _descricaoController.clear();
        await _carregarDados();
      }
    } finally {
      if (mounted) setState(() => _processandoIA = false);
    }
  }

  // **REGISTRO INTELIGENTE VIA FOTO DO PRATO**
  Future<void> _adicionarPorFoto() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (imagem == null) return;

    setState(() => _processandoIA = true);
    try {
      Uint8List bytes = await imagem.readAsBytes();
      final res = await NutricaoIAService.analisarRefeicaoPorFoto(bytes);

      if (res != null) {
        final nomePrato = res['nome_detectado'] ?? 'Refeição via Foto';
        await _dietaRepository.salvarRefeicao(
          usuarioId: widget.usuarioId,
          nome: '📸 $nomePrato',
          calorias: res['calorias'] ?? 0,
          proteinas: res['proteinas_g'] ?? 0,
          carboidratos: res['carboidratos_g'] ?? 0,
          gorduras: res['gorduras_g'] ?? 0,
        );
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'IA identificou: $nomePrato registradas com sucesso! 🥗',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar foto com IA: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoIA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planoCache = AppCache.planoAtual;
    final analiseNutricional =
        planoCache?['analise_nutricional'] ?? 'Diretrizes nutricionais ativas.';

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Diretrizes da Nutricionistas IA
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

          // **SUGESTÕES DIÁRIAS (Café, Almoço, Lanche, Jantar)**
          const Text(
            'Cardápio Sugerido para Hoje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sugestoesCardapio.length,
              itemBuilder: (context, index) {
                final sug = _sugestoesCardapio[index];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sug['refeicao'] ?? 'Refeição',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sug['itens'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${sug['calorias']} kcal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // **REGISTRAR REFEIÇÃO (TEXTO OU FOTO)**
          const Text(
            'Registrar Consumo Diário',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 2 ovos e 1 fatia de pão',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Texto
              IconButton(
                onPressed: _processandoIA ? null : _adicionarPorTexto,
                icon: const Icon(Icons.add, color: Colors.black),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 4),
              // **Botão Câmera / Foto do Prato**
              IconButton(
                onPressed: _processandoIA ? null : _adicionarPorFoto,
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),
              ),
            ],
          ),
          if (_processandoIA)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
          const SizedBox(height: 24),

          // Refeições Registradas
          const Text(
            'Refeições de Hoje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _refeicoes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
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
