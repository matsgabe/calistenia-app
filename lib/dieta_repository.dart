import 'package:supabase_flutter/supabase_flutter.dart';

class DietaRepository {
  final _supabase = Supabase.instance.client;

  // Busca os totais consumidos hoje (já devia existir, mas garantindo a estrutura)
  Future<Map<String, int>> buscarTotaisDiarios(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('consumo_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('data_registro', hoje);

    int kcal = 0, prot = 0, carb = 0, gord = 0;
    for (var item in response) {
      kcal += (item['calorias'] as num?)?.toInt() ?? 0;
      prot += (item['proteinas_g'] as num?)?.toInt() ?? 0;
      carb += (item['carboidratos_g'] as num?)?.toInt() ?? 0;
      gord += (item['gorduras_g'] as num?)?.toInt() ?? 0;
    }
    return {
      'calorias': kcal,
      'proteinas': prot,
      'carboidratos': carb,
      'gorduras': gord,
    };
  }

  // NOVO: Busca a lista de refeições de hoje para exibir na tela
  Future<List<Map<String, dynamic>>> buscarRefeicoesDoDia(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('consumo_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('data_registro', hoje)
        .order('created_at', ascending: false); // Mais recentes primeiro
    return List<Map<String, dynamic>>.from(response);
  }

  // NOVO: Registra uma nova refeição no banco
  Future<void> registrarRefeicao({
    required int usuarioId,
    required String descricao,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    await _supabase.from('consumo_alimentar').insert({
      'usuario_id': usuarioId,
      'data_registro': hoje,
      'descricao': descricao,
      'calorias': calorias,
      'proteinas_g': proteinas,
      'carboidratos_g': carboidratos,
      'gorduras_g': gorduras,
    });
  }
}
