import 'package:flutter/material.dart';
import '../../controllers/crypto_controller.dart';
import '../../models/investment.dart';
import '../../services/investment_service.dart';
import '../../services/settings_service.dart';
import '../../utils/config.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/trend_indicator.dart';
import 'crypto_detail_screen.dart';
import 'settings_screen.dart';

/// Tela principal do aplicativo Crypto Alert
///
/// Exibe lista de 26 criptomoedas com preço e variação
/// Gráficos são carregados sob demanda na tela de detalhes
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
    _initServices();
  }

  Future<void> _initServices() async {
    await _investmentService.initialize();
    await _settingsService.initialize();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    widget.controller.removeListener(_onControllerUpdate);
    _investmentService.removeListener(_onInvestmentUpdate);
    _settingsService.removeListener(_onSettingsUpdate);
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settingsService: _settingsService,
        ),
      ),
    );
  }

  void _openCryptoDetail(dynamic price) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CryptoDetailScreen(
          price: price,
          investmentService: _investmentService,
          settingsService: _settingsService,
        ),
      ),
    ).then((_) {
      // Atualiza ao voltar para refletir mudanças de investimento
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar),
            SizedBox(width: 8),
            Text('Radar de Mercado'),
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

    return CustomScrollView(
      slivers: [
        // Cabeçalho com portfólio
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de Portfólio (resumo dos investimentos)
                if (_investmentService.hasInvestments)
                  PortfolioSummaryCard(
                    summary: summary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Toque em uma moeda para ver detalhes'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                if (_investmentService.hasInvestments)
                  const SizedBox(height: 16),

                // Header com status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Criptomoedas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${widget.controller.prices.length} moedas • Atualiza a cada ${Config.defaultUpdateInterval}s',
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
              ],
            ),
          ),
        ),

        // Seções de moedas separadas por sugestão
        ..._buildCryptoSections(theme),

        // Mensagem de erro
        if (widget.controller.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
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
            ),
          ),

        // Última atualização
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                _getLastUpdateText(),
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),

        // Espaço no final
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  /// Constrói as seções de moedas separadas por sugestão de ação
  List<Widget> _buildCryptoSections(ThemeData theme) {
    final threshold = _settingsService.variationThreshold;
    
    // Separa moedas por categoria
    final sellCoins = <dynamic>[];  // Variação > threshold (VENDER)
    final holdCoins = <dynamic>[];  // Entre -threshold e +threshold (MANTER)
    final buyCoins = <dynamic>[];   // Variação < -threshold (COMPRAR)

    for (final price in widget.controller.prices) {
      final variation = _selectedCurrency == 'BRL'
          ? price.variationPercentageBrl ?? 0.0
          : price.variationPercentageUsd ?? 0.0;

      if (variation >= threshold) {
        sellCoins.add(price);
      } else if (variation <= -threshold) {
        buyCoins.add(price);
      } else {
        holdCoins.add(price);
      }
    }

    // Ordena cada grupo por variação
    sellCoins.sort((a, b) {
      final varA = _selectedCurrency == 'BRL' ? a.variationPercentageBrl ?? 0.0 : a.variationPercentageUsd ?? 0.0;
      final varB = _selectedCurrency == 'BRL' ? b.variationPercentageBrl ?? 0.0 : b.variationPercentageUsd ?? 0.0;
      return varB.compareTo(varA);
    });
    holdCoins.sort((a, b) {
      final varA = _selectedCurrency == 'BRL' ? a.variationPercentageBrl ?? 0.0 : a.variationPercentageUsd ?? 0.0;
      final varB = _selectedCurrency == 'BRL' ? b.variationPercentageBrl ?? 0.0 : b.variationPercentageUsd ?? 0.0;
      return varB.compareTo(varA);
    });
    buyCoins.sort((a, b) {
      final varA = _selectedCurrency == 'BRL' ? a.variationPercentageBrl ?? 0.0 : a.variationPercentageUsd ?? 0.0;
      final varB = _selectedCurrency == 'BRL' ? b.variationPercentageBrl ?? 0.0 : b.variationPercentageUsd ?? 0.0;
      return varB.compareTo(varA);
    });

    final sections = <Widget>[];

    // Seção VENDER (em alta)
    if (sellCoins.isNotEmpty) {
      sections.add(_buildSectionHeader(
        theme,
        '📈 Em Alta',
        'Sugestão: VENDER',
        Colors.red,
        sellCoins.length,
      ));
      sections.add(_buildCoinsList(sellCoins, SuggestedAction.sell));
    }

    // Seção MANTER (estável)
    if (holdCoins.isNotEmpty) {
      sections.add(_buildSectionHeader(
        theme,
        '➡️ Estável',
        'Sugestão: MANTER',
        Colors.orange,
        holdCoins.length,
      ));
      sections.add(_buildCoinsList(holdCoins, SuggestedAction.hold));
    }

    // Seção COMPRAR (em baixa)
    if (buyCoins.isNotEmpty) {
      sections.add(_buildSectionHeader(
        theme,
        '📉 Em Baixa',
        'Sugestão: COMPRAR',
        Colors.green,
        buyCoins.length,
      ));
      sections.add(_buildCoinsList(buyCoins, SuggestedAction.buy));
    }

    return sections;
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String subtitle,
    Color color,
    int count,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsList(List<dynamic> coins, SuggestedAction defaultAction) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final price = coins[index];
          final investment = _investmentService.getInvestment(price.coinId);
          final variation = _selectedCurrency == 'BRL'
              ? price.variationPercentageBrl
              : price.variationPercentageUsd;
          final suggestedAction = _settingsService.getSuggestedAction(variation);

          return _CryptoListItem(
            price: price,
            currency: _selectedCurrency,
            investment: investment,
            suggestedAction: suggestedAction,
            onTap: () => _openCryptoDetail(price),
          );
        },
        childCount: coins.length,
      ),
    );
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

/// Item da lista de criptomoedas
class _CryptoListItem extends StatelessWidget {
  final dynamic price;
  final String currency;
  final Investment? investment;
  final SuggestedAction? suggestedAction;
  final VoidCallback onTap;

  const _CryptoListItem({
    required this.price,
    required this.currency,
    this.investment,
    this.suggestedAction,
    required this.onTap,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone da moeda
              Container(
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

              const SizedBox(width: 12),

              // Nome e símbolo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            price.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        TrendIndicator(
                          trend: price.trend,
                          size: 16,
                          animated: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          price.symbol,
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        // Badge de investimento
                        if (investment != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: coinColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '💰',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                        // Badge de ação sugerida
                        if (suggestedAction != null &&
                            suggestedAction != SuggestedAction.hold) ...[
                          const SizedBox(width: 4),
                          _buildMiniActionBadge(suggestedAction!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Preço e variação
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price.getFormattedPrice(currency),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: variationColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      price.getFormattedVariation(currency),
                      style: TextStyle(
                        color: variationColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Seta de navegação
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionBadge(SuggestedAction action) {
    final color = action == SuggestedAction.buy
        ? Colors.green
        : action == SuggestedAction.sell
            ? Colors.red
            : Colors.orange;
    final text = action == SuggestedAction.buy
        ? 'C'
        : action == SuggestedAction.sell
            ? 'V'
            : 'M';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
