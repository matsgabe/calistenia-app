import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';

class AnamneseScreen extends StatefulWidget {
  final int usuarioId;
  const AnamneseScreen({super.key, required this.usuarioId});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  // 1. Variáveis agora começam vazias
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _idadeController = TextEditingController();

  String? _sexoBiologico;
  String? _objetivoSelecionado;
  String? _nivelSelecionado;

  bool _consomeCarne = false; // Começa desativado
  bool _dorLombar = false;
  bool _dorOmbros = false;

  bool _isLoading = false;

  Future<void> _gerarPlano() async {
    // 2. Validação: Impede o envio se faltar alguma informação
    if (_pesoController.text.isEmpty ||
        _alturaController.text.isEmpty ||
        _idadeController.text.isEmpty ||
        _sexoBiologico == null ||
        _objetivoSelecionado == null ||
        _nivelSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final int idade = int.tryParse(_idadeController.text) ?? 18;
      final int anoNascimento = DateTime.now().year - idade;
      final String dataNascimentoFormatada = '$anoNascimento-01-01';

      // Atualiza os dados físicos na tabela 'usuarios'
      await supabase
          .from('usuarios')
          .update({
            'data_nascimento': dataNascimentoFormatada,
            'altura_cm': int.tryParse(_alturaController.text) ?? 170,
            'genero': _sexoBiologico == 'Masculino' ? 'M' : 'F',
          })
          .eq('id', widget.usuarioId);

      // Mapeamento para o enum do banco
      String objetivoBanco = 'Hipertrofia';
      if (_objetivoSelecionado!.contains('Emagrecer'))
        objetivoBanco = 'Perder Peso';
      if (_objetivoSelecionado!.contains('Manter'))
        objetivoBanco = 'Manutencao';

      String nivelBanco = 'Leve';
      if (_nivelSelecionado!.contains('Intermediário')) nivelBanco = 'Moderado';
      if (_nivelSelecionado!.contains('Avançado')) nivelBanco = 'Intenso';

      final hoje = DateTime.now().toIso8601String().split('T')[0];
      await supabase.from('historico_fisico').insert({
        'usuario_id': widget.usuarioId,
        'data_registro': hoje,
        'peso_kg': double.tryParse(_pesoController.text) ?? 75.0,
        'objetivo': objetivoBanco,
        'nivel_atividade': nivelBanco,
      });

      // (Opcional) Simula tempo de processamento da IA
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(usuarioId: widget.usuarioId),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar dados: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text(
          'Anamnese Inteligente 🧬',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nos conte sobre você',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nossa IA vai atuar como sua nutricionista e personal trainer para criar o plano perfeito.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildMiniInput(
                    'Peso (kg)',
                    _pesoController,
                    'Ex: 75',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniInput(
                    'Altura (cm)',
                    _alturaController,
                    'Ex: 175',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniInput('Idade', _idadeController, 'Ex: 25'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Sexo biológico',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Masculino',
                  groupValue: _sexoBiologico,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) => setState(() => _sexoBiologico = val),
                ),
                const Text(
                  'Masculino',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Feminino',
                  groupValue: _sexoBiologico,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) => setState(() => _sexoBiologico = val),
                ),
                const Text('Feminino', style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Qual o seu principal objetivo?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _objetivoSelecionado,
              hint: 'Selecione seu objetivo',
              items: [
                'Hipertrofia (Ganhar massa muscular)',
                'Emagrecer (Perder gordura)',
                'Manter forma atual',
              ],
              onChanged: (val) => setState(() => _objetivoSelecionado = val),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nível atual na Calistenia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _nivelSelecionado,
              hint: 'Selecione sua experiência',
              items: [
                'Iniciante (Nunca fiz calistenia)',
                'Intermediário (Faço o básico)',
                'Avançado (Faço Muscle Up)',
              ],
              onChanged: (val) => setState(() => _nivelSelecionado = val),
            ),
            const SizedBox(height: 24),

            const Text(
              'Hábitos Alimentares',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.greenAccent,
              title: const Text(
                'Consome carne / produtos de origem animal?',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              value: _consomeCarne,
              onChanged: (val) => setState(() => _consomeCarne = val),
            ),
            const SizedBox(height: 12),

            const Text(
              'Histórico de Lesões ou Dores',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            _buildCheckbox(
              'Possui dores ou lesão na região Lombar?',
              _dorLombar,
              (val) => setState(() => _dorLombar = val!),
            ),
            _buildCheckbox(
              'Possui dores ou lesão nos Ombros?',
              _dorOmbros,
              (val) => setState(() => _dorOmbros = val!),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _gerarPlano,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF202024),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white30)
                    : const Text(
                        'GERAR PLANO INTELIGENTE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInput(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF29292E),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.white24,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 0),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF29292E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          dropdownColor: const Color(0xFF29292E),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.grey),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: Colors.greenAccent,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
