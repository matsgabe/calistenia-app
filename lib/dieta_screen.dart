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
  final _repository = DietaRepository();
  List<Map<String, dynamic>> _refeicoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarRefeicoes();
  }

  Future<void> _carregarRefeicoes() async {
    try {
      final dados = await _repository.buscarRefeicoesDoDia(widget.usuarioId);
      if (mounted) {
        setState(() {
          _refeicoes = dados;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dieta: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirModalInteligente() {
    final descricaoController = TextEditingController();
    XFile? imagemSelecionada;
    bool processandoIA = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text(
                        'Nutricionista IA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Descreva o que você comeu ou envie uma foto do prato. A IA calcula os macros para você!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 2 ovos mexidos, 1 fatia de pão integral e um café com leite...',
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final foto = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (foto != null) {
                            setModalState(() {
                              imagemSelecionada = foto;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.greenAccent,
                        ),
                        label: Text(
                          imagemSelecionada == null
                              ? 'Tirar Foto do Prato'
                              : 'Foto Anexada 📷',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: processandoIA
                          ? null
                          : () async {
                              if (descricaoController.text.isEmpty &&
                                  imagemSelecionada == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Insira uma descrição ou tire uma foto.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => processandoIA = true);

                              try {
                                final bytes = imagemSelecionada != null
                                    ? await imagemSelecionada!.readAsBytes()
                                    : null;

                                final resultadoIA =
                                    await NutricaoIAService.analisarRefeicao(
                                      descricao: descricaoController.text,
                                      imagemBytes: bytes,
                                    );

                                if (resultadoIA != null && mounted) {
                                  await _repository.registrarRefeicao(
                                    usuarioId: widget.usuarioId,
                                    nome: resultadoIA['nome'],
                                    calorias: resultadoIA['calorias'],
                                    proteinas: resultadoIA['proteinas'],
                                    carboidratos: resultadoIA['carboidratos'],
                                    gorduras: resultadoIA['gorduras'],
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(
                                      context,
                                    );
                                  }
                                  _carregarRefeicoes();
                                }
                              } catch (e) {
                                debugPrint('Erro na IA: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao analisar com IA: $e',
                                      ),
                                    ),
                                  );
                                }
                                setModalState(() => processandoIA = false);
                              }
                            },
                      child: processandoIA
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ANALISAR E SALVAR COM IA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : _refeicoes.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma refeição registrada hoje.\nClique no + para registrar com IA.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _refeicoes.length,
              itemBuilder: (context, index) {
                final ref = _refeicoes[index];
                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.restaurant,
                      color: Colors.greenAccent,
                    ),
                    title: Text(
                      ref['nome_refeicao'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${ref['calorias']} kcal | Prot: ${ref['proteinas_g']}g | Carb: ${ref['carboidratos_g']}g | Gord: ${ref['gorduras_g']}g',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalInteligente,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
    );
  }
}
