import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

/// Enum para ações sugeridas baseadas na variação
enum SuggestedAction {
  buy, // Comprar (preço caiu)
  sell, // Vender (preço subiu)
  hold, // Manter (variação pequena)
}

/// Serviço para gerenciar configurações do usuário
///
/// Persiste as preferências localmente usando SharedPreferences
class SettingsService extends ChangeNotifier {
  static const String _thresholdKey = 'variation_threshold';

  double _variationThreshold = Config.defaultVariationThreshold;

  /// Threshold atual para sugestão de ação
  double get variationThreshold => _variationThreshold;

  /// Inicializa o serviço carregando configurações salvas
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Define o threshold de variação
  Future<void> setVariationThreshold(double value) async {
    // Garante que está dentro dos limites
    final clampedValue = value.clamp(
      Config.minVariationThreshold,
      Config.maxVariationThreshold,
    );

    if (_variationThreshold != clampedValue) {
      _variationThreshold = clampedValue;
      await _saveSettings();
      notifyListeners();
    }
  }

  /// Retorna a ação sugerida baseada na variação
  SuggestedAction getSuggestedAction(double? variation) {
    if (variation == null) return SuggestedAction.hold;

    if (variation <= -_variationThreshold) {
      return SuggestedAction.buy; // Preço caiu muito -> comprar
    } else if (variation >= _variationThreshold) {
      return SuggestedAction.sell; // Preço subiu muito -> vender
    } else {
      return SuggestedAction.hold; // Variação pequena -> manter
    }
  }

  /// Retorna informações da ação para UI
  static ActionInfo getActionInfo(SuggestedAction action) {
    switch (action) {
      case SuggestedAction.buy:
        return ActionInfo(
          label: 'COMPRAR',
          description: 'Preço em queda',
          colorValue: 0xFF4CAF50, // Verde
        );
      case SuggestedAction.sell:
        return ActionInfo(
          label: 'VENDER',
          description: 'Preço em alta',
          colorValue: 0xFFF44336, // Vermelho
        );
      case SuggestedAction.hold:
        return ActionInfo(
          label: 'MANTER',
          description: 'Variação normal',
          colorValue: 0xFFFF9800, // Laranja
        );
    }
  }

  /// Carrega configurações do storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _variationThreshold =
          prefs.getDouble(_thresholdKey) ?? Config.defaultVariationThreshold;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
    }
  }

  /// Salva configurações no storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_thresholdKey, _variationThreshold);
    } catch (e) {
      debugPrint('Erro ao salvar configurações: $e');
    }
  }
}

/// Informações de uma ação sugerida para exibição na UI
class ActionInfo {
  final String label;
  final String description;
  final int colorValue;

  const ActionInfo({
    required this.label,
    required this.description,
    required this.colorValue,
  });
}
