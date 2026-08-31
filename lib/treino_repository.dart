import 'package:supabase_flutter/supabase_flutter.dart';

class TreinoRepository {
  final _supabase = Supabase.instance.client;

  /// Salva a sessão principal de treino e retorna o ID gerado
  Future<int> salvarSessaoTreino({
    required int usuarioId,
    required String tipoTreino,
    required int duracaoSegundos,
  }) async {
    final response = await _supabase
        .from('treinos_realizados')
        .insert({
          'usuario_id': usuarioId,
          'tipo_treino': tipoTreino,
          'duracao_segundos': duracaoSegundos,
          'data_registro': DateTime.now().toIso8601String().split('T')[0],
          'status': 'Concluido',
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Salva o detalhamento de cada exercício executado na sessão
  Future<void> salvarDetalhesExercicios({
    required int treinoId,
    required List<Map<String, dynamic>> exercicios,
  }) async {
    for (var ex in exercicios) {
      // Conta quantas séries foram marcadas como true
      final concluidasList = ex['concluidas'] as List<bool>;
      final totalConcluidas = concluidasList.where((c) => c).length;

      await _supabase.from('treino_exercicios').insert({
        'treino_id': treinoId,
        'nome_exercicio': ex['nome'],
        'series_alvo': ex['series'],
        'series_concluidas': totalConcluidas,
        'feedback_esforco':
            ex['feedback'] ?? 'Ideal', // Valor padrão caso não tenha avaliado
      });
    }
  }
}
