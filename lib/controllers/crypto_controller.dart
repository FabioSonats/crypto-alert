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
  Timer? _historyUpdateTimer;

  List<CryptoPrice> _prices = [];
  Map<String, List<PricePoint>> _priceHistories = {};
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  ChartPeriod _currentPeriod = ChartPeriod.days7;

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

  /// Período atual do gráfico
  ChartPeriod get currentPeriod => _currentPeriod;

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
      // E atualiza o último ponto do histórico com o preço atual em tempo real
      _prices = newPrices.map((price) {
        final previous = previousPrices[price.coinId];
        var history = _priceHistories[price.coinId] ?? [];
        
        // Adiciona o preço atual como último ponto do gráfico (tempo real)
        if (history.isNotEmpty) {
          final updatedHistory = List<PricePoint>.from(history);
          // Adiciona novo ponto com preço atual
          updatedHistory.add(PricePoint(
            timestamp: DateTime.now(),
            priceUsd: price.priceUsd,
            priceBrl: price.priceBrl,
          ));
          history = updatedHistory;
          _priceHistories[price.coinId] = history;
        }
        
        return price.copyWith(
          previousPriceBrl: previous?.priceBrl,
          previousPriceUsd: previous?.priceUsd,
          priceHistory: history,
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
      _priceHistories = await _cryptoService.fetchAllPriceHistories(
        days: _currentPeriod.days,
      );

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

  /// Muda o período do gráfico e recarrega o histórico
  Future<void> changePeriod(ChartPeriod period) async {
    if (_currentPeriod == period) return;
    
    _currentPeriod = period;
    notifyListeners();
    
    await loadPriceHistories();
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
        final history = await _cryptoService.fetchPriceHistory(
          coinId,
          days: _currentPeriod.days,
        );
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
      debugPrint('Recarregando histórico de $coinId (${_currentPeriod.days} dias)...');
      final history = await _cryptoService.fetchPriceHistory(
        coinId,
        days: _currentPeriod.days,
      );

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
    
    // Timer para atualização de preços (a cada 60s)
    _updateTimer = Timer.periodic(
      Duration(seconds: Config.defaultUpdateInterval),
      (_) => updatePrices(),
    );
    
    // Timer para atualização de histórico (a cada 5 minutos)
    _historyUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => loadPriceHistories(),
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
    _historyUpdateTimer?.cancel();
    _historyUpdateTimer = null;
  }

  @override
  void dispose() {
    stopAutoUpdate();
    _cryptoService.dispose();
    super.dispose();
  }
}
