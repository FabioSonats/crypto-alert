/// Serviço para integração com Firebase Analytics
/// 
/// NOTA: Firebase ainda não configurado. Métodos são placeholders.
class FirebaseService {
  /// Registra evento de atualização de preço
  static Future<void> logPriceUpdated(double price, String currency) async {
    // Firebase Analytics será implementado após configuração
    // Por enquanto, apenas imprime no console
    print('Analytics: price_updated - $currency: $price');
  }
  
  /// Registra evento de ação sugerida
  static Future<void> logActionSuggested(String action, double? variationPercentage) async {
    print('Analytics: action_suggested - $action (${variationPercentage?.toStringAsFixed(2)}%)');
  }
  
  /// Registra evento de atualização manual
  static Future<void> logManualUpdate() async {
    print('Analytics: manual_update');
  }
  
  /// Registra evento de mudança de moeda
  static Future<void> logCurrencyChanged(String fromCurrency, String toCurrency) async {
    print('Analytics: currency_changed - $fromCurrency -> $toCurrency');
  }
}

