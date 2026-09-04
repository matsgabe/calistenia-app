import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'anamnese_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final username = _usernameController.text.trim();
    final senha = _senhaController.text.trim();

    if (nome.isEmpty || username.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailFormatado = username.contains('@')
          ? username
          : '$username@calistenia.app';

      // 1. Registra no Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: emailFormatado,
        password: senha,
      );

      final user = res.user;
      if (user != null) {
        // 2. Salva na tabela 'usuarios' preenchendo todos os "Not Null" provisoriamente
        final usuarioData = await Supabase.instance.client
            .from('usuarios')
            .insert({
              'nome': nome,
              'username': username,
              'genero': 'M', // Valor provisório válido
              'data_nascimento':
                  '2000-01-01', // Valor provisório para evitar erro Not Null
              'altura_cm': 0, // Valor provisório para evitar erro Not Null
            })
            .select('id')
            .single();

        final int usuarioId = usuarioData['id'];

        // 3. Redireciona para a tela de Anamnese
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AnamneseScreen(usuarioId: usuarioId),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      // Captura erros específicos de Login/Cadastro (ex: senha curta, email desabilitado)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de Autenticação: ${e.message}')),
        );
      }
    } on PostgrestException catch (e) {
      // Captura erros específicos do Banco de Dados (ex: RLS, coluna faltando)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro no Banco: ${e.message}')));
      }
    } catch (e) {
      // Qualquer outro erro
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
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
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.greenAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Calistenia IA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            _buildTextField(
              controller: _nomeController,
              hint: 'Nome completo',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usernameController,
              hint: 'Username',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _senhaController,
              hint: 'Senha',
              icon: Icons.lock,
              obscure: true,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cadastrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'CADASTRAR E CONTINUAR',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade900,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
