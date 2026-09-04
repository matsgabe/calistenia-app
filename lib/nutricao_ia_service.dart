import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // Importado para usar o debugPrint
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutricaoIAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Função auxiliar para gerenciar a chamada e evitar repetição de código
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

    // Mecanismo de Fallback
    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando 1.5-flash...',
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

    // Mecanismo de Fallback
    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando 1.5-flash...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }

  static Future<Map<String, dynamic>?> gerarCardapioDiario({
    required double peso,
    required bool consomeCarne,
    required String objetivo,
  }) async {
    final prompt =
        '''
    Atue como um nutricionista esportivo. Crie um cardápio diário completo para um usuário com peso $peso kg, objetivo $objetivo, consome carne: $consomeCarne.
    Retorne um JSON contendo uma lista com 4 refeições nas chaves exatas:
    - "sugestoes": [
        {"refeicao": "Café da Manhã", "itens": "Ex: Ovos mexidos e pão integral", "calorias": 350},
        {"refeicao": "Almoço", "itens": "Ex: Frango grelhado, arroz e feijão", "calorias": 650},
        {"refeicao": "Café da Tarde", "itens": "Ex: Vitamina de banana com aveia", "calorias": 300},
        {"refeicao": "Jantar", "itens": "Ex: Omelete de forno com legumes", "calorias": 500}
      ]
    ''';

    final conteudo = [Content.text(prompt)];

    // Mecanismo de Fallback
    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando 1.5-flash...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }
}