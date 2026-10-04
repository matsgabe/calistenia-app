import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para o TextInput.finishAutofillContext()
import 'package:supabase_flutter/supabase_flutter.dart';

import 'usuario_repository.dart';
import 'home_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  final _usuarioRepository = UsuarioRepository();

  bool _isLoading = false;
  bool _ocultarSenha = true;
  bool _manterConectado = true;

  @override
  void initState() {
    super.initState();
    _verificarSessaoSalva();
  }

  Future<void> _verificarSessaoSalva() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null && session.user.email != null) {
        final username = session.user.email!.split('@')[0];

        final response = await Supabase.instance.client
            .from('usuarios')
            .select('id')
            .eq('username', username)
            .maybeSingle();

        if (response != null && mounted) {
          final int usuarioId = response['id'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(usuarioId: usuarioId)),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar sessão salva: $e');
    }
  }

  Future<void> _entrar() async {
    final u = _usernameController.text.trim();
    final s = _senhaController.text.trim();

    if (u.isEmpty || s.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Notifica o navegador que o formulário foi concluído, ativando o pop-up de "Salvar Senha"
      TextInput.finishAutofillContext();

      final user = await _usuarioRepository.fazerLogin(u, s);
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(usuarioId: user['id']),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário ou senha incorretos.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro no login: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogEsqueciSenha() {
    final userResetController = TextEditingController();
    final novaSenhaController = TextEditingController();
    bool obscureNewPass = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E), // Fundo CyberFit
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Recuperar Senha 🔑',
                style: TextStyle(color: Colors.greenAccent, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Informe seu Username cadastrado e defina uma nova senha:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userResetController,
                    decoration: const InputDecoration(
                      hintText: 'Seu Username',
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: novaSenhaController,
                    obscureText: obscureNewPass,
                    decoration: InputDecoration(
                      hintText: 'Nova Senha',
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPass
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            obscureNewPass = !obscureNewPass;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final u = userResetController.text.trim();
                    final novaSenha = novaSenhaController.text.trim();

                    if (u.isEmpty || novaSenha.isEmpty) return;

                    try {
                      await _usuarioRepository.redefinirSenha(u, novaSenha);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Senha redefinida com sucesso! Faça login.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao redefinir: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
// Ícone que remete ao corpo humano em movimento / Calistenia + IA
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: Colors.greenAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CalistenIA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sua jornada de força começa aqui.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              AutofillGroup(
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      onEditingComplete: _entrar,
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _manterConectado,
                    activeColor: Colors.greenAccent,
                    checkColor: Colors.black,
                    onChanged: (bool? value) {
                      setState(() {
                        _manterConectado = value ?? true;
                      });
                    },
                  ),
                  const Text(
                    'Manter conectado',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _mostrarDialogEsqueciSenha,
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _entrar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('ENTRAR'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CadastroScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Não tem uma conta? Cadastre-se',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
