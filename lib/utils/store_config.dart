/// Configurações da loja de aplicativos (Play Store / App Store)
///
/// Contém os IDs dos produtos de assinatura e configurações relacionadas

class StoreConfig {
  // IDs dos produtos de assinatura

  /// ID da assinatura mensal premium
  static const String monthlySubscriptionId = 'crypto_alert_premium_monthly';

  /// ID da assinatura anual premium
  static const String yearlySubscriptionId = 'crypto_alert_premium_yearly';

  /// Conjunto de todos os IDs de produtos
  static const Set<String> productIds = {
    monthlySubscriptionId,
    yearlySubscriptionId,
  };

  // Preços (para exibição - os preços reais vêm da loja)

  /// Preço mensal sugerido
  static const String monthlyPriceDisplay = 'R\$ 9,90';

  /// Preço anual sugerido
  static const String yearlyPriceDisplay = 'R\$ 79,90';

  /// Economia no plano anual
  static const String yearlySavingsDisplay = '33%';

  // Configurações de teste

  /// Se deve usar produtos de teste (sandbox)
  static const bool useSandbox = true;

  /// IDs de teste para Android (usar em desenvolvimento)
  static const String androidTestProductId = 'android.test.purchased';

  /// IDs de teste para iOS (usar em desenvolvimento)
  static const String iosTestProductId = 'com.example.subscription';
}
