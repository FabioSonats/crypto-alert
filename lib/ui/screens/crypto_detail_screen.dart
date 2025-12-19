import 'package:flutter/material.dart';
import '../../models/crypto_price.dart';
import '../../models/investment.dart';
import '../../services/crypto_service.dart';
import '../../services/investment_service.dart';
import '../../services/settings_service.dart';
import '../../utils/config.dart';
import '../widgets/price_chart.dart';
import '../widgets/trend_indicator.dart';
import '../widgets/investment_input.dart';

/// Tela de detalhes de uma criptomoeda
///
/// Exibe: preço, variação, gráfico histórico e simulador de investimento
/// O gráfico é carregado sob demanda quando a tela é aberta
class CryptoDetailScreen extends StatefulWidget {
  /// Dados de preço da criptomoeda
  final CryptoPrice price;

  /// Serviço de investimentos
  final InvestmentService investmentService;

  /// Serviço de configurações
  final SettingsService settingsService;

  const CryptoDetailScreen({
    super.key,
    required this.price,
    required this.investmentService,
    required this.settingsService,
  });

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final CryptoService _cryptoService = CryptoService();
  
  ChartPeriod _selectedPeriod = ChartPeriod.days7;
  List<PricePoint> _priceHistory = [];
  bool _isLoadingChart = true;
  String? _chartError;

  // Cache local de históricos por período
  final Map<ChartPeriod, List<PricePoint>> _historyCache = {};

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  @override
  void dispose() {
    _cryptoService.dispose();
    super.dispose();
  }

  Future<void> _loadChart({bool force = false}) async {
    // Verifica cache primeiro
    if (!force && _historyCache.containsKey(_selectedPeriod)) {
      setState(() {
        _priceHistory = _historyCache[_selectedPeriod]!;
        _isLoadingChart = false;
        _chartError = null;
      });
      return;
    }

    setState(() {
      _isLoadingChart = true;
      _chartError = null;
    });

    try {
      final history = await _cryptoService.fetchPriceHistory(
        widget.price.coinId,
        days: _selectedPeriod.days,
      );

      if (mounted) {
        setState(() {
          _priceHistory = history;
          _historyCache[_selectedPeriod] = history;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChart = false;
          _chartError = 'Erro ao carregar gráfico';
        });
      }
      debugPrint('Erro ao carregar gráfico: $e');
    }
  }

  void _changePeriod(ChartPeriod period) {
    if (period == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = period;
    });
    _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coinColor = Color(widget.price.colorValue);
    final investment = widget.investmentService.getInvestment(widget.price.coinId);
    final variation = widget.price.variationPercentageBrl;
    final suggestedAction = variation != null 
        ? widget.settingsService.getSuggestedAction(variation)
        : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: coinColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.price.symbol.substring(0, 1),
                  style: TextStyle(
                    color: coinColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.price.name),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de preço principal
            _buildPriceCard(theme, coinColor),

            const SizedBox(height: 20),

            // Seletor de período
            Center(
              child: ChartPeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                activeColor: coinColor,
              ),
            ),

            const SizedBox(height: 16),

            // Gráfico
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Histórico de preço',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (_chartError != null)
                          TextButton.icon(
                            onPressed: () => _loadChart(force: true),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Recarregar'),
                            style: TextButton.styleFrom(
                              foregroundColor: coinColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PriceChart(
                      priceHistory: _priceHistory,
                      lineColor: coinColor,
                      height: 200,
                      isLoading: _isLoadingChart,
                      onRetry: () => _loadChart(force: true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Badge de sugestão
            if (suggestedAction != null)
              _buildSuggestionBadge(theme, suggestedAction),

            const SizedBox(height: 20),

            // Seção de investimento
            _buildInvestmentSection(theme, coinColor, investment),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(ThemeData theme, Color coinColor) {
    final variation = widget.price.variationPercentageBrl;
    final variationColor = variation == null
        ? Colors.grey
        : variation >= 0
            ? Colors.green
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preço principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.price.symbol,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.price.getFormattedPrice('BRL'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.price.getFormattedPrice('USD'),
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TrendIndicator(
                      trend: widget.price.trend,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: variationColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            variation == null
                                ? Icons.remove
                                : variation >= 0
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                            color: variationColor,
                            size: 20,
                          ),
                          Text(
                            widget.price.getFormattedVariation('BRL'),
                            style: TextStyle(
                              color: variationColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '24h',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
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

  Widget _buildSuggestionBadge(ThemeData theme, SuggestedAction action) {
    final actionInfo = SettingsService.getActionInfo(action);
    final color = Color(actionInfo.colorValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            action == SuggestedAction.buy
                ? Icons.trending_down
                : action == SuggestedAction.sell
                    ? Icons.trending_up
                    : Icons.trending_flat,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            actionInfo.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            actionInfo.description,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSection(
    ThemeData theme,
    Color coinColor,
    Investment? investment,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Simulador de Investimento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: coinColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (investment == null) ...[
              // Sem investimento
              Text(
                'Simule quanto você investiria nesta moeda e acompanhe o rendimento.',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showInvestmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Simular Investimento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: coinColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Com investimento
              _buildInvestmentInfo(theme, coinColor, investment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentInfo(
    ThemeData theme,
    Color coinColor,
    Investment investment,
  ) {
    final pl = investment.profitLoss(widget.price.priceBrl);
    final plPercentage = investment.profitLossPercentage(widget.price.priceBrl);
    final isProfit = pl >= 0;
    final plColor = isProfit ? Colors.green : Colors.red;

    return Column(
      children: [
        // Grid de informações
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isProfit
                  ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                  : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: plColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                theme,
                'Investido',
                investment.formattedAmountInvested,
                Icons.attach_money,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                'Valor atual',
                investment.formattedCurrentValue(widget.price.priceBrl),
                Icons.account_balance_wallet,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                isProfit ? 'Lucro' : 'Prejuízo',
                '${investment.formattedProfitLoss(widget.price.priceBrl)} (${plPercentage >= 0 ? '+' : ''}${plPercentage.toStringAsFixed(1)}%)',
                isProfit ? Icons.trending_up : Icons.trending_down,
                valueColor: plColor,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                'Quantidade',
                '${investment.coinsAmount.toStringAsFixed(8)} ${widget.price.symbol}',
                Icons.currency_bitcoin,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botão de editar
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showInvestmentDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _removeInvestment,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _showInvestmentDialog() async {
    final existingInvestment = widget.investmentService.getInvestment(
      widget.price.coinId,
    );

    final result = await InvestmentInputDialog.show(
      context,
      widget.price,
      existingInvestment: existingInvestment,
    );

    if (result != null && mounted) {
      await widget.investmentService.setInvestment(result);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingInvestment == null
                  ? 'Investimento simulado!'
                  : 'Investimento atualizado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeInvestment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover investimento?'),
        content: Text(
          'Tem certeza que deseja remover a simulação de investimento em ${widget.price.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.investmentService.removeInvestment(widget.price.coinId);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investimento removido'),
          ),
        );
      }
    }
  }
}

