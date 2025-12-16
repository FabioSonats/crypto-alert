/// Modelo de assinatura do usuário
///
/// Define os níveis de assinatura (free/premium) e suas propriedades

/// Níveis de assinatura disponíveis
enum SubscriptionTier {
  /// Usuário gratuito - com anúncios e recursos limitados
  free,

  /// Usuário premium - sem anúncios e recursos completos
  premium,
}

/// Modelo que representa a assinatura atual do usuário
class Subscription {
  /// Nível da assinatura (free ou premium)
  final SubscriptionTier tier;

  /// Data de expiração da assinatura (null para free)
  final DateTime? expiresAt;

  /// ID do produto comprado (null para free)
  final String? productId;

  /// Construtor
  const Subscription({
    required this.tier,
    this.expiresAt,
    this.productId,
  });

  /// Cria uma assinatura gratuita padrão
  const Subscription.free()
      : tier = SubscriptionTier.free,
        expiresAt = null,
        productId = null;

  /// Cria uma assinatura premium
  const Subscription.premium({
    required this.expiresAt,
    required this.productId,
  }) : tier = SubscriptionTier.premium;

  /// Verifica se o usuário é premium
  bool get isPremium => tier == SubscriptionTier.premium;

  /// Verifica se deve mostrar anúncios
  bool get showAds => !isPremium;

  /// Verifica se a assinatura está ativa (não expirou)
  bool get isActive {
    if (tier == SubscriptionTier.free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Cria uma cópia com valores alterados
  Subscription copyWith({
    SubscriptionTier? tier,
    DateTime? expiresAt,
    String? productId,
  }) {
    return Subscription(
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      productId: productId ?? this.productId,
    );
  }

  /// Converte para Map (para persistência)
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'expiresAt': expiresAt?.toIso8601String(),
      'productId': productId,
    };
  }

  /// Cria a partir de Map (para persistência)
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      productId: json['productId'],
    );
  }

  @override
  String toString() => 'Subscription(tier: $tier, expiresAt: $expiresAt)';
}
