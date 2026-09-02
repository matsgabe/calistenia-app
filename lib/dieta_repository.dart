import 'package:supabase_flutter/supabase_flutter.dart';

class DietaRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarRefeicoesDoDia(int usuarioId) async {
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).toIso8601String();
    final fimDoDia = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await _supabase
        .from('consumo_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .gte('data_registro', inicioDoDia)
        .lte('data_registro', fimDoDia)
        .order('data_registro', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> registrarRefeicao({
    required int usuarioId,
    required String nome,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    await _supabase.from('consumo_alimentar').insert({
      'usuario_id': usuarioId,
      'nome_refeicao': nome,
      'calorias': calorias,
      'proteinas_g': proteinas,
      'carboidratos_g': carboidratos,
      'gorduras_g': gorduras,
    });
  }

  Future<Map<String, int>> buscarTotaisDiarios(int usuarioId) async {
    final refeicoes = await buscarRefeicoesDoDia(usuarioId);

    int totalKcal = 0;
    int totalProt = 0;
    int totalCarb = 0;
    int totalGord = 0;

    for (var ref in refeicoes) {
      totalKcal += (ref['calorias'] as num? ?? 0).toInt();
      totalProt += (ref['proteinas_g'] as num? ?? 0).toInt();
      totalCarb += (ref['carboidratos_g'] as num? ?? 0).toInt();
      totalGord += (ref['gorduras_g'] as num? ?? 0).toInt();
    }

    return {
      'calorias': totalKcal,
      'proteinas': totalProt,
      'carboidratos': totalCarb,
      'gorduras': totalGord,
    };
  }

  Future<void> salvarRefeicao({
    required int usuarioId,
    required String nome,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    await _supabase.from('refeicoes').insert({
      'usuario_id': usuarioId,
      'nome': nome,
      'calorias': calorias,
      'proteinas_g': proteinas,
      'carboidratos_g': carboidratos,
      'gorduras_g': gorduras,
      'data': DateTime.now().toIso8601String().split('T')[0],
    });
  }
}
