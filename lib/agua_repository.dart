import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AguaRepository {
  final _supabase = Supabase.instance.client;

  int calcularMetaAguaMl(double pesoKg) {
    if (pesoKg <= 0) return 2500;
    return (pesoKg * 35).toInt();
  }

  // Busca o total consumido no dia atual
  Future<int> buscarConsumoHoje(int usuarioId) async {
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('consumo_agua')
          .select('quantidade_ml')
          .eq('usuario_id', usuarioId)
          .eq('data_registro', hoje)
          .maybeSingle();

      if (response != null && response['quantidade_ml'] != null) {
        return (response['quantidade_ml'] as num).toInt();
      }
      return 0;
    } catch (e) {
      print('Erro ao buscar consumo de água: $e');
      return 0;
    }
  }

  // Adiciona água ao consumo diário (ex: +250ml ou +500ml)
  Future<int> adicionarAgua({
    required int usuarioId,
    required int quantidadeAdicionarMl,
  }) async {
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];

      // Busca o registro de hoje
      final atual = await buscarConsumoHoje(usuarioId);
      final novoTotal = atual + quantidadeAdicionarMl;

      // Verifica se já existe linha para hoje
      final respExistente = await _supabase
          .from('consumo_agua')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('data_registro', hoje)
          .maybeSingle();

      if (respExistente != null) {
        // Atualiza
        await _supabase
            .from('consumo_agua')
            .update({'quantidade_ml': novoTotal})
            .eq('id', respExistente['id']);
      } else {
        // Insere
        await _supabase.from('consumo_agua').insert({
          'usuario_id': usuarioId,
          'quantidade_ml': novoTotal,
          'data_registro': hoje,
        });
      }

      return novoTotal;
    } catch (e) {
      print('Erro ao registrar água: $e');
      rethrow;
    }
  }
}
