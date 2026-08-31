import 'package:flutter/material.dart';

import 'usuario_repository.dart';
import 'metricas_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String username;
  final String senha;
  const OnboardingScreen({
    super.key,
    required this.username,
    required this.senha,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _alturaController = TextEditingController();

  String _generoSelecionado = 'M';
  DateTime _dataNascimento = DateTime(1995, 1, 1);
  bool _isLoading = false;

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && selecionada != _dataNascimento) {
      setState(() => _dataNascimento = selecionada);
    }
  }

  Future<void> _salvarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final repository = UsuarioRepository();

        final id = await repository.cadastrarUsuario(
          username: widget.username,
          senha: widget.senha,
          nome: _nomeController.text.trim(),
          genero: _generoSelecionado,
          dataNascimento: _dataNascimento,
          alturaCm: int.parse(_alturaController.text),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MetricasScreen(usuarioId: id),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Conte-nos um pouco sobre você',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('input_nome_real'),
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Seu Nome (ex: Matheus Gabriel)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('select_genero'),
                value: _generoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Gênero',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Feminino')),
                ],
                onChanged: (value) =>
                    setState(() => _generoSelecionado = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('input_altura'),
                controller: _alturaController,
                decoration: const InputDecoration(
                  labelText: 'Altura (cm)',
                  hintText: 'Ex: 175',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Informe sua altura' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('btn_data_nascimento'),
                title: const Text('Data de Nascimento'),
                subtitle: Text(
                  "${_dataNascimento.day}/${_dataNascimento.month}/${_dataNascimento.year}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(context),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const Key('btn_salvar_perfil'),
                onPressed: _isLoading ? null : _salvarUsuario,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Salvar e Avançar',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
