import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  void _mostrarLoadingIA(String mensagem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text(mensagem, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarEAnalisarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
      if (foto == null) return;

      if (mounted) _mostrarLoadingIA('Vision IA analisando prato...');

      final bytes = await foto.readAsBytes();
      final resultadoIA = await NutricaoIAService.analisarRefeicaoPorFoto(
        bytes,
      );

      if (mounted) Navigator.pop(context);

      if (resultadoIA != null) {
        await _dietaRepository.registrarRefeicao(
          usuarioId: widget.usuarioId,
          descricao:
              resultadoIA['nome_detectado'] ?? 'Refeição identificada pela IA',
          calorias: resultadoIA['calorias'] ?? 0,
          proteinas: resultadoIA['proteinas_g'] ?? 0,
          carboidratos: resultadoIA['carboidratos_g'] ?? 0,
          gorduras: resultadoIA['gorduras_g'] ?? 0,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refeição analisada e salva com sucesso! 🥗'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarRefeicoes();
        }
      } else {
        throw Exception("A IA não conseguiu identificar os alimentos.");
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao analisar prato: $e')));
      }
    }
  }

  Future<void> _registrarManual() async {
    final descricaoDigitada = _textoController.text.trim();
    if (descricaoDigitada.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (mounted) _mostrarLoadingIA('IA calculando macronutrientes...');

    try {
      final resultadoIA = await NutricaoIAService.analisarRefeicao(
        descricao: descricaoDigitada,
      );

      if (mounted) Navigator.pop(context);

      if (resultadoIA != null) {
        await _dietaRepository.registrarRefeicao(
          usuarioId: widget.usuarioId,
          descricao: descricaoDigitada,
          calorias: resultadoIA['calorias'] ?? 0,
          proteinas: resultadoIA['proteinas_g'] ?? 0,
          carboidratos: resultadoIA['carboidratos_g'] ?? 0,
          gorduras: resultadoIA['gorduras_g'] ?? 0,
        );

        _textoController.clear();
        _carregarRefeicoes();
      } else {
        throw Exception("Falha ao calcular os nutrientes.");
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao calcular alimento: $e')),
        );
      }
    }
  }

  // --- NOVA FUNÇÃO: EXCLUIR REFEIÇÃO ---
  Future<void> _excluirRefeicao(int id) async {
    try {
      await _dietaRepository.excluirRefeicao(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refeição excluída.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      _carregarRefeicoes(); // Atualiza a lista na tela
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
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
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.greenAccent,
                child: Icon(Icons.add, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _capturarEAnalisarFoto,
              borderRadius: BorderRadius.circular(50),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.greenAccent,
                child: Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

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
                        ref['nome_refeicao'] ?? 'Refeição',
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
                      // --- NOVO: BOTÃO DE EXCLUIR NA LATERAL DIREITA ---
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${ref['calorias']} kcal',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            tooltip: 'Excluir refeição',
                            onPressed: () {
                              // Exclui a refeição usando o ID dela salvo no banco
                              if (ref['id'] != null) {
                                _excluirRefeicao(ref['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
