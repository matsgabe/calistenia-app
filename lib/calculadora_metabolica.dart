class PlanoAlimentarDTO {
  final int caloriasAlvo;
  final int proteinasG;
  final int gordurasG;
  final int carboidratosG;
  final int tmbCalculada;

  PlanoAlimentarDTO({
    required this.caloriasAlvo,
    required this.proteinasG,
    required this.gordurasG,
    required this.carboidratosG,
    required this.tmbCalculada,
  });
}

class CalculadoraMetabolica {
  static PlanoAlimentarDTO calcularPlano({
    required double pesoKg,
    required int alturaCm,
    required int idadeAnos,
    required String genero,
    required String nivelAtividade,
    required String objetivo,
  }) {
    double tmb = (10 * pesoKg) + (6.25 * alturaCm) - (5 * idadeAnos);
    tmb += (genero == 'M') ? 5 : -161;

    final multiplicadores = {
      'Sedentario': 1.2,
      'Leve': 1.375,
      'Moderado': 1.55,
      'Intenso': 1.725,
    };

    double gastoTotal = tmb * (multiplicadores[nivelAtividade] ?? 1.2);

    int caloriasAlvo = gastoTotal.round();
    if (objetivo == 'Perder Peso') {
      caloriasAlvo -= 500;
    } else if (objetivo == 'Hipertrofia') {
      caloriasAlvo += 300;
    }

    int proteinas = (pesoKg * 2.2).round();
    int gorduras = (pesoKg * 1.0).round();

    int caloriasRestantes = caloriasAlvo - ((proteinas * 4) + (gorduras * 9));
    int carboidratos = (caloriasRestantes / 4).round();

    if (carboidratos < 0) carboidratos = 0;

    return PlanoAlimentarDTO(
      caloriasAlvo: caloriasAlvo,
      proteinasG: proteinas,
      gordurasG: gorduras,
      carboidratosG: carboidratos,
      tmbCalculada: tmb.round(),
    );
  }

  static int calcularIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }
}
