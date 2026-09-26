import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'usuario_repository.dart';
import 'anamnese_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State {
  final _nomeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _ocultarSenha = true;

  // Variáveis para o feedback visual dinâmico da senha
  bool _temTamanho = false;
  bool _temLetra = false;
  bool _temNumero = false;
  bool _temEspecial = false;

  @override
  void initState() {
    super.initState();
    // Ouve tudo o que o usuário digita na senha em tempo real
    _senhaController.addListener(() {
      final senha = _senhaController.text;
      setState(() {
        _temTamanho = senha.length >= 8;
        _temLetra = RegExp(r'[a-zA-Z]').hasMatch(senha);
        _temNumero = RegExp(r'\d').hasMatch(senha);
        _temEspecial = RegExp(r'[^a-zA-Z0-9]').hasMatch(senha);
      });
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _usernameController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  bool _isSenhaTotalmenteValida() {
    return _temTamanho && _temLetra && _temNumero && _temEspecial;
  }

  Future _cadastrar() async {
    final nome = _nomeController.text.trim();
    final username = _usernameController.text.trim();
    final senha = _senhaController.text.trim();

    if (nome.isEmpty || username.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (!_isSenhaTotalmenteValida()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A senha não atende a todos os requisitos de segurança.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = UsuarioRepository();

      bool existe = await repository.verificarUsernameExiste(username);
      if (existe) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este username já está em uso.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final int novoId = await repository.cadastrarUsuario(
        nome: nome,
        username: username,
        senha: senha,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnamneseScreen(usuarioId: novoId),
          ),
        );
      }
    } on AuthException catch (e) {
      // Captura erros ESPECÍFICOS do Supabase e traduz para o usuário
      if (mounted) {
        String mensagemErro = 'Erro de autenticação.';
        if (e.message.contains('Password should be at least')) {
          mensagemErro =
              'A senha fornecida é considerada muito fraca pelo servidor.';
        } else if (e.message.contains('User already registered')) {
          mensagemErro = 'Este usuário já possui cadastro oficial no sistema.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro inesperado ao realizar o cadastro.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Componente visual para desenhar os requisitos da senha
  Widget _buildRegraSenha(String texto, bool cumprida) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            cumprida ? Icons.check_circle : Icons.circle_outlined,
            color: cumprida ? Colors.greenAccent : Colors.grey.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: cumprida ? Colors.white : Colors.grey.shade500,
              fontSize: 12,
              fontWeight: cumprida ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Criar Conta',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Junte-se à CalistenIA e comece sua evolução.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  hintText: 'Nome Completo',
                  prefixIcon: Icon(Icons.badge, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Username (ex: matsgabe)',
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                onChanged: (val) {
                  // O listener no initState já faz o trabalho, mas garantimos a atualização visual aqui
                },
                decoration: InputDecoration(
                  hintText: 'Senha',
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarSenha = !_ocultarSenha;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- PAINEL DE REQUISITOS DA SENHA ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSenhaTotalmenteValida()
                        ? Colors.greenAccent.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A senha deve conter:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildRegraSenha('No mínimo 8 caracteres', _temTamanho),
                    _buildRegraSenha('Pelo menos 1 letra', _temLetra),
                    _buildRegraSenha('Pelo menos 1 número', _temNumero),
                    _buildRegraSenha(
                      'Pelo menos 1 caractere especial (!@#\$&*)',
                      _temEspecial,
                    ),
                  ],
                ),
              ),
              // -------------------------------------

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _cadastrar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('CADASTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
