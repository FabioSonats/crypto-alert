import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/crypto_price.dart';
import '../utils/config.dart';

/// Serviço para buscar preços de criptomoedas na API CoinGecko
///
/// Suporta múltiplas moedas: Bitcoin, Ethereum e XRP
class CryptoService {
  final http.Client _client;

  // Cache da taxa USD/BRL para evitar requisições extras
  double? _cachedUsdToBrl;
  DateTime? _cacheTime;

  CryptoService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca o preço atual de todas as moedas configuradas
  Future<List<CryptoPrice>> fetchAllPrices() async {
    try {
      final coinIds = Config.supportedCoins.join(',');
      final currencies = Config.supportedCurrencies.join(',');

      final uri = Uri.parse(
        '${Config.coinGeckoBaseUrl}/simple/price'
        '?ids=$coinIds'
        '&vs_currencies=$currencies'
        '&include_24hr_change=true',
      );

      debugPrint('Buscando preços: $uri');

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: Config.requestTimeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('Preços recebidos: ${jsonData.keys.toList()}');
        return _parsePrices(jsonData);
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit excedido. Aguarde alguns segundos.');
      } else {
        throw Exception('Erro ao buscar preços: Status ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
          'Timeout: Requisição demorou mais de ${Config.requestTimeout} segundos');
    } catch (e) {
      throw Exception('Erro ao buscar preços: $e');
    }
  }

  /// Busca o histórico de preços de uma moeda para o gráfico
  Future<List<PricePoint>> fetchPriceHistory(String coinId) async {
    try {
      final uri = Uri.parse(
        '${Config.coinGeckoBaseUrl}/coins/$coinId/market_chart'
        '?vs_currency=usd'
        '&days=${Config.chartHistoryDays}',
      );

      debugPrint('Buscando histórico de $coinId: $uri');

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: Config.requestTimeout));

      debugPrint('Resposta histórico $coinId: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final prices = jsonData['prices'] as List<dynamic>?;

        if (prices == null || prices.isEmpty) {
          debugPrint('Histórico vazio para $coinId');
          return [];
        }

        debugPrint('Histórico $coinId: ${prices.length} pontos');

        // Pega a taxa USD/BRL (com cache)
        final usdToBrl = await _getUsdToBrlRate();

        // Reduz a quantidade de pontos para performance
        final step = (prices.length / 50).ceil();
        final reducedPrices = <PricePoint>[];

        for (int i = 0; i < prices.length; i += step) {
          try {
            reducedPrices.add(
              PricePoint.fromJson(prices[i] as List<dynamic>, usdToBrl),
            );
          } catch (e) {
            // Ignora pontos com erro
          }
        }

        // Sempre inclui o último ponto
        if (prices.isNotEmpty) {
          try {
            reducedPrices.add(
              PricePoint.fromJson(prices.last as List<dynamic>, usdToBrl),
            );
          } catch (e) {
            // Ignora
          }
        }

        return reducedPrices;
      } else if (response.statusCode == 429) {
        debugPrint('Rate limit para histórico de $coinId');
        return [];
      } else {
        debugPrint('Erro histórico $coinId: ${response.statusCode}');
        return [];
      }
    } on TimeoutException {
      debugPrint('Timeout histórico $coinId');
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar histórico de $coinId: $e');
      return [];
    }
  }

  /// Busca histórico de todas as moedas
  Future<Map<String, List<PricePoint>>> fetchAllPriceHistories() async {
    final histories = <String, List<PricePoint>>{};

    for (final coinId in Config.supportedCoins) {
      try {
        debugPrint('Buscando histórico de $coinId...');
        final history = await fetchPriceHistory(coinId);
        histories[coinId] = history;
        debugPrint('Histórico $coinId: ${history.length} pontos');

        // Delay maior para evitar rate limit
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Erro no histórico de $coinId: $e');
        histories[coinId] = [];
      }
    }

    return histories;
  }

  /// Obtém a taxa de câmbio USD para BRL (com cache)
  Future<double> _getUsdToBrlRate() async {
    // Usa cache se disponível e recente (menos de 5 minutos)
    if (_cachedUsdToBrl != null && _cacheTime != null) {
      final diff = DateTime.now().difference(_cacheTime!);
      if (diff.inMinutes < 5) {
        return _cachedUsdToBrl!;
      }
    }

    try {
      final btcUri = Uri.parse(
        '${Config.coinGeckoBaseUrl}/simple/price'
        '?ids=bitcoin'
        '&vs_currencies=usd,brl',
      );

      final btcResponse =
          await _client.get(btcUri).timeout(const Duration(seconds: 5));

      if (btcResponse.statusCode == 200) {
        final data = json.decode(btcResponse.body) as Map<String, dynamic>;
        final btcData = data['bitcoin'] as Map<String, dynamic>;
        final usd = (btcData['usd'] as num).toDouble();
        final brl = (btcData['brl'] as num).toDouble();

        _cachedUsdToBrl = brl / usd;
        _cacheTime = DateTime.now();

        return _cachedUsdToBrl!;
      }

      return _cachedUsdToBrl ?? 6.0; // Fallback
    } catch (e) {
      return _cachedUsdToBrl ?? 6.0; // Fallback
    }
  }

  /// Parseia os preços do JSON
  List<CryptoPrice> _parsePrices(Map<String, dynamic> json) {
    final prices = <CryptoPrice>[];
    final now = DateTime.now();

    for (final coinId in Config.supportedCoins) {
      if (json.containsKey(coinId)) {
        final coinData = json[coinId] as Map<String, dynamic>;
        prices.add(CryptoPrice(
          coinId: coinId,
          priceUsd: (coinData['usd'] as num).toDouble(),
          priceBrl: (coinData['brl'] as num).toDouble(),
          lastUpdate: now,
        ));
      } else {
        debugPrint('Moeda não encontrada: $coinId');
      }
    }

    return prices;
  }

  void dispose() {
    _client.close();
  }
}
