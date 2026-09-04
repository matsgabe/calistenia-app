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
        'Fallback ativado: gemini-3.5-flash-lite falhou ($e). Tentando gemini-3.5-flash-lite...',
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
        'Fallback ativado: 3.5-flash-lite falhou ($e). Tentando gemini-3.5-flash-lite...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }

  // --- NOVA FUNÇÃO: GERA DIETA E TREINO COM CÁLCULO EXATO ---
  static Future<Map<String, dynamic>?> gerarPlanoCompleto({
    required double peso,
    required bool consomeCarne,
    required String objetivo,
    required String nivel,
    required bool lesaoLombar,
    required bool lesaoOmbro,
    required List<Map<String, dynamic>> historicoRecente,
  }) async {
    // 1. CÁLCULO MATEMÁTICO REAL BASEADO NO USUÁRIO
    int kcalAlvo;
    final obj = objetivo.toLowerCase();

    if (obj.contains('emagrecer') || obj.contains('perder')) {
      kcalAlvo = (peso * 22).round(); // Déficit calórico
    } else if (obj.contains('hipertrofia') || obj.contains('ganhar')) {
      kcalAlvo = (peso * 28).round(); // Superávit calórico
    } else {
      kcalAlvo = (peso * 25).round(); // Manutenção
    }

    int protAlvo = (peso * 2.0).round(); // 2g/kg
    int gordAlvo = (peso * 0.8).round(); // 0.8g/kg
    int carbAlvo = ((kcalAlvo - (protAlvo * 4) - (gordAlvo * 9)) / 4)
        .round(); // Restante
    if (carbAlvo < 0) carbAlvo = 0;

    // 2. MONTAGEM DO PROMPT
    final prompt =
        '''
    Atue como um personal trainer de elite e nutricionista especialista em Calistenia.
    
    Perfil do Atleta:
    - Peso: $peso kg | Objetivo: $objetivo | Nível: $nivel
    - Consome carne: $consomeCarne
    - Dores/Lesões: Lombar ($lesaoLombar), Ombros ($lesaoOmbro).
    
    Histórico Recente de Treinos: $historicoRecente

    Crie o plano de HOJE. 
    REGRA DE EVOLUÇÃO: Analise o Histórico Recente. Se o atleta treinou nos dias anteriores, aplique SOBRECARGA PROGRESSIVA no treino de hoje (adicione repetições, troque a variação para uma mais difícil ou mude o grupo muscular para permitir descanso). 
    Os exercícios DEVEM utilizar APENAS o peso do próprio corpo.
    
    Retorne OBRIGATORIAMENTE um JSON com as chaves exatas (use os cálculos exatos fornecidos abaixo):
    {
      "calorias_alvo": $kcalAlvo,
      "proteinas_g_alvo": $protAlvo,
      "carboidratos_g_alvo": $carbAlvo,
      "gorduras_g_alvo": $gordAlvo,
      "sugestoes": [{"refeicao": "Café", "itens": "Sugira alimentos batendo as metas", "calorias": 300}],
      "treino_sugerido_nome": "Treino de Calistenia ($nivel)",
      "resumo_analise": "Análise da evolução e foco de hoje...",
      "treino_descricao": "Descrição do foco de hoje.",
      "exercicios": [
        {
          "nome": "Flexão de Braços (Push-up)",
          "series": 3,
          "repeticoes": "10 a 15",
          "instrucoes": "Mantenha o corpo em prancha reta..."
        }
      ]
    }
    ''';

    final conteudo = [Content.text(prompt)];

    try {
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    } catch (e) {
      debugPrint(
        'Fallback ativado: gemini-pro falhou ($e). Tentando 3.5-flash-lite...',
      );
      return await _chamarAPI('gemini-3.5-flash-lite', conteudo);
    }
  }
}
