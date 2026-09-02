import 'dart:convert';
import 'dart:typed_data'; // <-- Import necessário para Uint8List

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutricaoIAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<Map<String, dynamic>?> analisarRefeicao({
    required String descricao,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        '''
    Atue como um nutricionista esportivo. Analise o alimento descrito: "$descricao".
    Retorne obrigatoriamente um JSON com as chaves exatas:
    - "calorias": int,
    - "proteinas_g": int,
    - "carboidratos_g": int,
    - "gorduras_g": int
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) return null;
    return jsonDecode(response.text!);
  }

  // **CORRIGIDO: Recebe e trata Uint8List diretamente**
  static Future<Map<String, dynamic>?> analisarRefeicaoPorFoto(
    Uint8List imageBytes,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

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

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes), // Agora compatível com Uint8List
      ]),
    ]);

    if (response.text == null) return null;
    return jsonDecode(response.text!);
  }

  static Future<Map<String, dynamic>?> gerarCardapioDiario({
    required double peso,
    required bool consomeCarne,
    required String objetivo,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

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

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) return null;
    return jsonDecode(response.text!);
  }
}
