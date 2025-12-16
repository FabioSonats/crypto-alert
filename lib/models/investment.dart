import 'package:intl/intl.dart';

/// Modelo para representar um investimento simulado
class Investment {
  /// ID da criptomoeda (ex: 'bitcoin', 'ethereum', 'ripple')
  final String coinId;

  /// Valor investido em BRL
  final double amountInvested;

  /// Preço da moeda no momento do "investimento"
  final double priceAtPurchase;

  /// Data do "investimento"
  final DateTime purchaseDate;

  const Investment({
    required this.coinId,
    required this.amountInvested,
    required this.priceAtPurchase,
    required this.purchaseDate,
  });

  /// Quantidade de moedas "compradas"
  double get coinsAmount => amountInvested / priceAtPurchase;

  /// Calcula o valor atual baseado no preço atual
  double currentValue(double currentPrice) => coinsAmount * currentPrice;

  /// Calcula o lucro/prejuízo absoluto
  double profitLoss(double currentPrice) =>
      currentValue(currentPrice) - amountInvested;

  /// Calcula o lucro/prejuízo percentual
  double profitLossPercentage(double currentPrice) {
    if (amountInvested == 0) return 0;
    return ((currentValue(currentPrice) - amountInvested) / amountInvested) *
        100;
  }

  /// Retorna o valor investido formatado
  String get formattedAmountInvested {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    return format.format(amountInvested);
  }

  /// Retorna o valor atual formatado
  String formattedCurrentValue(double currentPrice) {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    return format.format(currentValue(currentPrice));
  }

  /// Retorna o lucro/prejuízo formatado
  String formattedProfitLoss(double currentPrice) {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    final pl = profitLoss(currentPrice);
    final sign = pl >= 0 ? '+' : '';
    return '$sign${format.format(pl)}';
  }

  /// Retorna a porcentagem formatada
  String formattedProfitLossPercentage(double currentPrice) {
    final pl = profitLossPercentage(currentPrice);
    final sign = pl >= 0 ? '+' : '';
    return '$sign${pl.toStringAsFixed(2)}%';
  }

  /// Converte para JSON para persistência
  Map<String, dynamic> toJson() => {
        'coinId': coinId,
        'amountInvested': amountInvested,
        'priceAtPurchase': priceAtPurchase,
        'purchaseDate': purchaseDate.toIso8601String(),
      };

  /// Cria a partir de JSON
  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      coinId: json['coinId'] as String,
      amountInvested: (json['amountInvested'] as num).toDouble(),
      priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    );
  }

  /// Cria uma cópia com valores atualizados
  Investment copyWith({
    String? coinId,
    double? amountInvested,
    double? priceAtPurchase,
    DateTime? purchaseDate,
  }) {
    return Investment(
      coinId: coinId ?? this.coinId,
      amountInvested: amountInvested ?? this.amountInvested,
      priceAtPurchase: priceAtPurchase ?? this.priceAtPurchase,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  @override
  String toString() =>
      'Investment($coinId: R\$$amountInvested @ R\$$priceAtPurchase)';
}

/// Resumo do portfólio completo
class PortfolioSummary {
  final double totalInvested;
  final double totalCurrentValue;
  final List<Investment> investments;

  const PortfolioSummary({
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.investments,
  });

  /// Lucro/prejuízo total
  double get totalProfitLoss => totalCurrentValue - totalInvested;

  /// Percentual total
  double get totalProfitLossPercentage {
    if (totalInvested == 0) return 0;
    return ((totalCurrentValue - totalInvested) / totalInvested) * 100;
  }

  /// Formatado
  String get formattedTotalInvested {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    return format.format(totalInvested);
  }

  String get formattedTotalCurrentValue {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    return format.format(totalCurrentValue);
  }

  String get formattedTotalProfitLoss {
    final format = NumberFormat.currency(
      symbol: 'R\$',
      decimalDigits: 2,
      locale: 'pt_BR',
    );
    final sign = totalProfitLoss >= 0 ? '+' : '';
    return '$sign${format.format(totalProfitLoss)}';
  }

  String get formattedTotalProfitLossPercentage {
    final sign = totalProfitLossPercentage >= 0 ? '+' : '';
    return '$sign${totalProfitLossPercentage.toStringAsFixed(2)}%';
  }
}
