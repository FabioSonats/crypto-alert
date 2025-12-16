import 'package:intl/intl.dart';

/// Modelo de dados para representar o preço do Bitcoin
/// 
/// Contém preços em USD e BRL, data da última atualização
/// e preço anterior para cálculo de variação percentual
class BitcoinPrice {
  /// Preço em dólares americanos
  final double priceUsd;
  
  /// Preço em reais brasileiros
  final double priceBrl;
  
  /// Data e hora da última atualização
  final DateTime lastUpdate;
  
  /// Preço anterior para cálculo de variação (opcional)
  final double? previousPrice;
  
  /// Construtor da classe BitcoinPrice
  BitcoinPrice({
    required this.priceUsd,
    required this.priceBrl,
    required this.lastUpdate,
    this.previousPrice,
  });
  
  /// Calcula a variação percentual em relação ao preço anterior
  double? get variationPercentage {
    if (previousPrice == null || previousPrice == 0) {
      return null;
    }
    return ((priceBrl - previousPrice!) / previousPrice!) * 100;
  }
  
  /// Cria uma instância de BitcoinPrice a partir de um JSON
  factory BitcoinPrice.fromJson(Map<String, dynamic> json) {
    final bitcoinData = json['bitcoin'] as Map<String, dynamic>;
    return BitcoinPrice(
      priceUsd: (bitcoinData['usd'] as num).toDouble(),
      priceBrl: (bitcoinData['brl'] as num).toDouble(),
      lastUpdate: DateTime.now(),
    );
  }
  
  /// Cria uma cópia da instância com campos opcionais atualizados
  BitcoinPrice copyWith({
    double? priceUsd,
    double? priceBrl,
    DateTime? lastUpdate,
    double? previousPrice,
  }) {
    return BitcoinPrice(
      priceUsd: priceUsd ?? this.priceUsd,
      priceBrl: priceBrl ?? this.priceBrl,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      previousPrice: previousPrice ?? this.previousPrice,
    );
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
}

