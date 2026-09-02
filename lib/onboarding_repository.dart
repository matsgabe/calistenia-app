import 'dart:convert';

import 'app_cache.dart';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  final _supabase = Supabase.instance.client;
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _geminiBackupKey = dotenv.env['GEMINI_BACKUP_KEY'] ?? '';

  Future<Map<String, dynamic>> processarEPlanoIA({
    required int usuarioId,
    required double peso,
    required double altura,
    required int idade,
    required String sexo,
    required String objetivo,
    required String experiencia,
    required bool consomeCarne,
    required bool lesaoLombar,
    required bool lesaoOmbro,
  }) async {
    Map<String, dynamic>? dadosPlano;

    // TENTATIVA 1: Motor Principal (Gemini)
    try {
      dadosPlano = await _chamarGeminiCompleto(
        apiKey: _geminiApiKey,
        modelName: 'gemini-3.5-flash-lite',
        peso: peso,
        altura: altura,
        idade: idade,
        sexo: sexo,
        objetivo: objetivo,
        experiencia: experiencia,
        consomeCarne: consomeCarne,
        lesaoLombar: lesaoLombar,
        lesaoOmbro: lesaoOmbro,
      );
    } catch (e) {
      debugPrint(
        'IA Principal falhou: $e. Tentando IA de backup (GEMINI_BACKUP_KEY)...',
      );

      // TENTATIVA 2: IA Secundária com a Chave de Backup
      try {
        dadosPlano = await _chamarGeminiCompleto(
          apiKey: _geminiBackupKey.isNotEmpty
              ? _geminiBackupKey
              : _geminiApiKey,
          modelName: 'gemini-3.5-flash-lite',
          peso: peso,
          altura: altura,
          idade: idade,
          sexo: sexo,
          objetivo: objetivo,
          experiencia: experiencia,
          consomeCarne: consomeCarne,
          lesaoLombar: lesaoLombar,
          lesaoOmbro: lesaoOmbro,
        );
      } catch (backupError) {
        debugPrint(
          'IA de backup também falhou: $backupError. Ativando fallback matemático seguro.',
        );

        // Fallback matemático e estrutural de emergência
        dadosPlano = {
          'calorias_alvo': 2200,
          'proteinas_g_alvo': (peso * 2.0).toInt(),
          'carboidratos_g_alvo': 250,
          'gorduras_g_alvo': 70,
          'resumo_analise': 'Perfil avaliado pelo sistema de segurança. Foco em progressão segura na calistenia respeitando sua estrutura.',
          'treino_sugerido_nome': 'Fullbody Iniciante Seguro',
          'treino_descricao':
              'Série focada em fortalecimento global sem sobrecarga articular.',
          'exercicios': [
            {
              "nome": "Agachamento Livre na parede",
              "series": "3",
              "repeticoes": "12",
              "instrucoes": "Costas coladas na parede, desça controlando o movimento sem forçar a lombar.",
            },
          ],
        };
      }
    }

    // Salva o plano calórico no Supabase
    await _supabase.from('plano_alimentar').insert({
      'usuario_id': usuarioId,
      'calorias_alvo': dadosPlano['calorias_alvo'] ?? 2000,
      'proteinas_g_alvo': dadosPlano['proteinas_g_alvo'] ?? 150,
      'carboidratos_g_alvo': dadosPlano['carboidratos_g_alvo'] ?? 200,
      'gorduras_g_alvo': dadosPlano['gorduras_g_alvo'] ?? 60,
      'ativo': true,
    });

    // Salva o plano no cache
    AppCache.planoAtual = dadosPlano;

    return dadosPlano;
  }

  Future<Map<String, dynamic>> _chamarGeminiCompleto({
    required String apiKey,
    required String modelName,
    required double peso,
    required double altura,
    required int idade,
    required String sexo,
    required String objetivo,
    required String experiencia,
    required bool consomeCarne,
    required bool lesaoLombar,
    required bool lesaoOmbro,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        '''
    Atue como um nutricionista esportivo e personal trainer especialista em calistenia de elite.
    Dados do aluno:
    - Peso: $peso kg, Altura: $altura cm, Idade: $idade anos, Sexo: $sexo
    - Objetivo: $objetivo, Experiência: $experiencia
    - Consome carne: $consomeCarne
    - Lesão lombar: $lesaoLombar
    - Lesão ombro: $lesaoOmbro

    Retorne obrigatoriamente um objeto JSON estruturado exatamente com estas chaves:
    - "calorias_alvo": int,
    - "proteinas_g_alvo": int,
    - "carboidratos_g_alvo": int,
    - "gorduras_g_alvo": int,
    - "analise_nutricional": "Texto focado exclusivamente na estratégia alimentar, distribuição de macros, fontes de proteína e adaptação para consumo de carne.",
    - "analise_treino": "Texto focado na estratégia de treino, calistenia, proteções articulares para a lombar e ombros.",
    - "treino_sugerido_nome": "Nome do Treino",
    - "treino_descricao": "Breve descrição dos blocos",
    - "exercicios": [
        {
          "nome": "Nome do exercício",
          "series": "3",
          "repeticoes": "8 a 12",
          "instrucoes": "Passo a passo detalhado."
        }
      ]
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) throw Exception('Resposta vazia da IA');
    return jsonDecode(response.text!);
  }
}
