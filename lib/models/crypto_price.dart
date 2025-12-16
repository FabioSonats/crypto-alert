import 'package:intl/intl.dart';
import '../utils/config.dart';

/// Enum para tendência de preço
enum PriceTrend {
  up, // Subindo ↑
  down, // Caindo ↓
  stable, // Estável →
}

/// Modelo de dados para representar o preço de uma criptomoeda
///
/// Suporta múltiplas moedas (BTC, ETH, XRP)
class CryptoPrice {
  /// ID da criptomoeda (ex: 'bitcoin', 'ethereum', 'ripple')
  final String coinId;

  /// Preço em dólares americanos
  final double priceUsd;

  /// Preço em reais brasileiros
  final double priceBrl;

  /// Data e hora da última atualização
  final DateTime lastUpdate;

  /// Preço anterior para cálculo de variação (opcional)
  final double? previousPriceBrl;

  /// Preço anterior em USD
  final double? previousPriceUsd;

  /// Histórico de preços para o gráfico (últimos 7 dias)
  final List<PricePoint>? priceHistory;

  /// Construtor da classe CryptoPrice
  const CryptoPrice({
    required this.coinId,
    required this.priceUsd,
    required this.priceBrl,
    required this.lastUpdate,
    this.previousPriceBrl,
    this.previousPriceUsd,
    this.priceHistory,
  });

  /// Nome da criptomoeda
  String get name => Config.coinNames[coinId] ?? coinId;

  /// Símbolo da criptomoeda
  String get symbol => Config.coinSymbols[coinId] ?? coinId.toUpperCase();

  /// Cor da criptomoeda (para UI)
  int get colorValue => Config.coinColors[coinId] ?? 0xFF2196F3;

  /// Calcula a variação percentual em relação ao preço anterior (BRL)
  double? get variationPercentageBrl {
    if (previousPriceBrl == null || previousPriceBrl == 0) {
      return null;
    }
    return ((priceBrl - previousPriceBrl!) / previousPriceBrl!) * 100;
  }

  /// Calcula a variação percentual em relação ao preço anterior (USD)
  double? get variationPercentageUsd {
    if (previousPriceUsd == null || previousPriceUsd == 0) {
      return null;
    }
    return ((priceUsd - previousPriceUsd!) / previousPriceUsd!) * 100;
  }

  /// Retorna a tendência do preço
  PriceTrend get trend {
    final variation = variationPercentageBrl;
    if (variation == null) return PriceTrend.stable;
    if (variation > 0.1) return PriceTrend.up;
    if (variation < -0.1) return PriceTrend.down;
    return PriceTrend.stable;
  }

  /// Retorna o preço formatado de acordo com a moeda especificada
  String getFormattedPrice(String currency) {
    final format = NumberFormat.currency(
      symbol: currency == 'BRL' ? 'R\$' : '\$',
      decimalDigits: 2,
      locale: currency == 'BRL' ? 'pt_BR' : 'en_US',
    );
    final price = currency == 'BRL' ? priceBrl : priceUsd;
    return format.format(price);
  }

  /// Retorna a variação formatada
  String getFormattedVariation(String currency) {
    final variation =
        currency == 'BRL' ? variationPercentageBrl : variationPercentageUsd;
    if (variation == null) return '--';
    final sign = variation >= 0 ? '+' : '';
    return '$sign${variation.toStringAsFixed(2)}%';
  }

  /// Cria uma cópia da instância com campos opcionais atualizados
  CryptoPrice copyWith({
    String? coinId,
    double? priceUsd,
    double? priceBrl,
    DateTime? lastUpdate,
    double? previousPriceBrl,
    double? previousPriceUsd,
    List<PricePoint>? priceHistory,
  }) {
    return CryptoPrice(
      coinId: coinId ?? this.coinId,
      priceUsd: priceUsd ?? this.priceUsd,
      priceBrl: priceBrl ?? this.priceBrl,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      previousPriceBrl: previousPriceBrl ?? this.previousPriceBrl,
      previousPriceUsd: previousPriceUsd ?? this.previousPriceUsd,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  @override
  String toString() => 'CryptoPrice($symbol: \$$priceUsd / R\$$priceBrl)';
}

/// Ponto de preço para o gráfico histórico
class PricePoint {
  /// Timestamp do ponto
  final DateTime timestamp;

  /// Preço em USD neste momento
  final double priceUsd;

  /// Preço em BRL neste momento
  final double priceBrl;

  const PricePoint({
    required this.timestamp,
    required this.priceUsd,
    required this.priceBrl,
  });

  factory PricePoint.fromJson(List<dynamic> json, double usdToBrl) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(json[0] as int);
    final priceUsd = (json[1] as num).toDouble();
    return PricePoint(
      timestamp: timestamp,
      priceUsd: priceUsd,
      priceBrl: priceUsd * usdToBrl,
    );
  }
}
