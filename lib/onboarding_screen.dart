import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'usuario_repository.dart';
import 'metricas_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _alturaController = TextEditingController();

  String _generoSelecionado = 'M';
  DateTime _dataNascimento = DateTime(1995, 1, 1);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarEmailAutenticado();
  }

  void _carregarEmailAutenticado() {
    final user = _supabase.auth.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && selecionada != _dataNascimento) {
      setState(() {
        _dataNascimento = selecionada;
      });
    }
  }

  Future<void> _salvarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final repository = UsuarioRepository();

        final id = await repository.cadastrarUsuario(
          nome: _nomeController.text,
          email: _emailController.text,
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
              TextFormField(
                key: const Key('input_nome'),
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome ou Apelido'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('input_email'),
                controller: _emailController,
                readOnly: true, // E-mail vem travado da autenticação
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  helperText: 'Vinculado à sua conta de acesso',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('select_genero'),
                value: _generoSelecionado,
                decoration: const InputDecoration(labelText: 'Gênero'),
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
