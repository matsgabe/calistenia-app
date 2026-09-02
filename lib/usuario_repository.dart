import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fazerLogin(
    String username,
    String senha,
  ) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('username', username)
        .eq('senha', senha)
        .maybeSingle();
    return response;
  }

  Future<bool> verificarUsernameExiste(String username) async {
    final response = await _supabase
        .from('usuarios')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return response != null;
  }

  Future<int> cadastrarUsuario({
    required String username,
    required String senha,
    required String nome,
    required String genero,
    required DateTime dataNascimento,
    required int alturaCm,
  }) async {
    final response = await _supabase
        .from('usuarios')
        .insert({
          'username': username,
          'senha': senha,
          'nome': nome,
          'genero': genero,
          'data_nascimento': dataNascimento.toIso8601String().split('T')[0],
          'altura_cm': alturaCm,
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  Future<void> registrarMetricas({
    required int usuarioId,
    required double pesoKg,
    required String objetivo,
    required String nivelAtividade,
  }) async {
    await _supabase.from('historico_fisico').insert({
      'usuario_id': usuarioId,
      'data_registro': DateTime.now().toIso8601String().split('T')[0],
      'peso_kg': pesoKg,
      'objetivo': objetivo,
      'nivel_atividade': nivelAtividade,
    });
  }

  Future<Map<String, dynamic>> buscarUsuario(int id) async {
    return await _supabase.from('usuarios').select().eq('id', id).single();
  }

  Future<void> gravarPlanoAlimentar({
    required int usuarioId,
    required int caloriasAlvo,
    required int proteinasG,
    required int carboidratosG,
    required int gordurasG,
  }) async {
    await _supabase.from('plano_alimentar').insert({
      'usuario_id': usuarioId,
      'data_inicio': DateTime.now().toIso8601String().split('T')[0],
      'calorias_alvo': caloriasAlvo,
      'proteinas_g_alvo': proteinasG,
      'carboidratos_g_alvo': carboidratosG,
      'gorduras_g_alvo': gordurasG,
      'ativo': true,
    });
  }

  Future<Map<String, dynamic>?> buscarPlanoAtivo(int usuarioId) async {
    final response = await _supabase
        .from('plano_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  Future<bool> verificarTreinoConcluidoHoje(int usuarioId) async {
    final response = await _supabase
        .from('treinos_realizados')
        .select('data_realizacao')
        .eq('usuario_id', usuarioId)
        .order('data_realizacao', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return false;

    final dataTreino = DateTime.parse(response['data_realizacao']).toLocal();
    final hoje = DateTime.now();

    return dataTreino.year == hoje.year &&
        dataTreino.month == hoje.month &&
        dataTreino.day == hoje.day;
  }

  Future<void> registrarTreinoConcluido(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];

    await _supabase.from('historico_treinos').insert({
      'usuario_id': usuarioId,
      'data_conclusao': hoje,
      'concluido': true,
    });
  }
}
