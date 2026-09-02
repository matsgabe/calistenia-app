import 'package:flutter/material.dart';
import 'usuario_repository.dart';
import 'calculadora_metabolica.dart';
import 'home_screen.dart';

class MetricasScreen extends StatefulWidget {
  final int usuarioId;
  const MetricasScreen({super.key, required this.usuarioId});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();

  String _objetivoSelecionado = 'Perder Peso';
  String _atividadeSelecionada = 'Sedentario';
  bool _isLoading = false;

  Future<void> _salvarMetricasEGerarPlano() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final repository = UsuarioRepository();
        final peso = double.parse(_pesoController.text.replaceAll(',', '.'));
        final usuarioData = await repository.buscarUsuario(widget.usuarioId);
        final dataNascimento = DateTime.parse(usuarioData['data_nascimento']);
        final idade = CalculadoraMetabolica.calcularIdade(dataNascimento);

        final plano = CalculadoraMetabolica.calcularPlano(
          pesoKg: peso,
          alturaCm: usuarioData['altura_cm'],
          idadeAnos: idade,
          genero: usuarioData['genero'],
          nivelAtividade: _atividadeSelecionada,
          objetivo: _objetivoSelecionado,
        );

        await repository.registrarMetricas(
          usuarioId: widget.usuarioId,
          pesoKg: peso,
          objetivo: _objetivoSelecionado,
          nivelAtividade: _atividadeSelecionada,
        );

        await repository.gravarPlanoAlimentar(
          usuarioId: widget.usuarioId,
          caloriasAlvo: plano.caloriasAlvo,
          proteinasG: plano.proteinasG,
          carboidratosG: plano.carboidratosG,
          gordurasG: plano.gordurasG,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(usuarioId: widget.usuarioId),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao gerar plano: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu Físico Atual')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                key: const Key('input_peso'),
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso Atual (kg)',
                  hintText: 'Ex: 80.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Informe seu peso' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('select_objetivo'),
                value: _objetivoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Objetivo Principal',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Perder Peso',
                    child: Text('Emagrecer e Definir'),
                  ),
                  DropdownMenuItem(
                    value: 'Hipertrofia',
                    child: Text('Ganhar Massa Muscular'),
                  ),
                  DropdownMenuItem(
                    value: 'Manutencao',
                    child: Text('Manter Peso (Saúde)'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _objetivoSelecionado = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('select_atividade'),
                value: _atividadeSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Nível de Atividade Diária',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Sedentario',
                    child: Text('Sedentário (Trabalha sentado)'),
                  ),
                  DropdownMenuItem(
                    value: 'Leve',
                    child: Text('Leve (Caminhadas curtas)'),
                  ),
                  DropdownMenuItem(
                    value: 'Moderado',
                    child: Text('Moderado (Treino 3-4x na semana)'),
                  ),
                  DropdownMenuItem(
                    value: 'Intenso',
                    child: Text('Intenso (Trabalho braçal ou atleta)'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _atividadeSelecionada = value!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const Key('btn_salvar_metricas'),
                onPressed: _isLoading ? null : _salvarMetricasEGerarPlano,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Gerar Plano', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
