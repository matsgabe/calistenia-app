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

  // Verifica se o treino já foi concluído hoje
  Future<bool> verificarTreinoConcluidoHoje(int usuarioId) async {
    try {
      final hoje = DateTime.now();
      final response = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', usuarioId);

      for (var item in response) {
        final dataRegistro = item['data_registro'] ?? item['created_at'];
        if (dataRegistro != null) {
          final dataTreino = DateTime.parse(dataRegistro.toString());
          if (dataTreino.year == hoje.year &&
              dataTreino.month == hoje.month &&
              dataTreino.day == hoje.day) {
            return true; // Encontrou um treino concluído hoje!
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar treino hoje: $e');
      return false;
    }
  }

  // Registra a conclusão do treino de calistenia do dia usando o timestamp automático
  Future<void> registrarTreinoConcluido(int usuarioId) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];

    await _supabase.from('historico_fisico').insert({
      'usuario_id': usuarioId,
      'data_registro': hoje,
      'peso_kg': 70.0,
      'objetivo': 'Hipertrofia',
      'nivel_atividade': 'Moderado',
    });
  }

  // Busca o histórico recente de treinos do usuário para análise da IA
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

  // Realiza o login do usuário
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

  // Verifica se o username já existe no cadastro
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

    if (genero != null) {
      dadosInsercao['genero'] = genero;
    }

    if (dataNascimento != null) {
      dadosInsercao['data_nascimento'] = dataNascimento.toIso8601String().split(
        'T',
      )[0];
    }

    if (alturaCm != null) {
      dadosInsercao['altura_cm'] = alturaCm;
    }

    final response = await _supabase
        .from('usuarios')
        .insert(dadosInsercao)
        .select('id')
        .single();

    return response['id'] as int;
  }

  // Salva as métricas físicas do usuário
  Future<void> registrarMetricas({
    required int usuarioId,
    required double peso,
    required double altura,
  }) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];

    await _supabase.from('historico_fisico').insert({
      'usuario_id': usuarioId,
      'peso': peso,
      'altura': altura,
      'data_registro': hoje, // Garante que a data seja preenchida aqui também
    });
  }

  // Grava o plano alimentar inicial/atualizado
  Future<void> gravarPlanoAlimentar({
    required int usuarioId,
    required int calorias,
    required int proteinas,
    required int carboidratos,
    required int gorduras,
  }) async {
    // Desativa planos anteriores
    await _supabase
        .from('plano_alimentar')
        .update({'ativo': false})
        .eq('usuario_id', usuarioId);

    // Insere o novo plano ativo
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
