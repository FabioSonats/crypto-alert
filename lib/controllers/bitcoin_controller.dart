import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bitcoin_price.dart';
import '../services/coin_gecko_service.dart';
import '../services/firebase_service.dart';
import '../services/subscription_service.dart';
import '../services/ad_service.dart';

/// Enum para representar as ações sugeridas
enum SuggestedAction {
  buy, // Comprar
  sell, // Vender
  hold, // Manter
}

/// Controller para gerenciar o estado e lógica do Bitcoin
class BitcoinController extends ValueNotifier<BitcoinPrice?> {
  final CoinGeckoService _priceService;
  final SubscriptionService _subscriptionService;
  Timer? _updateTimer;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCurrency = 'BRL';
  final double _variationThreshold = 3.0;
  int _manualUpdateCount = 0;

  BitcoinController({
    CoinGeckoService? priceService,
    required SubscriptionService subscriptionService,
  })  : _priceService = priceService ?? CoinGeckoService(),
        _subscriptionService = subscriptionService,
        super(null);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCurrency => _selectedCurrency;
  double get variationThreshold => _variationThreshold;

  /// Acesso ao serviço de assinatura
  SubscriptionService get subscriptionService => _subscriptionService;

  /// Verifica se o usuário é premium
  bool get isPremium => _subscriptionService.isPremium;

  /// Sugere uma ação baseada na variação do preço
  SuggestedAction suggestAction() {
    final price = value;
    if (price == null || price.variationPercentage == null) {
      return SuggestedAction.hold;
    }

    final variation = price.variationPercentage!;

    if (variation < -_variationThreshold) {
      return SuggestedAction.buy;
    } else if (variation > _variationThreshold) {
      return SuggestedAction.sell;
    } else {
      return SuggestedAction.hold;
    }
  }

  /// Atualiza o preço do Bitcoin
  Future<void> updatePrice() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final previousPrice = value?.priceBrl;
      final newPrice = await _priceService.fetchPrice();

      final priceWithPrevious = newPrice.copyWith(
        previousPrice: previousPrice,
      );

      value = priceWithPrevious;

      await FirebaseService.logPriceUpdated(
        _selectedCurrency == 'BRL'
            ? priceWithPrevious.priceBrl
            : priceWithPrevious.priceUsd,
        _selectedCurrency,
      );

      final action = suggestAction();
      await FirebaseService.logActionSuggested(
        action.name,
        priceWithPrevious.variationPercentage,
      );

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Erro ao atualizar preço: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza o preço manualmente
  /// Exibe interstitial ad a cada 3 atualizações manuais (apenas para free)
  Future<void> manualUpdate() async {
    await FirebaseService.logManualUpdate();
    await updatePrice();

    // Incrementa contador e mostra interstitial a cada 3 updates (só free)
    if (!isPremium) {
      _manualUpdateCount++;
      if (_manualUpdateCount >= 3) {
        _manualUpdateCount = 0;
        // Tenta mostrar interstitial
        await AdService.instance.showInterstitialAd();
      }
    }
  }

  /// Inicia a atualização automática periódica
  /// Usa intervalo baseado no tier da assinatura
  void startAutoUpdate() {
    stopAutoUpdate();
    final interval = _subscriptionService.updateInterval;
    _updateTimer = Timer.periodic(Duration(seconds: interval), (_) {
      updatePrice();
    });
    updatePrice();

    // Escuta mudanças na assinatura para ajustar o intervalo
    _subscriptionService.addListener(_onSubscriptionChanged);
  }

  /// Callback quando a assinatura muda
  void _onSubscriptionChanged() {
    // Reinicia o timer com o novo intervalo
    startAutoUpdate();
  }

  /// Para a atualização automática
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Altera a moeda selecionada
  void changeCurrency(String currency) {
    if (currency == _selectedCurrency) return;
    final oldCurrency = _selectedCurrency;
    _selectedCurrency = currency;
    FirebaseService.logCurrencyChanged(oldCurrency, currency);
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoUpdate();
    _subscriptionService.removeListener(_onSubscriptionChanged);
    _priceService.dispose();
    super.dispose();
  }
}
