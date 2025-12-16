import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../utils/store_config.dart';

/// Modal sheet para upgrade para Premium
/// 
/// Exibe os benefícios do plano premium e opções de assinatura
class PaywallSheet extends StatelessWidget {
  /// Serviço de assinatura para realizar a compra
  final SubscriptionService subscriptionService;
  
  const PaywallSheet({
    super.key,
    required this.subscriptionService,
  });
  
  /// Exibe o paywall como bottom sheet
  static Future<void> show(BuildContext context, SubscriptionService service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallSheet(subscriptionService: service),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.amber.shade700, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Ícone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Título
            const Text(
              'Crypto Alert Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Desbloqueie todo o potencial do app',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            
            // Benefícios
            _buildBenefit(Icons.block, 'Sem anúncios'),
            _buildBenefit(Icons.speed, 'Atualização a cada 10 segundos'),
            _buildBenefit(Icons.currency_bitcoin, '+5 criptomoedas'),
            _buildBenefit(Icons.notifications_active, 'Alertas ilimitados'),
            _buildBenefit(Icons.palette, 'Temas exclusivos'),
            
            const SizedBox(height: 24),
            
            // Preços
            Row(
              children: [
                // Mensal
                Expanded(
                  child: _buildPriceCard(
                    context,
                    title: 'Mensal',
                    price: StoreConfig.monthlyPriceDisplay,
                    subtitle: 'por mês',
                    isPopular: false,
                    onTap: () => _onBuyMonthly(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Anual
                Expanded(
                  child: _buildPriceCard(
                    context,
                    title: 'Anual',
                    price: StoreConfig.yearlyPriceDisplay,
                    subtitle: 'por ano',
                    isPopular: true,
                    badge: 'Economize ${StoreConfig.yearlySavingsDisplay}',
                    onTap: () => _onBuyYearly(context),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Restaurar compras
            TextButton(
              onPressed: () => _onRestorePurchases(context),
              child: Text(
                'Restaurar compras',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            
            // Continuar com anúncios
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continuar com anúncios',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.greenAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required bool isPopular,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPopular 
              ? Colors.white 
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: isPopular 
              ? Border.all(color: Colors.amber, width: 2) 
              : null,
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPopular ? Colors.black87 : Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isPopular ? Colors.black : Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isPopular ? Colors.black54 : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _onBuyMonthly(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      await subscriptionService.buySubscription(
        StoreConfig.monthlySubscriptionId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  void _onBuyYearly(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      await subscriptionService.buySubscription(
        StoreConfig.yearlySubscriptionId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  void _onRestorePurchases(BuildContext context) async {
    Navigator.pop(context);
    await subscriptionService.restorePurchases();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando compras anteriores...')),
      );
    }
  }
}

