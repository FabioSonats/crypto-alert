import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';
import '../../services/subscription_service.dart';

/// Widget que exibe um banner de anúncio condicionalmente
///
/// Só exibe o banner se o usuário não for premium
class ConditionalBanner extends StatefulWidget {
  /// Serviço de assinatura para verificar o tier do usuário
  final SubscriptionService subscriptionService;

  const ConditionalBanner({
    super.key,
    required this.subscriptionService,
  });

  @override
  State<ConditionalBanner> createState() => _ConditionalBannerState();
}

class _ConditionalBannerState extends State<ConditionalBanner> {
  @override
  void initState() {
    super.initState();
    // Escuta mudanças na assinatura
    widget.subscriptionService.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    widget.subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    // Rebuild quando a assinatura mudar
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se for premium, não mostra nada
    if (widget.subscriptionService.isPremium) {
      return const SizedBox.shrink();
    }

    final adService = AdService.instance;
    final bannerAd = adService.bannerAd;

    // Se o banner não estiver carregado, mostra placeholder
    if (!adService.isBannerAdLoaded || bannerAd == null) {
      return Container(
        height: 50,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Text(
            'Remova anúncios com Premium',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Exibe o banner
    return Container(
      height: 50,
      alignment: Alignment.center,
      child: AdWidget(ad: bannerAd),
    );
  }
}

/// Widget simples para exibir o banner sem verificar assinatura
/// Útil para testes ou quando a verificação é feita externamente
class SimpleBannerAd extends StatelessWidget {
  const SimpleBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final adService = AdService.instance;
    final bannerAd = adService.bannerAd;

    if (!adService.isBannerAdLoaded || bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      height: 50,
      alignment: Alignment.center,
      child: AdWidget(ad: bannerAd),
    );
  }
}
