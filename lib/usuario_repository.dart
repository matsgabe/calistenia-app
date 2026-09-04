import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRepository {
  final _supabase = Supabase.instance.client;

  // Busca os dados do usuário logado
  Future<Map<String, dynamic>?> buscarUsuario(int usuarioId) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .single();
    return response;
  }

  // Busca o plano ativo do usuário
  Future<Map<String, dynamic>?> buscarPlanoAtivo(int usuarioId) async {
    final response = await _supabase
        .from('plano_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .maybeSingle();
    return response;
  }

  // VERIFICA TREINO: Agora aponta para a tabela correta 'treinos_realizados'
  Future<bool> verificarTreinoConcluidoHoje(int usuarioId) async {
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('treinos_realizados')
          .select('id')
          .eq('usuario_id', usuarioId)
          .gte('data_realizacao', '$hoje 00:00:00');

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar treino hoje: $e');
      return false;
    }
  }

  // REGISTRA TREINO: Agora aponta para a tabela 'treinos_realizados' ao invés de historico_fisico
  Future<void> registrarTreinoConcluido(int usuarioId) async {
    final agora = DateTime.now().toIso8601String();

    await _supabase.from('treinos_realizados').insert({
      'usuario_id': usuarioId,
      'tipo_treino': 'Calistenia IA',
      'duracao_segundos': 1800, // 30 minutos padrão
      'data_realizacao': agora,
    });
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoRecente(
    int usuarioId,
  ) async {
    try {
      final resposta = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', usuarioId)
          .limit(5);
      return List<Map<String, dynamic>>.from(resposta);
    } catch (e) {
      debugPrint('Erro ao buscar histórico recente: $e');
      return [];
    }
  }

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
        .select()
        .eq('username', username)
        .maybeSingle();
    return response != null;
  }

  Future<int> cadastrarUsuario({
    required String nome,
    required String username,
    required String senha,
    String? genero,
    DateTime? dataNascimento,
    double? alturaCm,
  }) async {
    final Map<String, dynamic> dadosInsercao = {
      'nome': nome,
      'username': username,
      'senha': senha,
    };

    if (genero != null) dadosInsercao['genero'] = genero;
    if (dataNascimento != null) {
      dadosInsercao['data_nascimento'] = dataNascimento.toIso8601String().split(
        'T',
      )[0];
    }
    if (alturaCm != null) dadosInsercao['altura_cm'] = alturaCm;

    final response = await _supabase
        .from('usuarios')
        .insert(dadosInsercao)
        .select('id')
        .single();

    return response['id'] as int;
  }

  Future<void> registrarMetricas({
    required int usuarioId,
    required double peso,
    required double altura,
  }) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    await _supabase.from('historico_fisico').insert({
      'usuario_id': usuarioId,
      'peso_kg': peso,
      'data_registro': hoje,
    });
  }

  Future<void> gravarPlanoAlimentar({
    required int usuarioId,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    await _supabase
        .from('plano_alimentar')
        .update({'ativo': false})
        .eq('usuario_id', usuarioId);

    await _supabase.from('plano_alimentar').insert({
      'usuario_id': usuarioId,
      'calorias_alvo': calorias,
      'proteinas_g_alvo': proteinas,
      'carboidratos_g_alvo': carboidratos,
      'gorduras_g_alvo': gorduras,
      'ativo': true,
    });
  }
}
