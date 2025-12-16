import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment.dart';
import '../models/crypto_price.dart';

/// Serviço para gerenciar investimentos simulados
///
/// Persiste os dados localmente usando SharedPreferences
class InvestmentService extends ChangeNotifier {
  static const String _storageKey = 'investments';

  Map<String, Investment> _investments = {};

  /// Mapa de investimentos por coinId
  Map<String, Investment> get investments => _investments;

  /// Verifica se há algum investimento
  bool get hasInvestments => _investments.isNotEmpty;

  /// Retorna o investimento de uma moeda específica
  Investment? getInvestment(String coinId) => _investments[coinId];

  /// Inicializa o serviço carregando dados salvos
  Future<void> initialize() async {
    await _loadInvestments();
  }

  /// Adiciona ou atualiza um investimento
  Future<void> setInvestment(Investment investment) async {
    _investments[investment.coinId] = investment;
    await _saveInvestments();
    notifyListeners();
  }

  /// Remove um investimento
  Future<void> removeInvestment(String coinId) async {
    _investments.remove(coinId);
    await _saveInvestments();
    notifyListeners();
  }

  /// Limpa todos os investimentos
  Future<void> clearAll() async {
    _investments.clear();
    await _saveInvestments();
    notifyListeners();
  }

  /// Calcula o resumo do portfólio
  PortfolioSummary calculateSummary(List<CryptoPrice> prices) {
    double totalInvested = 0;
    double totalCurrentValue = 0;

    for (final investment in _investments.values) {
      totalInvested += investment.amountInvested;

      // Encontra o preço atual da moeda
      final price = prices.firstWhere(
        (p) => p.coinId == investment.coinId,
        orElse: () => CryptoPrice(
          coinId: investment.coinId,
          priceUsd: 0,
          priceBrl: investment.priceAtPurchase,
          lastUpdate: DateTime.now(),
        ),
      );

      totalCurrentValue += investment.currentValue(price.priceBrl);
    }

    return PortfolioSummary(
      totalInvested: totalInvested,
      totalCurrentValue: totalCurrentValue,
      investments: _investments.values.toList(),
    );
  }

  /// Carrega investimentos do storage
  Future<void> _loadInvestments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _investments = {
          for (final item in jsonList)
            (item['coinId'] as String): Investment.fromJson(item),
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar investimentos: $e');
    }
  }

  /// Salva investimentos no storage
  Future<void> _saveInvestments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _investments.values.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar investimentos: $e');
    }
  }
}
