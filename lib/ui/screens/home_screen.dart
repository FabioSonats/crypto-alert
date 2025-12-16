import 'package:flutter/material.dart';
import '../../controllers/crypto_controller.dart';
import '../../models/investment.dart';
import '../../services/investment_service.dart';
import '../../services/settings_service.dart';
import '../../services/tesouro_service.dart';
import '../../utils/config.dart';
import '../widgets/crypto_card.dart';
import '../widgets/investment_input.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/tesouro_card.dart';
import 'settings_screen.dart';

/// Tela principal do aplicativo Crypto Alert
///
/// Exibe as 3 criptomoedas: Bitcoin, Ethereum e XRP
/// Com simulador de investimento integrado e Tesouro Direto
class HomeScreen extends StatefulWidget {
  final CryptoController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _selectedCurrency = Config.defaultCurrency;
  final InvestmentService _investmentService = InvestmentService();
  final SettingsService _settingsService = SettingsService();
  final TesouroService _tesouroService = TesouroService();
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    // Registra observer para ciclo de vida do app
    WidgetsBinding.instance.addObserver(this);

    widget.controller.startAutoUpdate();
    widget.controller.addListener(_onControllerUpdate);
    _investmentService.addListener(_onInvestmentUpdate);
    _settingsService.addListener(_onSettingsUpdate);
    _tesouroService.addListener(_onTesouroUpdate);
    _initServices();
  }

  Future<void> _initServices() async {
    await _investmentService.initialize();
    await _settingsService.initialize();
    await _tesouroService.initialize();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    widget.controller.removeListener(_onControllerUpdate);
    _investmentService.removeListener(_onInvestmentUpdate);
    _settingsService.removeListener(_onSettingsUpdate);
    _tesouroService.removeListener(_onTesouroUpdate);
    widget.controller.stopAutoUpdate();
    super.dispose();
  }

  /// Detecta mudanças no ciclo de vida do app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App foi para background -> PARA requisições
        if (!_isInBackground) {
          _isInBackground = true;
          widget.controller.stopAutoUpdate();
          debugPrint('📱 App em background - requisições pausadas');
        }
        break;
      case AppLifecycleState.resumed:
        // App voltou ao primeiro plano -> RETOMA requisições
        if (_isInBackground) {
          _isInBackground = false;
          widget.controller.startAutoUpdate();
          debugPrint('📱 App em foreground - requisições retomadas');
        }
        break;
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onInvestmentUpdate() {
    if (mounted) setState(() {});
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _onTesouroUpdate() {
    if (mounted) setState(() {});
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settingsService: _settingsService,
        ),
      ),
    );
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
          // Botão de configurações
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: 'Configurações',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toque em uma moeda para simular investimento'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Card Tesouro Direto
          TesouroCard(tesouroService: _tesouroService),

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
                  Row(
                    children: [
                      Text(
                        'Atualização a cada ${Config.defaultUpdateInterval}s',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      if (_isInBackground) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PAUSADO',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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

          const SizedBox(height: 12),

          // Seletor de período do gráfico
          Center(
            child: ChartPeriodSelector(
              selectedPeriod: widget.controller.currentPeriod,
              onPeriodChanged: (period) {
                widget.controller.changePeriod(period);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Cards das moedas
          ...widget.controller.prices.map((price) {
            final investment = _investmentService.getInvestment(price.coinId);
            final variation = _selectedCurrency == 'BRL'
                ? price.variationPercentageBrl
                : price.variationPercentageUsd;
            final suggestedAction =
                _settingsService.getSuggestedAction(variation);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CryptoCard(
                price: price,
                currency: _selectedCurrency,
                isLoadingHistory: widget.controller.isLoadingHistory,
                investment: investment,
                suggestedAction: suggestedAction,
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
