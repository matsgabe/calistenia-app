import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dieta_repository.dart';

class DietaScreen extends StatefulWidget {
  final int usuarioId;
  const DietaScreen({super.key, required this.usuarioId});

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> {
  final _dietaRepository = DietaRepository();
  final _textoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<Map<String, dynamic>> _refeicoesHoje = [];

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
          _refeicoesHoje = refeicoes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fluxo de captura de foto e Análise da IA
  Future<void> _capturarEAnalisarFoto() async {
    try {
      // 1. Abre a câmera ou galeria
      final XFile? foto = await _picker.pickImage(source: ImageSource.camera);

      if (foto == null) return; // Usuário cancelou

      // 2. Exibe modal de carregamento estiloso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: Color(0xFF1E1E1E),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.greenAccent),
                SizedBox(height: 16),
                Text(
                  'Vision IA analisando prato...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      // 3. Simulação da API de Visão Computacional (Gemini Vision)
      // No futuro, aqui você passa os bytes da 'foto' para o Google Generative AI
      await Future.delayed(const Duration(seconds: 3));

      // Retorno simulado da IA
      final String descricaoIA =
          "Prato de Frango Grelhado com Batata Doce e Salada";
      final int kcalIA = 420;
      final int protIA = 45;
      final int carbIA = 35;
      final int gordIA = 10;

      // 4. Salva no Supabase
      await _dietaRepository.registrarRefeicao(
        usuarioId: widget.usuarioId,
        descricao: descricaoIA,
        calorias: kcalIA,
        proteinas: protIA,
        carboidratos: carbIA,
        gorduras: gordIA,
      );

      // 5. Fecha modal e recarrega
      if (mounted) {
        Navigator.pop(context); // Fecha o modal de loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refeição identificada e salva com sucesso! 🥗'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarRefeicoes(); // Atualiza a lista na tela
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha o modal em caso de erro
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao analisar prato: $e')));
      }
    }
  }

  // Registro manual via texto (botão +)
  Future<void> _registrarManual() async {
    if (_textoController.text.trim().isEmpty) return;

    // Simplificação para registro manual rápido (em um app real a IA de texto avaliaria isso)
    await _dietaRepository.registrarRefeicao(
      usuarioId: widget.usuarioId,
      descricao: _textoController.text.trim(),
      calorias: 300, // Valores genéricos para exemplo manual
      proteinas: 15,
      carboidratos: 30,
      gorduras: 10,
    );

    _textoController.clear();
    FocusScope.of(context).unfocus();
    _carregarRefeicoes();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- DIRETRIZES DA NUTRI IA ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Diretrizes da Nutricionista IA',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Para promover a hipertrofia muscular com foco em calistenia, precisamos de um leve superávit calórico. Suas refeições devem combinar proteínas de alto valor biológico com carboidratos complexos para garantir energia plena nos treinos.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- CARDÁPIO SUGERIDO ---
        const Text(
          'Cardápio Sugerido para Hoje',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardRefeicao(
                'Café da Manhã',
                'Ovos mexidos, pão integral e banana',
                '450 kcal',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardRefeicao(
                'Almoço',
                'Carne bovina magra, arroz, feijão e azeite',
                '750 kcal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- REGISTRAR CONSUMO ---
        const Text(
          'Registrar Consumo Diário',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textoController,
                decoration: InputDecoration(
                  hintText: 'Ex: 2 ovos e 1 fatia de pão',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _registrarManual,
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.greenAccent,
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _capturarEAnalisarFoto, // CHAMA A CAMERA E IA AQUI!
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.greenAccent,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- LISTAGEM DE REFEIÇÕES DO DIA ---
        const Text(
          'Refeições de Hoje',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _refeicoesHoje.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
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
                itemCount: _refeicoesHoje.length,
                itemBuilder: (context, index) {
                  final ref = _refeicoesHoje[index];
                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: Icon(
                          Icons.local_dining,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        ref['descricao'] ?? 'Refeição',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'P: ${ref['proteinas_g']}g  |  C: ${ref['carboidratos_g']}g  |  G: ${ref['gorduras_g']}g',
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
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCardRefeicao(String titulo, String desc, String kcal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            kcal,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
