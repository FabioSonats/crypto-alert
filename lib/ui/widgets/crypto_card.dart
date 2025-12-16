import 'package:flutter/material.dart';
import '../../models/crypto_price.dart';
import '../../models/investment.dart';
import 'trend_indicator.dart';
import 'price_chart.dart';

/// Card que exibe informações de uma criptomoeda
///
/// Inclui: nome, símbolo, preço, variação, tendência, gráfico e investimento
class CryptoCard extends StatelessWidget {
  /// Dados de preço da criptomoeda
  final CryptoPrice price;

  /// Moeda para exibição (BRL ou USD)
  final String currency;

  /// Se está carregando o histórico
  final bool isLoadingHistory;

  /// Investimento simulado (opcional)
  final Investment? investment;

  /// Callback ao tocar no card
  final VoidCallback? onTap;

  /// Callback ao tocar no botão de investimento
  final VoidCallback? onInvestmentTap;

  /// Callback para recarregar gráfico
  final VoidCallback? onChartRetry;

  const CryptoCard({
    super.key,
    required this.price,
    this.currency = 'BRL',
    this.isLoadingHistory = false,
    this.investment,
    this.onTap,
    this.onInvestmentTap,
    this.onChartRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coinColor = Color(price.colorValue);
    final variation = currency == 'BRL'
        ? price.variationPercentageBrl
        : price.variationPercentageUsd;
    final variationColor = variation == null
        ? Colors.grey
        : variation >= 0
            ? Colors.green
            : Colors.red;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? onInvestmentTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ícone + Nome + Símbolo
              Row(
                children: [
                  // Ícone da moeda (círculo colorido com símbolo)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: coinColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        price.symbol.substring(0, 1),
                        style: TextStyle(
                          color: coinColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome e símbolo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          price.symbol,
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tendência
                  TrendIndicator(
                    trend: price.trend,
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gráfico
              PriceChart(
                priceHistory: price.priceHistory ?? [],
                lineColor: coinColor,
                height: 80,
                isLoading: isLoadingHistory,
                onRetry: onChartRetry,
              ),

              const SizedBox(height: 16),

              // Preço e variação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Preço atual
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preço atual',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        price.getFormattedPrice(currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  // Variação
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Variação',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            variation == null
                                ? Icons.remove
                                : variation >= 0
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                            color: variationColor,
                            size: 24,
                          ),
                          Text(
                            price.getFormattedVariation(currency),
                            style: TextStyle(
                              color: variationColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Seção de Investimento
              if (investment != null || onInvestmentTap != null) ...[
                const Divider(height: 24),
                _buildInvestmentSection(context, coinColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentSection(BuildContext context, Color coinColor) {
    final theme = Theme.of(context);

    if (investment == null) {
      // Sem investimento - mostrar botão para adicionar
      return InkWell(
        onTap: onInvestmentTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: coinColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: coinColor.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: coinColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Simular investimento',
                style: TextStyle(
                  color: coinColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Com investimento - mostrar P&L
    final pl = investment!.profitLoss(price.priceBrl);
    final plPercentage = investment!.profitLossPercentage(price.priceBrl);
    final isProfit = pl >= 0;
    final plColor = isProfit ? Colors.green : Colors.red;

    return InkWell(
      onTap: onInvestmentTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isProfit
                ? [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05)
                  ]
                : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: plColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Header do investimento
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: plColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Seu investimento',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.edit,
                  color: theme.colorScheme.outline,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Valores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Investido
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investido',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      investment!.formattedAmountInvested,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Valor atual
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Valor atual',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      investment!.formattedCurrentValue(price.priceBrl),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Lucro/Prejuízo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isProfit ? 'Lucro' : 'Prejuízo',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfit
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: plColor,
                          size: 18,
                        ),
                        Text(
                          '${plPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: plColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card compacto para lista
class CryptoListTile extends StatelessWidget {
  final CryptoPrice price;
  final String currency;
  final VoidCallback? onTap;

  const CryptoListTile({
    super.key,
    required this.price,
    this.currency = 'BRL',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coinColor = Color(price.colorValue);
    final variation = currency == 'BRL'
        ? price.variationPercentageBrl
        : price.variationPercentageUsd;
    final variationColor = variation == null
        ? Colors.grey
        : variation >= 0
            ? Colors.green
            : Colors.red;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: coinColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            price.symbol.substring(0, 1),
            style: TextStyle(
              color: coinColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            price.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          TrendIndicator(trend: price.trend, size: 16, animated: false),
        ],
      ),
      subtitle: Text(price.symbol),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price.getFormattedPrice(currency),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            price.getFormattedVariation(currency),
            style: TextStyle(
              color: variationColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
