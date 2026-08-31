import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'onboarding_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _autenticar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          // Login
          final response = await _supabase.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );
          if (response.user != null && mounted) {
            // Vai direto para a Home se já tiver perfil
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen(usuarioId: 1)),
            );
          }
        } else {
          // Cadastro via Supabase Auth
          final response = await _supabase.auth.signUp(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

          if (response.user != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conta criada! Preencha seu perfil.'),
              ),
            );
            // Vai para o Onboarding complementar
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro na autenticação: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Entrar no Calistenia App' : 'Criar Conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail válido'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.contains('@') ? null : 'Insira um e-mail válido',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 6 caracteres)',
                ),
                obscureText: true,
                validator: (value) =>
                    value!.length >= 6 ? null : 'Senha muito curta',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _autenticar,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLogin ? 'Entrar' : 'Cadastrar'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? 'Não tem uma conta? Cadastre-se'
                      : 'Já tem uma conta? Entre',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
