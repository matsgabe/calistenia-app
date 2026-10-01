import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> buscarUsuario(int usuarioId) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> buscarPlanoAtivo(int usuarioId) async {
    final response = await _supabase
        .from('plano_alimentar')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .maybeSingle();
    return response;
  }

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

  Future<void> registrarTreinoConcluido(int usuarioId) async {
    final agora = DateTime.now().toIso8601String();
    await _supabase.from('treinos_realizados').insert({
      'usuario_id': usuarioId,
      'tipo_treino': 'Calistenia IA',
      'duracao_segundos': 1800,
      'data_realizacao': agora,
    });
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoRecente(
    int usuarioId,
  ) async {
    try {
      final response = await _supabase
          .from('historico_fisico')
          .select()
          .eq('usuario_id', usuarioId)
          .order(
            'id',
            ascending: false,
          )
          .limit(1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar histórico recente: $e');
      return [];
    }
  }

  Future<bool> verificarUsernameExiste(String username) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('username', username)
        .maybeSingle();
    return response != null;
  }

  // --- MÉTODOS DE AUTENTICAÇÃO ATUALIZADOS (O "HACK" DO E-MAIL) ---

  Future<Map<String, dynamic>?> fazerLogin(
    String username,
    String senha,
  ) async {
    try {
      // 1. Faz o login no sistema blindado do Supabase Auth criando um e-mail falso
      final emailFake = '$username@calistenia.app';
      await _supabase.auth.signInWithPassword(
        email: emailFake,
        password: senha,
      );

      // 2. Se a senha estiver correta, busca os dados na nossa tabela pública
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('username', username)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Erro no login oficial: $e');
      return null; // Retorna nulo se a senha estiver errada
    }
  }

  Future<int> cadastrarUsuario({
    required String nome,
    required String username,
    required String senha,
    String? genero,
    DateTime? dataNascimento,
    double? alturaCm,
  }) async {
    // 1. Cria a credencial blindada no Supabase Auth
    final emailFake = '$username@calistenia.app';
    await _supabase.auth.signUp(email: emailFake, password: senha);

    // 2. Salva os dados do perfil na nossa tabela 'usuarios'.
    // NOTA: Não precisamos mais salvar a 'senha' na nossa tabela pública!
    final Map<String, dynamic> dadosInsercao = {
      'nome': nome,
      'username': username,
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

  Future<void> redefinirSenha(String username, String novaSenha) async {
    throw Exception(
      'No modo atual, a redefinição de senha deve ser feita diretamente no painel do Supabase pelo Administrador.',
    );
  }

  // --- FIM DOS MÉTODOS DE AUTENTICAÇÃO ---

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

  Future<void> gravarPlanoDiario({
    required int usuarioId,
    required Map<String, dynamic> dadosIA,
  }) async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    await _supabase
        .from('plano_alimentar')
        .update({'ativo': false})
        .eq('usuario_id', usuarioId);
    await _supabase.from('plano_alimentar').insert({
      'usuario_id': usuarioId,
      'calorias_alvo': dadosIA['calorias_alvo'] ?? 2000,
      'proteinas_g_alvo': dadosIA['proteinas_g_alvo'] ?? 150,
      'carboidratos_g_alvo': dadosIA['carboidratos_g_alvo'] ?? 200,
      'gorduras_g_alvo': dadosIA['gorduras_g_alvo'] ?? 60,
      'dados_ia': dadosIA,
      'data_registro': hoje,
      'ativo': true,
    });
  }

  Future<Map<String, dynamic>?> buscarPlanoPorData(
    int usuarioId,
    String dataIso,
  ) async {
    try {
      final response = await _supabase
          .from('plano_alimentar')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('data_registro', dataIso)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar plano da data $dataIso: $e');
      return null;
    }
  }

  Future<void> atualizarPerfilCompleto({
    required int usuarioId,
    required double pesoKg,
    required double alturaCm,
    required String objetivo,
    required String nivel,
  }) async {
    try {
      // 1. Atualiza a altura na tabela usuarios usando a coluna 'altura_cm'
      await _supabase
          .from('usuarios')
          .update({'altura_cm': alturaCm})
          .eq('id', usuarioId);

      // 2. Insere a nova evolução no historico_fisico (sem a coluna altura)
      await _supabase.from('historico_fisico').insert({
        'usuario_id': usuarioId,
        'peso_kg': pesoKg,
        'objetivo': objetivo,
        'nivel_atividade':
            nivel, // Nome da coluna correta na tabela historico_fisico
        'data_registro': DateTime.now().toIso8601String().split('T')[0],
      });
    } catch (e) {
      print('Erro ao atualizar perfil completo: $e');
      rethrow;
    }
  }
}
