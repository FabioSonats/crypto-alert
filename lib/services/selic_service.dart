import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

/// Serviço para buscar a taxa SELIC atual do Banco Central
///
/// Usa a API oficial do BCB: https://api.bcb.gov.br/
class SelicService {
  final http.Client _client;

  // Cache da taxa SELIC
  double? _cachedRate;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24);

  SelicService({http.Client? client}) : _client = client ?? http.Client();

  /// Retorna a taxa SELIC atual (% a.a.)
  ///
  /// Usa cache de 24h pois a SELIC não muda frequentemente
  Future<double> fetchSelicRate() async {
    // Verifica cache
    if (_cachedRate != null && _cacheTime != null) {
      final diff = DateTime.now().difference(_cacheTime!);
      if (diff < _cacheDuration) {
        debugPrint('SELIC do cache: $_cachedRate%');
        return _cachedRate!;
      }
    }

    try {
      final uri = Uri.parse(Config.bcbSelicUrl);
      debugPrint('Buscando SELIC: $uri');

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: Config.requestTimeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;

        if (jsonData.isNotEmpty) {
          // Pega o último valor (mais recente)
          final lastEntry = jsonData.last as Map<String, dynamic>;
          final valueStr = lastEntry['valor'] as String;
          final rate = double.tryParse(valueStr) ?? 0.0;

          // Atualiza cache
          _cachedRate = rate;
          _cacheTime = DateTime.now();

          debugPrint('SELIC atual: $rate%');
          return rate;
        }
      }

      debugPrint('Erro ao buscar SELIC: ${response.statusCode}');
      return _cachedRate ?? _getFallbackRate();
    } on TimeoutException {
      debugPrint('Timeout ao buscar SELIC');
      return _cachedRate ?? _getFallbackRate();
    } catch (e) {
      debugPrint('Erro ao buscar SELIC: $e');
      return _cachedRate ?? _getFallbackRate();
    }
  }

  /// Taxa de fallback caso a API falhe
  double _getFallbackRate() {
    // Taxa SELIC aproximada como fallback
    return 13.25;
  }

  /// Retorna a taxa do cache (se disponível)
  double? get cachedRate => _cachedRate;

  /// Verifica se tem cache válido
  bool get hasCachedRate {
    if (_cachedRate == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  void dispose() {
    _client.close();
  }
}
