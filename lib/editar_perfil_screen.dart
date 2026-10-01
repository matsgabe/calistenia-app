import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'usuario_repository.dart';
import 'nutricao_ia_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final int usuarioId;
  const EditarPerfilScreen({super.key, required this.usuarioId});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _repository = UsuarioRepository();

  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();

  // Exibe o texto amigável completo na UI
  String _objetivoSelecionado = 'Hipertrofia (Ganhar massa muscular)';
  String _nivelSelecionado = 'Iniciante (Nunca fiz calistenia)';
  bool _isLoading = false;

  // Textos completos para a UI iguais aos do cadastro
  final List<String> _objetivosExibicao = [
    'Hipertrofia (Ganhar massa muscular)',
    'Emagrecer (Perder gordura)',
    'Manter forma atual',
  ];

  final List<String> _niveisExibicao = [
    'Iniciante (Nunca fiz calistenia)',
    'Intermediário (Faço o básico)',
    'Avançado (Faço Muscle Up)',
  ];

  // Mapeia o texto amigável da UI para o formato aceito pelo banco de dados (enum)
  String _mapearObjetivoParaBanco(String objetivoUI) {
    if (objetivoUI.contains('Hipertrofia')) return 'Hipertrofia';
    if (objetivoUI.contains('Emagrecer')) return 'Perder Peso';
    if (objetivoUI.contains('Manter')) return 'Manutencao';
    return 'Hipertrofia';
  }

  // Mapeia o valor do banco de volta para o texto completo amigável da UI
  String _mapearObjetivoParaUI(String objetivoBanco) {
    if (objetivoBanco == 'Hipertrofia') {
      return 'Hipertrofia (Ganhar massa muscular)';
    }
    if (objetivoBanco == 'Emagrecer' || objetivoBanco == 'Perder Peso') {
      return 'Emagrecer (Perder gordura)';
    }
    if (objetivoBanco == 'Manutencao') return 'Manter forma atual';
    return 'Hipertrofia (Ganhar massa muscular)';
  }

  String _mapearNivelParaBanco(String nivelUI) {
    if (nivelUI.contains('Iniciante')) return 'Leve';
    if (nivelUI.contains('Intermediário')) return 'Moderado';
    if (nivelUI.contains('Avançado')) return 'Intenso';
    return 'Leve';
  }

  String _mapearNivelParaUI(String nivelBanco) {
    if (nivelBanco == 'Leve') return 'Iniciante (Nunca fiz calistenia)';
    if (nivelBanco == 'Moderado') return 'Intermediário (Faço o básico)';
    if (nivelBanco == 'Intenso') return 'Avançado (Faço Muscle Up)';
    return 'Iniciante (Nunca fiz calistenia)';
  }

  @override
  void initState() {
    super.initState();
    _carregarDadosAtuais();
  }

  Future<void> _carregarDadosAtuais() async {
    setState(() => _isLoading = true);
    try {
      // 1. Busca a altura real na tabela 'usuarios'
      final userResponse = await Supabase.instance.client
          .from('usuarios')
          .select('altura_cm')
          .eq('id', widget.usuarioId)
          .maybeSingle();

      if (userResponse != null && userResponse['altura_cm'] != null) {
        _alturaController.text = userResponse['altura_cm'].toString();
      }

      // 2. Busca o histórico recente (peso, objetivo, nível)
      final historico = await _repository.buscarHistoricoRecente(
        widget.usuarioId,
      );
      if (historico.isNotEmpty) {
        final ultimo = historico.first;
        setState(() {
          if (ultimo['peso_kg'] != null) {
            _pesoController.text = ultimo['peso_kg'].toString();
          }

          final objBanco = ultimo['objetivo']?.toString();
          if (objBanco != null) {
            _objetivoSelecionado = _mapearObjetivoParaUI(objBanco);
          }

          final nivBanco =
              ultimo['nivel_atividade']?.toString() ??
              ultimo['nivel']?.toString();
          if (nivBanco != null) {
            _nivelSelecionado = _mapearNivelParaUI(nivBanco);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar dados para edição: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarEAtualizarIA() async {
    final peso =
        double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 0.0;
    final altura =
        double.tryParse(_alturaController.text.replaceAll(',', '.')) ?? 0.0;

    if (peso <= 0 || altura <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insira valores válidos para peso e altura.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Salva convertendo para o formato do banco de dados
      await _repository.atualizarPerfilCompleto(
        usuarioId: widget.usuarioId,
        pesoKg: peso,
        alturaCm: altura,
        objetivo: _mapearObjetivoParaBanco(_objetivoSelecionado),
        nivel: _mapearNivelParaBanco(_nivelSelecionado),
      );

      final novoPlanoIA = await NutricaoIAService.gerarPlanoCompleto(
        peso: peso,
        consomeCarne: true,
        objetivo: _objetivoSelecionado,
        nivel: _nivelSelecionado,
        lesaoLombar: false,
        lesaoOmbro: false,
        historicoRecente: [],
      );

      if (novoPlanoIA != null) {
        await _repository.gravarPlanoDiario(
          usuarioId: widget.usuarioId,
          dadosIA: novoPlanoIA,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado e IA recalculada com sucesso! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Atualizar Perfil e Metas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corrija sua altura ou atualize suas métricas para a IA recalcular sua dieta e treinos sob medida.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _pesoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Peso Atual (kg)',
                      prefixIcon: Icon(
                        Icons.monitor_weight,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _alturaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height, color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Qual o seu principal objetivo?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _objetivoSelecionado,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1C1C1E),
                    items: _objetivosExibicao
                        .map(
                          (obj) => DropdownMenuItem(
                            value: obj,
                            child: Text(
                              obj,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _objetivoSelecionado = val!),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flag, color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Nível atual na Calistenia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _nivelSelecionado,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1C1C1E),
                    items: _niveisExibicao
                        .map(
                          (niv) => DropdownMenuItem(
                            value: niv,
                            child: Text(
                              niv,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _nivelSelecionado = val!),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.trending_up,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarEAtualizarIA,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                      ),
                      child: const Text(
                        'RECALCULAR COM IA',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
