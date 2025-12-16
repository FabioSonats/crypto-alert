import 'package:flutter/material.dart';
import '../../controllers/crypto_controller.dart';
import '../../models/investment.dart';
import '../../services/investment_service.dart';
import '../../utils/config.dart';
import '../widgets/crypto_card.dart';
import '../widgets/investment_input.dart';
import '../widgets/portfolio_summary_card.dart';

/// Tela principal do aplicativo Crypto Alert
///
/// Exibe as 3 criptomoedas: Bitcoin, Ethereum e XRP
/// Com simulador de investimento integrado
class HomeScreen extends StatefulWidget {
  final CryptoController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCurrency = Config.defaultCurrency;
  final InvestmentService _investmentService = InvestmentService();

  @override
  void initState() {
    super.initState();
    widget.controller.startAutoUpdate();
    widget.controller.addListener(_onControllerUpdate);
    _investmentService.addListener(_onInvestmentUpdate);
    _initInvestmentService();
  }

  Future<void> _initInvestmentService() async {
    await _investmentService.initialize();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _investmentService.removeListener(_onInvestmentUpdate);
    widget.controller.stopAutoUpdate();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onInvestmentUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_bitcoin),
            SizedBox(width: 8),
            Text('Crypto Alert'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Toggle de moeda
          PopupMenuButton<String>(
            icon: Text(
              _selectedCurrency,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            onSelected: (value) {
              setState(() {
                _selectedCurrency = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'BRL', child: Text('R\$ BRL')),
              const PopupMenuItem(value: 'USD', child: Text('\$ USD')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.controller.manualUpdate(),
        child: widget.controller.prices.isEmpty
            ? _buildLoadingState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando cotações...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final summary =
        _investmentService.calculateSummary(widget.controller.prices);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Portfólio (resumo dos investimentos)
          PortfolioSummaryCard(
            summary: summary,
            onTap: () {
              // Scroll para o primeiro card ou mostra dica
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toque em uma moeda para simular investimento'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Header com status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cotações em tempo real',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Atualização a cada ${Config.defaultUpdateInterval}s',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // Indicador de loading
              if (widget.controller.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Cards das moedas
          ...widget.controller.prices.map((price) {
            final investment = _investmentService.getInvestment(price.coinId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CryptoCard(
                price: price,
                currency: _selectedCurrency,
                isLoadingHistory: widget.controller.isLoadingHistory,
                investment: investment,
                onInvestmentTap: () => _showInvestmentDialog(price, investment),
                onChartRetry: () =>
                    widget.controller.reloadHistoryFor(price.coinId),
              ),
            );
          }),

          // Mensagem de erro
          if (widget.controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.controller.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Última atualização
          Center(
            child: Text(
              _getLastUpdateText(),
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showInvestmentDialog(
    dynamic price,
    Investment? existingInvestment,
  ) async {
    final result = await InvestmentInputDialog.show(
      context,
      price,
      existingInvestment: existingInvestment,
    );

    if (result != null) {
      // Salva o novo investimento
      await _investmentService.setInvestment(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingInvestment == null
                  ? 'Investimento simulado em ${price.name}!'
                  : 'Investimento atualizado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (existingInvestment != null && result == null) {
      // Se tinha investimento e retornou null, significa que quer remover
      // (isso só acontece se o usuário clicou no botão Remover)
    }
  }

  String _getLastUpdateText() {
    if (widget.controller.prices.isEmpty) {
      return 'Aguardando dados...';
    }
    final lastUpdate = widget.controller.prices.first.lastUpdate;
    final now = DateTime.now();
    final diff = now.difference(lastUpdate);

    if (diff.inSeconds < 60) {
      return 'Atualizado há ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'Atualizado há ${diff.inMinutes}min';
    } else {
      return 'Atualizado há ${diff.inHours}h';
    }
  }
}
