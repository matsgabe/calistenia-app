import 'package:flutter/material.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'usuario_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _efetuarLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repository = UsuarioRepository();
        final usuario = await repository.fazerLogin(
          _usernameController.text.trim(),
          _senhaController.text.trim(),
        );

        if (!mounted) return;

        if (usuario != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(usuarioId: usuario['id']),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Usuário ou senha incorretos, ou conta não existe.',
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
      appBar: AppBar(title: const Text('Entrar no Calistenia App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Bem-vindo de volta!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                key: const Key('input_login_username'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe seu username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('input_login_senha'),
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? 'Informe sua senha' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('btn_fazer_login'),
                onPressed: _isLoading ? null : _efetuarLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Entrar', style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                key: const Key('btn_ir_para_registro'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Não tem uma conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
