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

  // Controladores
  final _nomeController = TextEditingController();
  final _senhaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();

  // Controle de visibilidade da senha
  bool _senhaOculta = true;

  String _objetivoSelecionado = 'Hipertrofia (Ganhar massa muscular)';
  String _nivelSelecionado = 'Iniciante (Nunca fiz calistenia)';
  bool _isLoading = false;

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

  String _mapearObjetivoParaBanco(String objetivoUI) {
    if (objetivoUI.contains('Hipertrofia')) return 'Hipertrofia';
    if (objetivoUI.contains('Emagrecer')) return 'Perder Peso';
    if (objetivoUI.contains('Manter')) return 'Manutencao';
    return 'Hipertrofia';
  }

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
      final userResponse = await Supabase.instance.client
          .from('usuarios')
          .select('nome, altura_cm')
          .eq('id', widget.usuarioId)
          .maybeSingle();

      if (userResponse != null) {
        if (userResponse['nome'] != null) {
          _nomeController.text = userResponse['nome'].toString();
        }
        if (userResponse['altura_cm'] != null) {
          _alturaController.text = userResponse['altura_cm'].toString();
        }
      }

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

  Future<void> _salvarConfiguracoes() async {
    final peso =
        double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 0.0;
    final altura =
        double.tryParse(_alturaController.text.replaceAll(',', '.')) ?? 0.0;
    final novoNome = _nomeController.text.trim();
    final novaSenha = _senhaController.text.trim();

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
      if (novoNome.isNotEmpty) {
        await Supabase.instance.client
            .from('usuarios')
            .update({'nome': novoNome})
            .eq('id', widget.usuarioId);
      }

      if (novaSenha.isNotEmpty && novaSenha.length >= 6) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: novaSenha),
        );
      } else if (novaSenha.isNotEmpty) {
        throw Exception('A senha deve ter pelo menos 6 caracteres.');
      }

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
            content: Text('Configurações e perfil atualizados com sucesso! 🚀'),
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
          'Configurações e Perfil',
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
                    'Gerencie suas informações cadastrais e métricas para recalcular seus treinos e dieta sob medida.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- SEÇÃO: DADOS CADASTRAIS ---
                  const Text(
                    'Dados Cadastrais',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person, color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _senhaController,
                    obscureText: _senhaOculta,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nova Senha (Opcional)',
                      hintText: 'Mínimo de 6 caracteres',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.greenAccent,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaOculta
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _senhaOculta = !_senhaOculta;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SEÇÃO: MÉTRICAS E OBJETIVOS ---
                  const Text(
                    'Métricas e Objetivos (IA)',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pesoController,
                          style: const TextStyle(color: Colors.white),
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _alturaController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Altura (cm)',
                            prefixIcon: Icon(
                              Icons.height,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Principal objetivo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
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
                      fontSize: 13,
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
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
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
                      onPressed: _isLoading ? null : _salvarConfiguracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'SALVAR ALTERAÇÕES',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
