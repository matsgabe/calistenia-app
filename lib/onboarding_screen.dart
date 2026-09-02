import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'onboarding_repository.dart';

class OnboardingScreen extends StatefulWidget {
  final int usuarioId;
  const OnboardingScreen({super.key, required this.usuarioId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _idadeController = TextEditingController();
  final _restricoesController = TextEditingController();
  bool _consomeCarne = true;
  bool _temLesaoLombar = false;
  bool _temLesaoOmbro = false;

  String _sexoSelecionado = 'Masculino';

  final List<String> _objetivos = [
    'Hipertrofia (Ganhar massa muscular)',
    'Emagrecimento (Perder gordura)',
    'Condicionamento físico geral',
    'Definição muscular',
  ];
  late String _objetivoSelecionado = _objetivos.first;

  final List<String> _experiencias = [
    'Iniciante (Nunca fiz calistenia)',
    'Intermediário (Já treino há alguns meses)',
    'Avançado (Domino movimentos complexos)',
  ];
  late String _experienciaSelecionada = _experiencias.first;

  bool _isLoading = false;

  Future<void> _gerarPlanoComIA() async {
    if (_pesoController.text.isEmpty ||
        _alturaController.text.isEmpty ||
        _idadeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos numéricos.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = OnboardingRepository();

      // 1. Envia os dados para a IA estruturar o plano nutricional e de treino
      await repository.processarEPlanoIA(
        usuarioId: widget.usuarioId,
        peso: double.parse(_pesoController.text),
        altura: double.parse(_alturaController.text),
        idade: int.parse(_idadeController.text),
        sexo: _sexoSelecionado,
        objetivo: _objetivoSelecionado,
        experiencia: _experienciaSelecionada,
        consomeCarne: _consomeCarne,
        lesaoLombar: _temLesaoLombar,
        lesaoOmbro: _temLesaoOmbro,
      );

      if (mounted) {
        // 2. Finaliza e avança para a Home (ou substitui a tela)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(usuarioId: widget.usuarioId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar plano inteligente: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anamnese Inteligente 🧬'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nos conte sobre você',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nossa IA vai atuar como sua nutricionista e personal trainer para criar o plano perfeito.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildTextField('Peso (kg)', _pesoController)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField('Altura (cm)', _alturaController),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Idade', _idadeController)),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Sexo biológico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: ['Masculino', 'Feminino'].map((sexo) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(sexo, style: const TextStyle(fontSize: 13)),
                    value: sexo,
                    groupValue: _sexoSelecionado,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) => setState(() => _sexoSelecionado = val!),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            const Text(
              'Qual o seu principal objetivo?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _objetivoSelecionado,
              dropdownColor: Colors.grey.shade900,
              decoration: const InputDecoration(filled: true),
              items: _objetivos
                  .map((obj) => DropdownMenuItem(value: obj, child: Text(obj)))
                  .toList(),
              onChanged: (val) => setState(() => _objetivoSelecionado = val!),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nível atual na Calistenia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _experienciaSelecionada,
              dropdownColor: Colors.grey.shade900,
              decoration: const InputDecoration(filled: true),
              items: _experiencias
                  .map((exp) => DropdownMenuItem(value: exp, child: Text(exp)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _experienciaSelecionada = val!),
            ),

            // Dentro da Column de campos da OnboardingScreen:
            // Dentro da Column de campos da OnboardingScreen:
            const SizedBox(height: 20),
            const Text(
              'Hábitos Alimentares',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Consome carne / produtos de origem animal?'),
              value: _consomeCarne,
              activeColor: Colors.greenAccent,
              onChanged: (val) => setState(() => _consomeCarne = val),
            ),
            const SizedBox(height: 12),

            const Text(
              'Histórico de Lesões ou Dores',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Possui dores ou lesão na região Lombar?'),
              value: _temLesaoLombar,
              activeColor: Colors.greenAccent,
              onChanged: (val) => setState(() => _temLesaoLombar = val!),
            ),
            CheckboxListTile(
              title: const Text('Possui dores ou lesão nos Ombros?'),
              value: _temLesaoOmbro,
              activeColor: Colors.greenAccent,
              onChanged: (val) => setState(() => _temLesaoOmbro = val!),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _gerarPlanoComIA,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'GERAR PLANO INTELIGENTE COM IA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, filled: true),
    );
  }
}
