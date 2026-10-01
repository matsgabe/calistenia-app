import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'usuario_repository.dart';
import 'dieta_repository.dart';

class CalendarioScreen extends StatefulWidget {
  final int usuarioId;

  const CalendarioScreen({super.key, required this.usuarioId});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final _usuarioRepository = UsuarioRepository();
  final _dietaRepository = DietaRepository();

  DateTime _diaSelecionado = DateTime.now();
  DateTime _diaFoco = DateTime.now();

  bool _isLoading = false;
  Map<String, dynamic>? _planoDoDia;
  List<Map<String, dynamic>> _refeicoesConsumidas = [];
  Map<String, int> _totaisConsumidos = {
    'calorias': 0,
    'proteinas': 0,
    'carboidratos': 0,
    'gorduras': 0,
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosDoDia(_diaSelecionado);
  }

  Future<void> _carregarDadosDoDia(DateTime data) async {
    setState(() => _isLoading = true);

    final dataIso = data.toIso8601String().split('T')[0];

    // 1. Busca o plano da IA do dia (para ver a meta/calorias alvo, se houver)
    final plano = await _usuarioRepository.buscarPlanoPorData(
      widget.usuarioId,
      dataIso,
    );

    // 2. Busca o que o usuário realmente consumiu/registrou nesta data específica
    final consumidos = await _dietaRepository.buscarRefeicoesPorData(
      widget.usuarioId,
      dataIso,
    );

    // 3. Calcula os totais reais consumidos no dia
    int totalKcal = 0;
    int totalProt = 0;
    int totalCarb = 0;
    int totalGord = 0;

    for (var item in consumidos) {
      totalKcal += (item['calorias'] as num?)?.toInt() ?? 0;
      totalProt += (item['proteinas_g'] as num?)?.toInt() ?? 0;
      totalCarb += (item['carboidratos_g'] as num?)?.toInt() ?? 0;
      totalGord += (item['gorduras_g'] as num?)?.toInt() ?? 0;
    }

    setState(() {
      _planoDoDia = plano;
      _refeicoesConsumidas = consumidos;
      _totaisConsumidos = {
        'calorias': totalKcal,
        'proteinas': totalProt,
        'carboidratos': totalCarb,
        'gorduras': totalGord,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico e Calendário'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _diaFoco,
                currentDay: _diaSelecionado,
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.grey),
                ),
                selectedDayPredicate: (day) => isSameDay(_diaSelecionado, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _diaSelecionado = selectedDay;
                    _diaFoco = focusedDay;
                  });
                  _carregarDadosDoDia(selectedDay);
                },
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Registro de ${_diaSelecionado.day.toString().padLeft(2, '0')}/${_diaSelecionado.month.toString().padLeft(2, '0')}/${_diaSelecionado.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- CALORIAS CONSUMIDAS VS META ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calorias Consumidas:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '${_totaisConsumidos['calorias']} / ${_planoDoDia?['calorias_alvo'] ?? 2000} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 20),

                        // --- MACROS TOTAIS DO DIA CORRIGIDOS (EM COLUNA OU WRAP) ---
                        const Text(
                          'Macros Totais do Dia:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prot: ${_totaisConsumidos['proteinas']}g',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'Carb: ${_totaisConsumidos['carboidratos']}g',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'Gord: ${_totaisConsumidos['gorduras']}g',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),

                        const Divider(color: Colors.white12, height: 20),
                        const Text(
                          'O que foi consumido (Refeições):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _refeicoesConsumidas.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Nenhum alimento registrado nesta data.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _refeicoesConsumidas.length,
                                itemBuilder: (context, index) {
                                  final item = _refeicoesConsumidas[index];

                                  // Tenta buscar o nome do alimento considerando todas as variações possíveis de colunas
                                  final nomeAlimento = item['nome_refeicao'] ?? 'Refeição Registrada';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nomeAlimento,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'P: ${item['proteinas_g'] ?? 0}g | C: ${item['carboidratos_g'] ?? 0}g | G: ${item['gorduras_g'] ?? 0}g',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item['calorias'] ?? 0} kcal',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
