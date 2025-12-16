import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/crypto_price.dart';
import '../services/crypto_service.dart';
import '../utils/config.dart';

/// Controller para gerenciar o estado de múltiplas criptomoedas
class CryptoController extends ChangeNotifier {
  final CryptoService _cryptoService;
  Timer? _updateTimer;
  Timer? _historyRetryTimer;

  List<CryptoPrice> _prices = [];
  Map<String, List<PricePoint>> _priceHistories = {};
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  // Controle de retry para históricos que falharam
  final Set<String> _failedHistories = {};

  CryptoController({CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// Lista de preços das criptomoedas
  List<CryptoPrice> get prices => _prices;

  /// Histórico de preços por moeda
  Map<String, List<PricePoint>> get priceHistories => _priceHistories;

  /// Se está carregando preços
  bool get isLoading => _isLoading;

  /// Se está carregando histórico
  bool get isLoadingHistory => _isLoadingHistory;

  /// Mensagem de erro (se houver)
  String? get errorMessage => _errorMessage;

  /// Retorna o preço de uma moeda específica
  CryptoPrice? getPriceFor(String coinId) {
    try {
      return _prices.firstWhere((p) => p.coinId == coinId);
    } catch (e) {
      return null;
    }
  }

  /// Retorna o histórico de uma moeda específica
  List<PricePoint> getHistoryFor(String coinId) {
    return _priceHistories[coinId] ?? [];
  }

  /// Atualiza os preços de todas as moedas
  Future<void> updatePrices() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final previousPrices = Map.fromEntries(
        _prices.map((p) => MapEntry(p.coinId, p)),
      );

      final newPrices = await _cryptoService.fetchAllPrices();

      // Adiciona preço anterior para cálculo de variação
      _prices = newPrices.map((price) {
        final previous = previousPrices[price.coinId];
        return price.copyWith(
          previousPriceBrl: previous?.priceBrl,
          previousPriceUsd: previous?.priceUsd,
          priceHistory: _priceHistories[price.coinId],
        );
      }).toList();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Erro ao atualizar preços: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega o histórico de preços para gráficos
  Future<void> loadPriceHistories() async {
    if (_isLoadingHistory) return;

    _isLoadingHistory = true;
    _failedHistories.clear();
    notifyListeners();

    try {
      _priceHistories = await _cryptoService.fetchAllPriceHistories();

      // Verifica quais falharam
      for (final coinId in Config.supportedCoins) {
        if (_priceHistories[coinId]?.isEmpty ?? true) {
          _failedHistories.add(coinId);
          debugPrint('Histórico vazio para $coinId, tentará novamente...');
        }
      }

      // Atualiza os preços com o histórico
      _prices = _prices.map((price) {
        return price.copyWith(
          priceHistory: _priceHistories[price.coinId],
        );
      }).toList();

      // Se algum falhou, agenda retry
      if (_failedHistories.isNotEmpty) {
        _scheduleHistoryRetry();
      }
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Agenda retry para históricos que falharam
  void _scheduleHistoryRetry() {
    _historyRetryTimer?.cancel();
    _historyRetryTimer = Timer(const Duration(seconds: 5), () {
      _retryFailedHistories();
    });
  }

  /// Tenta carregar novamente os históricos que falharam
  Future<void> _retryFailedHistories() async {
    if (_failedHistories.isEmpty) return;

    debugPrint('Tentando recarregar históricos: $_failedHistories');

    for (final coinId in _failedHistories.toList()) {
      try {
        final history = await _cryptoService.fetchPriceHistory(coinId);
        if (history.isNotEmpty) {
          _priceHistories[coinId] = history;
          _failedHistories.remove(coinId);
          debugPrint('Histórico de $coinId carregado com sucesso!');

          // Atualiza o preço com o novo histórico
          _prices = _prices.map((price) {
            if (price.coinId == coinId) {
              return price.copyWith(priceHistory: history);
            }
            return price;
          }).toList();

          notifyListeners();
        }
        // Delay entre requisições
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        debugPrint('Retry falhou para $coinId: $e');
      }
    }

    // Se ainda tem falhas, agenda outro retry
    if (_failedHistories.isNotEmpty) {
      _scheduleHistoryRetry();
    }
  }

  /// Recarrega o histórico de uma moeda específica
  Future<void> reloadHistoryFor(String coinId) async {
    try {
      debugPrint('Recarregando histórico de $coinId...');
      final history = await _cryptoService.fetchPriceHistory(coinId);

      if (history.isNotEmpty) {
        _priceHistories[coinId] = history;
        _failedHistories.remove(coinId);

        _prices = _prices.map((price) {
          if (price.coinId == coinId) {
            return price.copyWith(priceHistory: history);
          }
          return price;
        }).toList();

        notifyListeners();
        debugPrint('Histórico de $coinId recarregado!');
      }
    } catch (e) {
      debugPrint('Erro ao recarregar histórico de $coinId: $e');
    }
  }

  /// Atualização manual
  Future<void> manualUpdate() async {
    await updatePrices();

    // Também tenta recarregar históricos que falharam
    if (_failedHistories.isNotEmpty) {
      _retryFailedHistories();
    }
  }

  /// Inicia a atualização automática
  void startAutoUpdate() {
    stopAutoUpdate();
    _updateTimer = Timer.periodic(
      Duration(seconds: Config.defaultUpdateInterval),
      (_) => updatePrices(),
    );
    // Carrega dados iniciais
    updatePrices();
    loadPriceHistories();
  }

  /// Para a atualização automática
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _historyRetryTimer?.cancel();
    _historyRetryTimer = null;
  }

  @override
  void dispose() {
    stopAutoUpdate();
    _cryptoService.dispose();
    super.dispose();
  }
}
