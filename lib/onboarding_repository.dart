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

  // Método auxiliar para buscar o histórico recente de treinos do usuário no Supabase
  Future<List<Map<String, dynamic>>> _buscarHistoricoRecente(
    int usuarioId,
  ) async {
    try {
      final resposta = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', usuarioId)
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(resposta);
    } catch (e) {
      // Retorna vazio caso a tabela ainda esteja vazia ou com outro nome de coluna
      return [];
    }
  }

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

    // Busca o histórico recente para que a IA conheça o que foi treinado nos dias anteriores
    final historicoRecente = await _buscarHistoricoRecente(usuarioId);

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
        historicoRecente: historicoRecente,
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
          historicoRecente: historicoRecente,
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
          'analise_nutricional':
              'Diretrizes alimentares ajustadas por segurança.',
          'analise_treino': 'Perfil avaliado pelo sistema de segurança. Foco em progressão segura na calistenia respeitando sua estrutura.',
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
    required List<Map<String, dynamic>> historicoRecente,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        '''
    Atue como um personal trainer e nutricionista de elite especialista em calistenia pura (Street Workout e treinamento estritamente com o peso corporal, sem pesos livres ou aparelhos de academia).
    
    Contexto do usuário:
    - Histórico recente de treinos executados: $historicoRecente
    - Peso: $peso kg, Altura: $altura cm, Idade: $idade anos, Sexo: $sexo
    - Objetivo: $objetivo, Experiência: $experiencia (Iniciante, Intermediário ou Avançado)
    - Consome carne: $consomeCarne
    - Lesão lombar: $lesaoLombar | Lesão ombro: $lesaoOmbro

    DIRETRIZES INTELIGENTES:
    - Analise o histórico recente fornecido para garantir variação de estímulos para hoje (evite repetições excessivas do mesmo grupo muscular treinado nos dias anteriores).
    - Os exercícios DEVEM utilizar APENAS o peso corporal (ex: flexões, pranchas, agachamentos livres, barras, etc.). NUNCA sugira halteres, anilhas ou máquinas.
    - Adapte rigorosamente a dieta e o treino de acordo com a restrição de carne e com as lesões informadas.

    Retorne obrigatoriamente um objeto JSON estruturado exatamente com as chaves:
    - "calorias_alvo": int,
    - "proteinas_g_alvo": int,
    - "carboidratos_g_alvo": int,
    - "gorduras_g_alvo": int,
    - "analise_nutricional": "Diretrizes alimentares detalhadas para hoje...",
    - "analise_treino": "Diretrizes de calistenia corporal e biomecânica para hoje...",
    - "treino_sugerido_nome": "Nome do Treino (ex: Calistenia Bodyweight - Push)",
    - "treino_descricao": "Descrição focada em controle corporal",
    - "exercicios": [
        {
          "nome": "Flexão Tradicional com Joelhos Apoiados",
          "series": "3",
          "repeticoes": "10 a 12",
          "instrucoes": "Mantenha o corpo alinhado, desça controlando o tronco usando apenas o peso do corpo."
        }
      ]
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) throw Exception('Resposta vazia da IA');
    return jsonDecode(response.text!);
  }
}
