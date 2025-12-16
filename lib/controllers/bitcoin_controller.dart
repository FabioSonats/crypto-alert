import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bitcoin_price.dart';
import '../services/coin_gecko_service.dart';
import '../services/firebase_service.dart';
import '../utils/config.dart';

/// Enum para representar as ações sugeridas
enum Action {
  buy,   // Comprar
  sell,  // Vender
  hold,  // Manter
}

/// Controller para gerenciar o estado e lógica do Bitcoin
class BitcoinController extends ValueNotifier<BitcoinPrice?> {
  final CoinGeckoService _priceService;
  Timer? _updateTimer;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCurrency = Config.defaultCurrency;
  double _variationThreshold = Config.defaultVariationThreshold;
  
  BitcoinController({CoinGeckoService? priceService})
      : _priceService = priceService ?? CoinGeckoService(),
        super(null);
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCurrency => _selectedCurrency;
  double get variationThreshold => _variationThreshold;
  
  /// Sugere uma ação baseada na variação do preço
  Action suggestAction() {
    final price = value;
    if (price == null || price.variationPercentage == null) {
      return Action.hold;
    }
    
    final variation = price.variationPercentage!;
    
    if (variation < -_variationThreshold) {
      return Action.buy;
    } else if (variation > _variationThreshold) {
      return Action.sell;
    } else {
      return Action.hold;
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
        _selectedCurrency == 'BRL' ? priceWithPrevious.priceBrl : priceWithPrevious.priceUsd,
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
  Future<void> manualUpdate() async {
    await FirebaseService.logManualUpdate();
    await updatePrice();
  }
  
  /// Inicia a atualização automática periódica
  void startAutoUpdate({int? intervalSeconds}) {
    stopAutoUpdate();
    final interval = intervalSeconds ?? Config.defaultUpdateInterval;
    _updateTimer = Timer.periodic(Duration(seconds: interval), (_) {
      updatePrice();
    });
    updatePrice();
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
    _priceService.dispose();
    super.dispose();
  }
}

