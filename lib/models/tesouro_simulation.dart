import 'dart:math';

/// Modelo para simulação de investimento em Tesouro Direto
///
/// Calcula rendimento usando juros compostos
class TesouroSimulation {
  /// Valor inicial investido em reais
  final double valorInicial;

  /// Tempo do investimento em meses
  final int tempoMeses;

  /// Taxa de juros anual (% a.a.)
  final double taxaAnual;

  /// Dias já decorridos desde o investimento (para cálculo proporcional)
  final int diasDecorridos;

  const TesouroSimulation({
    required this.valorInicial,
    required this.tempoMeses,
    required this.taxaAnual,
    this.diasDecorridos = 0,
  });

  /// Tempo total em anos
  double get tempoAnos => tempoMeses / 12.0;

  /// Tempo decorrido em anos
  double get tempoDecorridoAnos => diasDecorridos / 365.0;

  /// Valor final após o período completo (juros compostos)
  ///
  /// Fórmula: VF = VI * (1 + taxa)^tempo
  double get valorFinal {
    if (valorInicial <= 0 || tempoMeses <= 0 || taxaAnual <= 0) {
      return valorInicial;
    }
    return valorInicial * pow(1 + taxaAnual / 100, tempoAnos);
  }

  /// Valor atual proporcional ao tempo decorrido
  double get valorAtualProporcional {
    if (valorInicial <= 0 || taxaAnual <= 0) {
      return valorInicial;
    }
    return valorInicial * pow(1 + taxaAnual / 100, tempoDecorridoAnos);
  }

  /// Ganho atual proporcional
  double get ganhoAtualProporcional => valorAtualProporcional - valorInicial;

  /// Ganho bruto em reais (valor final completo)
  double get ganhoBruto => valorFinal - valorInicial;

  /// Rentabilidade total em percentual
  double get rentabilidadeTotal {
    if (valorInicial <= 0) return 0;
    return (ganhoBruto / valorInicial) * 100;
  }

  /// Retorna valor formatado em reais
  String formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Adiciona separador de milhares
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(intPart[i]);
    }

    return 'R\$ ${buffer.toString()},$decPart';
  }

  /// Valor inicial formatado
  String get valorInicialFormatado => formatCurrency(valorInicial);

  /// Valor final formatado
  String get valorFinalFormatado => formatCurrency(valorFinal);

  /// Ganho formatado
  String get ganhoBrutoFormatado => formatCurrency(ganhoBruto);

  /// Rentabilidade formatada
  String get rentabilidadeFormatada =>
      '+${rentabilidadeTotal.toStringAsFixed(2)}%';

  /// Cria cópia com novos valores
  TesouroSimulation copyWith({
    double? valorInicial,
    int? tempoMeses,
    double? taxaAnual,
  }) {
    return TesouroSimulation(
      valorInicial: valorInicial ?? this.valorInicial,
      tempoMeses: tempoMeses ?? this.tempoMeses,
      taxaAnual: taxaAnual ?? this.taxaAnual,
    );
  }

  @override
  String toString() {
    return 'TesouroSimulation(valor: $valorInicialFormatado, '
        'tempo: $tempoMeses meses, taxa: $taxaAnual%, '
        'final: $valorFinalFormatado)';
  }
}

/// Opções de tempo pré-definidas para o dropdown
class TempoOptions {
  static const List<TempoOption> options = [
    TempoOption(meses: 6, label: '6 meses'),
    TempoOption(meses: 12, label: '1 ano'),
    TempoOption(meses: 24, label: '2 anos'),
    TempoOption(meses: 36, label: '3 anos'),
    TempoOption(meses: 60, label: '5 anos'),
    TempoOption(meses: 120, label: '10 anos'),
  ];
}

/// Representa uma opção de tempo
class TempoOption {
  final int meses;
  final String label;

  const TempoOption({required this.meses, required this.label});
}
