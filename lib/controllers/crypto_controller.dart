import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/crypto_price.dart';
import '../services/crypto_service.dart';
import '../utils/config.dart';

/// Controller para gerenciar o estado de múltiplas criptomoedas
///
/// Otimizado para uso eficiente da API:
/// - Preços: atualizam a cada 60s (inclui variação 24h)
/// - Gráficos: carregados sob demanda na tela de detalhes
class CryptoController extends ChangeNotifier {
  final CryptoService _cryptoService;
  Timer? _updateTimer;

  List<CryptoPrice> _prices = [];
  bool _isLoading = false;
  String? _errorMessage;

  CryptoController({CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// Lista de preços das criptomoedas
  List<CryptoPrice> get prices => _prices;

  /// Se está carregando preços
  bool get isLoading => _isLoading;

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

  /// Atualiza os preços de todas as moedas
  /// Esta é a única requisição que roda periodicamente (60s)
  Future<void> updatePrices() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPrices = await _cryptoService.fetchAllPrices();
      _prices = newPrices;
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

  /// Atualização manual (pull to refresh)
  Future<void> manualUpdate() async {
    await updatePrices();
  }

  /// Inicia a atualização automática
  /// APENAS preços atualizam automaticamente (60s)
  /// Gráficos são carregados sob demanda na tela de detalhes
  void startAutoUpdate() {
    stopAutoUpdate();

    // Timer APENAS para preços (a cada 60s)
    _updateTimer = Timer.periodic(
      Duration(seconds: Config.defaultUpdateInterval),
      (_) => updatePrices(),
    );

    // Carrega dados iniciais
    updatePrices();
  }

  /// Para a atualização automática
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void dispose() {
    stopAutoUpdate();
    _cryptoService.dispose();
    super.dispose();
  }
}
