import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NutricaoIAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<Map<String, dynamic>?> analisarRefeicao({
    String? descricao,
    Uint8List? imagemBytes,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Chave da API do Gemini não encontrada no arquivo .env.');
    }
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = '''
    Analise o alimento/refeição informado e estime os valores nutricionais totais.
    Retorne obrigatoriamente um objeto JSON com as seguintes chaves exatas:
    - "nome": um resumo curto e descritivo do prato/alimento.
    - "calorias": número inteiro com o total de calorias (kcal).
    - "proteinas": número inteiro com gramas de proteína.
    - "carboidratos": número inteiro com gramas de carboidratos.
    - "gorduras": número inteiro com gramas de gorduras.
    ''';

    final List<Part> parts = [];

    if (imagemBytes != null) {
      parts.add(DataPart('image/jpeg', imagemBytes));
    }

    if (descricao != null && descricao.isNotEmpty) {
      parts.add(TextPart(descricao));
    }

    parts.add(TextPart(prompt));

    if (parts.isEmpty) return null;

    final response = await model.generateContent([Content.multi(parts)]);

    if (response.text == null) return null;

    final dadosJson = jsonDecode(response.text!);
    return {
      'nome': dadosJson['nome'] ?? 'Refeição',
      'calorias': dadosJson['calorias'] ?? 0,
      'proteinas': dadosJson['proteinas'] ?? 0,
      'carboidratos': dadosJson['carboidratos'] ?? 0,
      'gorduras': dadosJson['gorduras'] ?? 0,
    };
  }
}
