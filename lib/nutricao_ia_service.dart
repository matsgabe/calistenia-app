import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutricaoIAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<Map<String, dynamic>?> _chamarAPI(
    String nomeModelo,
    List<Content> conteudo,
  ) async {
    final model = GenerativeModel(
      model: nomeModelo,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final response = await model.generateContent(conteudo);
    if (response.text == null) return null;
    return jsonDecode(response.text!);
  }

  static Future<Map<String, dynamic>?> analisarRefeicao({
    required String descricao,
  }) async {
    final prompt =
        '''
    Atue como um nutricionista esportivo. Analise o alimento descrito: "$descricao".
    Retorne obrigatoriamente um JSON com as chaves exatas:
    - "calorias": int,
    - "proteinas_g": int,
    - "carboidratos_g": int,
    - "gorduras_g": int
    ''';

    final conteudo = [Content.text(prompt)];

    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando 3.5-flash...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }

  static Future<Map<String, dynamic>?> analisarRefeicaoPorFoto(
    Uint8List imageBytes,
  ) async {
    final prompt = '''
    Atue como um nutricionista esportivo. Analise a foto deste prato de comida.
    Identifique os alimentos, estime as gramaturas visuais e calcule o total aproximado.
    Retorne obrigatoriamente um JSON com as chaves exatas:
    - "nome_detectado": "Nome descritivo dos alimentos vistos na foto",
    - "calorias": int,
    - "proteinas_g": int,
    - "carboidratos_g": int,
    - "gorduras_g": int
    ''';

    final conteudo = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: 3.5-flash-lite falhou ($e). Tentando 3.5-flash...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }

  // --- NOVA FUNÇÃO: GERA DIETA E TREINO DE CALISTENIA JUNTOS ---
  static Future<Map<String, dynamic>?> gerarPlanoCompleto({
    required double peso,
    required bool consomeCarne,
    required String objetivo,
    required String nivel,
    required bool lesaoLombar,
    required bool lesaoOmbro,
  }) async {
    final prompt =
        '''
    Atue como um personal trainer de elite e nutricionista especialista em Calistenia (treino estrito com peso corporal).
    
    Perfil do Atleta:
    - Peso: $peso kg
    - Objetivo: $objetivo
    - Nível na Calistenia: $nivel
    - Consome carne: $consomeCarne
    - Dores/Lesões: Lombar ($lesaoLombar), Ombros ($lesaoOmbro).

    Crie um plano completo. Os exercícios de treino DEVEM utilizar APENAS o peso do próprio corpo. Adapte e substitua exercícios que possam forçar a lombar ou ombros caso o atleta possua lesões nessas áreas.
    
    Retorne OBRIGATORIAMENTE um JSON com as chaves exatas:
    {
      "sugestoes": [
        {"refeicao": "Café da Manhã", "itens": "Ex: Ovos mexidos e pão", "calorias": 350},
        {"refeicao": "Almoço", "itens": "Ex: Frango e arroz", "calorias": 650},
        {"refeicao": "Café da Tarde", "itens": "Ex: Aveia e iogurte", "calorias": 300},
        {"refeicao": "Jantar", "itens": "Ex: Salada e atum", "calorias": 500}
      ],
      "treino_sugerido_nome": "Treino de Calistenia ($nivel)",
      "resumo_analise": "Análise focada no condicionamento de calistenia para este atleta...",
      "exercicios": [
        {
          "nome": "Flexão de Braços (Push-up)",
          "series": 3,
          "repeticoes": "10 a 15",
          "instrucoes": "Mantenha o corpo em prancha reta. Desça até o peito quase tocar o chão e empurre explosivamente. Mantenha os cotovelos a 45 graus para proteger os ombros."
        },
        // Gere entre 5 e 6 exercícios completos
      ]
    }
    ''';

    final conteudo = [Content.text(prompt)];

    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando 3.5-flash...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }
}
