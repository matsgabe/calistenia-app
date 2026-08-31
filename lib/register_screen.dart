import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import 'usuario_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _avancarParaOnboarding() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repository = UsuarioRepository();
        final username = _usernameController.text.trim();

        // Valida se o username já está em uso
        final existe = await repository.verificarUsernameExiste(username);
        if (existe) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Este username já está em uso. Escolha outro.'),
              ),
            );
          }
          return;
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                username: username,
                senha: _senhaController.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Nova Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Defina suas credenciais',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                key: const Key('input_reg_username'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Escolha um Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('input_reg_senha'),
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 4 caracteres)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value!.length >= 4 ? null : 'Senha muito curta',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('btn_avancar_onboarding'),
                onPressed: _isLoading ? null : _avancarParaOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Avançar para Perfil',
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
