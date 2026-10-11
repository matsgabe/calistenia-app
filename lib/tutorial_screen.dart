import 'package:flutter/material.dart';

import 'home_screen.dart';

class TutorialScreen extends StatefulWidget {
  final int usuarioId;
  const TutorialScreen({super.key, required this.usuarioId});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _paginaAtual = 0;

  // Lista de slides com seus respectivos ícones específicos
  final List<Map<String, dynamic>> _slides = [
    {
      'titulo': 'Bem-vindo ao CalistenIA 🚀',
      'descricao': 'Seu personal trainer e nutricionista inteligente integrando inteligência artificial e calistenia de alta performance.',
      'icone': Icons.psychology, // Ícone de IA / Análise
    },
    {
      'titulo': 'Treinos sob Medida 🦾',
      'descricao': 'A IA avalia sua constância e gera treinos diários personalizados para o seu nível e evolução corporal.',
      'icone':
          Icons.accessibility_new, // Ícone de Calistenia / Corpo em movimento
    },
    {
      'titulo': 'Dieta Inteligente & Foto 🥗',
      'descricao': 'Registre o que come digitando ou tirando foto do seu prato. A Vision IA calcula calorias e macronutrientes na hora!',
      'icone': Icons.restaurant_menu, // Ícone de Dieta e Refeições
    },
    {
      'titulo': 'Constância e Hidratação 💧',
      'descricao': 'Acompanhe sua sequência de treinos (streaks), meta de água diária e conquiste insígnias exclusivas no seu histórico.',
      'icone': Icons.water_drop, // Ícone de Hidratação
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(usuarioId: widget.usuarioId),
                      ),
                    );
                  },
                  child: const Text(
                    'Pular',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _paginaAtual = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Círculo com o ícone específico do módulo
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            slide['icone']
                                as IconData, // Ícone dinâmico do slide
                            size: 64,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['titulo']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['descricao']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _paginaAtual == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _paginaAtual == index
                          ? Colors.greenAccent
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_paginaAtual < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HomeScreen(usuarioId: widget.usuarioId),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _paginaAtual == _slides.length - 1
                        ? 'COMEÇAR AGORA'
                        : 'PRÓXIMO',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
