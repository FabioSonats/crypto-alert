import 'package:flutter/material.dart';
import '../../models/bitcoin_price.dart';

/// Widget para exibir o preço do Bitcoin em um card
class PriceCard extends StatelessWidget {
  final BitcoinPrice? price;
  final String currency;
  final bool isLoading;
  
  const PriceCard({
    super.key,
    required this.price,
    required this.currency,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preço do Bitcoin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (price != null)
              Text(
                price!.getFormattedPrice(currency),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Text(
                'Carregando...',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            if (price != null && !isLoading) ...[
              const SizedBox(height: 8),
              Text(
                'Atualizado em: ${_formatDateTime(price!.lastUpdate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

