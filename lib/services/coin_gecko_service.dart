import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bitcoin_price.dart';
import '../utils/config.dart';

/// Serviço para buscar preços do Bitcoin na API CoinGecko
class CoinGeckoService {
  final http.Client _client;

  CoinGeckoService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca o preço atual do Bitcoin
  Future<BitcoinPrice> fetchPrice() async {
    try {
      final uri = Uri.parse(
        '${Config.coinGeckoBaseUrl}/simple/price'
        '?ids=bitcoin'
        '&vs_currencies=${Config.supportedCurrencies.join(',')}',
      );

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: Config.requestTimeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return BitcoinPrice.fromJson(jsonData);
      } else {
        throw Exception('Erro ao buscar preço: Status ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
          'Timeout: Requisição demorou mais de ${Config.requestTimeout} segundos');
    } catch (e) {
      throw Exception('Erro ao buscar preço: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
