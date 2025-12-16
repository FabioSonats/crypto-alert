import 'package:flutter/material.dart';
import '../../controllers/bitcoin_controller.dart';

/// Widget para exibir o indicador visual de ação sugerida
class ActionIndicator extends StatelessWidget {
  final Action action;
  final double? variationPercentage;
  
  const ActionIndicator({
    super.key,
    required this.action,
    this.variationPercentage,
  });
  
  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _getActionData();
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (variationPercentage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Variação: ${variationPercentage!.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  (IconData, String, Color) _getActionData() {
    switch (action) {
      case Action.buy:
        return (Icons.trending_down, 'COMPRAR', Colors.green);
      case Action.sell:
        return (Icons.trending_up, 'VENDER', Colors.red);
      case Action.hold:
        return (Icons.trending_flat, 'MANTER', Colors.orange);
    }
  }
}

