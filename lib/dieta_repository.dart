import 'package:supabase_flutter/supabase_flutter.dart';

class DietaRepository {
  final _supabase = Supabase.instance.client;

  // Busca os totais consumidos hoje
  Future<Map<String, int>> buscarTotaisDiarios(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];

    // Busca todo o histórico e filtra no app para evitar erro de fuso horário/timestamp
    final response = await _supabase
        .from('consumo_alimentar')
        .select()
        .eq('usuario_id', usuarioId);

    int kcal = 0, prot = 0, carb = 0, gord = 0;
    for (var item in response) {
      final dataRegistro = item['data_registro']?.toString() ?? '';
      if (dataRegistro.startsWith(hoje)) {
        kcal += (item['calorias'] as num?)?.toInt() ?? 0;
        prot += (item['proteinas_g'] as num?)?.toInt() ?? 0;
        carb += (item['carboidratos_g'] as num?)?.toInt() ?? 0;
        gord += (item['gorduras_g'] as num?)?.toInt() ?? 0;
      }
    }
    return {
      'calorias': kcal,
      'proteinas': prot,
      'carboidratos': carb,
      'gorduras': gord,
    };
  }

  // Busca a lista de refeições de hoje para exibir na tela
  Future<List<Map<String, dynamic>>> buscarRefeicoesDoDia(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('consumo_alimentar')
        .select()
        .eq('usuario_id', usuarioId);

    final refeicoesHoje = <Map<String, dynamic>>[];
    for (var item in response) {
      final dataRegistro = item['data_registro']?.toString() ?? '';
      if (dataRegistro.startsWith(hoje)) {
        refeicoesHoje.add(item);
      }
    }

    // Ordena para a refeição mais recente ficar no topo da lista
    refeicoesHoje.sort((a, b) {
      final dateA = a['data_registro']?.toString() ?? '';
      final dateB = b['data_registro']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });

    return refeicoesHoje;
  }

  // Registra uma nova refeição no banco
  Future<void> registrarRefeicao({
    required int usuarioId,
    required String descricao,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    final agora = DateTime.now()
        .toIso8601String(); // Salva a data e hora exatas

    await _supabase.from('consumo_alimentar').insert({
      'usuario_id': usuarioId,
      'data_registro': agora,
      'nome_refeicao':
          descricao, // Usando a coluna original que você já tinha no banco!
      'calorias': calorias,
      'proteinas_g': proteinas,
      'carboidratos_g': carboidratos,
      'gorduras_g': gorduras,
    });
  }
}
