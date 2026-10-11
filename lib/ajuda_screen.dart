import 'package:flutter/material.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Ajuda e Manuais',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Guia de Módulos do CalistenIA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Entenda como aproveitar ao máximo cada recurso do seu personal e nutricionista inteligente.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          SizedBox(height: 24),

          _CardAjudaModulo(
            icone: Icons.home_filled,
            titulo: '1. Módulo Home (Dashboard)',
            descricao: '• Análise Nutri & Personal IA: Resumo estratégico gerado sob medida para o seu objetivo.\n• Resumo Diário: Acompanhe suas calorias consumidas versus a meta calórica estabelecida.\n• Treino do Diário: Exibe o treino de calistenia gerado pela IA para o dia. Toque para iniciar e marcar como concluído!',
          ),
          SizedBox(height: 16),

          _CardAjudaModulo(
            icone: Icons.restaurant_menu,
            titulo: '2. Módulo Dieta',
            descricao: '• Registro Manual ou por Câmera: Digite o que comeu (ex: "2 ovos e arroz") ou tire foto/escolha da galeria para a Vision IA calcular os macros instantaneamente.\n• Cardápio Sugerido: Opção retrátil com as sugestões diárias da IA. Basta tocar no botão (+) para registrar o prato sugerido com um clique.',
          ),
          SizedBox(height: 16),

          _CardAjudaModulo(
            icone: Icons.water_drop,
            titulo: '3. Hidratação Diária',
            descricao: '• Calculada automaticamente com base no seu peso corporal.\n• Utilize os botões rápidos de (+250 ml) e (+500 ml) para atualizar sua ingestão diária de água em tempo real.',
          ),
          SizedBox(height: 16),

          _CardAjudaModulo(
            icone: Icons.history,
            titulo: '4. Histórico e Calendário',
            descricao: '• Navegue pelo calendário mensal para consultar o histórico de treinos e consumo calórico de dias anteriores ou futuros.',
          ),
          SizedBox(height: 16),

          _CardAjudaModulo(
            icone: Icons.manage_accounts,
            titulo: '5. Configurações e Perfil',
            descricao: '• Atualize seu peso, altura, objetivo (Hipertrofia, Emagrecimento, etc.) e nível na calistenia a qualquer momento para recalcular automaticamente seus planos.',
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CardAjudaModulo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _CardAjudaModulo({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
