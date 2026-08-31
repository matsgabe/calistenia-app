import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRepository {
  final _supabase = Supabase.instance.client;

  Future<int> cadastrarUsuario({
    required String nome,
    required String email,
    required String genero,
    required DateTime dataNascimento,
    required int alturaCm,
  }) async {
    final response = await _supabase
        .from('usuarios')
        .insert({
          'nome': nome,
          'email': email,
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

  Future<Map<String, dynamic>> buscarPlanoAtivo(int usuarioId) async {
    return await _supabase
        .from('plano_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .order('id', ascending: false)
        .limit(1)
        .single();
  }
}
