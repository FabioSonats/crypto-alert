import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/crypto_price.dart';
import '../services/crypto_service.dart';
import '../utils/config.dart';

/// Controller para gerenciar o estado de múltiplas criptomoedas
///
/// Otimizado para uso eficiente da API:
/// - Preços: atualizam a cada 60s (inclui variação 24h)
/// - Gráficos: carregam 1x ao abrir ou mudar período (com cache)
class CryptoController extends ChangeNotifier {
  final CryptoService _cryptoService;
  Timer? _updateTimer;
  Timer? _historyRetryTimer;

  List<CryptoPrice> _prices = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  ChartPeriod _currentPeriod = ChartPeriod.days7;

  // Cache de históricos por período (evita requisições desnecessárias)
  // Estrutura: { ChartPeriod: { coinId: [PricePoint] } }
  final Map<ChartPeriod, Map<String, List<PricePoint>>> _historyCache = {};

  // Controle de retry para históricos que falharam
  final Set<String> _failedHistories = {};

  CryptoController({CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// Lista de preços das criptomoedas
  List<CryptoPrice> get prices => _prices;

  /// Histórico de preços do período atual
  Map<String, List<PricePoint>> get priceHistories =>
      _historyCache[_currentPeriod] ?? {};

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
    return _historyCache[_currentPeriod]?[coinId] ?? [];
  }

  /// Atualiza os preços de todas as moedas
  /// Esta é a única requisição que roda periodicamente (60s)
  Future<void> updatePrices() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPrices = await _cryptoService.fetchAllPrices();

      // Atualiza preços mantendo o histórico do cache
      final currentHistories = _historyCache[_currentPeriod] ?? {};
      _prices = newPrices.map((price) {
        return price.copyWith(
          priceHistory: currentHistories[price.coinId],
        );
      }).toList();

      _errorMessage = null;
      debugPrint('✅ Preços atualizados (${_prices.length} moedas)');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Erro ao atualizar preços: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega o histórico de preços para gráficos
  /// Só busca da API se não tiver no cache
  Future<void> loadPriceHistories({bool force = false}) async {
    // Verifica se já tem no cache
    if (!force && _historyCache.containsKey(_currentPeriod)) {
      final cached = _historyCache[_currentPeriod]!;
      final allLoaded = Config.supportedCoins.every(
        (coinId) => cached[coinId]?.isNotEmpty ?? false,
      );

      if (allLoaded) {
        debugPrint('📦 Usando cache para ${_currentPeriod.label}');
        _updatePricesWithHistory(cached);
        return;
      }
    }

    if (_isLoadingHistory && !force) return;

    _isLoadingHistory = true;
    _failedHistories.clear();
    notifyListeners();

    debugPrint('🔄 Buscando histórico ${_currentPeriod.label} da API...');

    try {
      final histories = await _cryptoService.fetchAllPriceHistories(
        days: _currentPeriod.days,
      );

      // Salva no cache
      _historyCache[_currentPeriod] = histories;

      // Verifica quais falharam
      for (final coinId in Config.supportedCoins) {
        if (histories[coinId]?.isEmpty ?? true) {
          _failedHistories.add(coinId);
          debugPrint('⚠️ Histórico vazio para $coinId');
        }
      }

      // Atualiza os preços com o histórico
      _updatePricesWithHistory(histories);

      // Se algum falhou, agenda retry
      if (_failedHistories.isNotEmpty) {
        _scheduleHistoryRetry();
      }

      debugPrint('✅ Histórico ${_currentPeriod.label} carregado e cacheado');
    } catch (e) {
      debugPrint('❌ Erro ao carregar histórico: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Atualiza os preços com os dados de histórico
  void _updatePricesWithHistory(Map<String, List<PricePoint>> histories) {
    _prices = _prices.map((price) {
      return price.copyWith(
        priceHistory: histories[price.coinId],
      );
    }).toList();
    notifyListeners();
  }

  /// Muda o período do gráfico
  /// Usa cache se disponível, senão busca da API
  Future<void> changePeriod(ChartPeriod period) async {
    if (_currentPeriod == period) return;

    _currentPeriod = period;
    debugPrint('📊 Mudando para ${period.label}');

    // Verifica se tem cache para este período
    if (_historyCache.containsKey(period)) {
      final cached = _historyCache[period]!;
      final allLoaded = Config.supportedCoins.every(
        (coinId) => cached[coinId]?.isNotEmpty ?? false,
      );

      if (allLoaded) {
        debugPrint('📦 Cache encontrado para ${period.label}');
        _updatePricesWithHistory(cached);
        return;
      }
    }

    // Não tem cache, mostra loading e busca da API
    _prices = _prices.map((price) {
      return price.copyWith(priceHistory: []);
    }).toList();

    _isLoadingHistory = true;
    notifyListeners();

    await loadPriceHistories(force: true);
  }

  /// Limpa o cache de um período específico
  void clearCacheFor(ChartPeriod period) {
    _historyCache.remove(period);
    debugPrint('🗑️ Cache de ${period.label} limpo');
  }

  /// Limpa todo o cache de histórico
  void clearAllCache() {
    _historyCache.clear();
    debugPrint('🗑️ Todo cache de histórico limpo');
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

    debugPrint('🔄 Tentando recarregar: $_failedHistories');

    for (final coinId in _failedHistories.toList()) {
      try {
        final history = await _cryptoService.fetchPriceHistory(
          coinId,
          days: _currentPeriod.days,
        );
        if (history.isNotEmpty) {
          // Atualiza o cache
          _historyCache[_currentPeriod] ??= {};
          _historyCache[_currentPeriod]![coinId] = history;
          _failedHistories.remove(coinId);

          // Atualiza o preço com o novo histórico
          _prices = _prices.map((price) {
            if (price.coinId == coinId) {
              return price.copyWith(priceHistory: history);
            }
            return price;
          }).toList();

          notifyListeners();
          debugPrint('✅ Histórico de $coinId carregado!');
        }
        // Delay entre requisições
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        debugPrint('❌ Retry falhou para $coinId: $e');
      }
    }

    // Se ainda tem falhas, agenda outro retry
    if (_failedHistories.isNotEmpty) {
      _scheduleHistoryRetry();
    }
  }

  /// Recarrega o histórico de uma moeda específica (botão manual)
  Future<void> reloadHistoryFor(String coinId) async {
    try {
      debugPrint('🔄 Recarregando $coinId (${_currentPeriod.days} dias)...');
      final history = await _cryptoService.fetchPriceHistory(
        coinId,
        days: _currentPeriod.days,
      );

      if (history.isNotEmpty) {
        // Atualiza o cache
        _historyCache[_currentPeriod] ??= {};
        _historyCache[_currentPeriod]![coinId] = history;
        _failedHistories.remove(coinId);

        _prices = _prices.map((price) {
          if (price.coinId == coinId) {
            return price.copyWith(priceHistory: history);
          }
          return price;
        }).toList();

        notifyListeners();
        debugPrint('✅ Histórico de $coinId recarregado!');
      }
    } catch (e) {
      debugPrint('❌ Erro ao recarregar histórico de $coinId: $e');
    }
  }

  /// Atualização manual (pull to refresh)
  Future<void> manualUpdate() async {
    await updatePrices();

    // Também tenta recarregar históricos que falharam
    if (_failedHistories.isNotEmpty) {
      _retryFailedHistories();
    }
  }

  /// Inicia a atualização automática
  /// APENAS preços atualizam automaticamente (60s)
  /// Gráficos só carregam 1x ao abrir
  void startAutoUpdate() {
    stopAutoUpdate();

    // Timer APENAS para preços (a cada 60s)
    _updateTimer = Timer.periodic(
      Duration(seconds: Config.defaultUpdateInterval),
      (_) => updatePrices(),
    );

    // Carrega dados iniciais
    updatePrices();
    loadPriceHistories(); // Só 1x ao iniciar
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
