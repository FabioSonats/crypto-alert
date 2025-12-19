/// Configurações centralizadas do aplicativo NexusStack
///
/// Este arquivo contém todas as constantes de configuração
/// seguindo o princípio de Single Responsibility (SOLID)
class Config {
  // ============================================
  // Configurações de Variação e Sugestão
  // ============================================

  /// Percentual de variação para sugerir ação de compra/venda
  /// Padrão: 10.0% (valor configurável pelo usuário)
  static const double defaultVariationThreshold = 10.0;

  /// Threshold mínimo permitido
  static const double minVariationThreshold = 1.0;

  /// Threshold máximo permitido
  static const double maxVariationThreshold = 15.0;

  // ============================================
  // Configurações de Moeda
  // ============================================

  /// Moeda padrão para exibição
  /// Opções: 'BRL' ou 'USD'
  static const String defaultCurrency = 'BRL';

  // ============================================
  // Configurações de Rede
  // ============================================

  /// Timeout de requisições HTTP em segundos
  static const int requestTimeout = 10;

  /// URL base da API CoinGecko
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';

  // ============================================
  // Configurações de Atualização
  // ============================================

  /// Intervalo de atualização padrão em segundos (60s = 1 minuto)
  static const int defaultUpdateInterval = 60;

  /// Máximo de alertas
  static const int maxAlerts = 999;

  // ============================================
  // Moedas Suportadas (26 criptomoedas)
  // ============================================

  /// Lista de criptomoedas monitoradas (IDs CoinGecko)
  static const List<String> supportedCoins = [
    // Top 10
    'bitcoin',
    'ethereum',
    'ripple',
    'solana',
    'cardano',
    // Layer 1 & 2
    'avalanche-2',
    'polkadot',
    'near',
    'cosmos',
    'algorand',
    // DeFi
    'chainlink',
    'uniswap',
    'aave',
    'the-graph',
    'lido-dao',
    // Layer 2 Scaling
    'matic-network',
    'arbitrum',
    'optimism',
    'immutable-x',
    // Outros
    'stellar',
    'hedera-hashgraph',
    'bitcoin-cash',
    'litecoin',
    'ethereum-classic',
    'quant-network',
    'celestia',
  ];

  /// Moedas suportadas para conversão de preço
  static const List<String> supportedCurrencies = ['usd', 'brl'];

  // ============================================
  // Mapeamento de Moedas
  // ============================================

  /// Mapa de ID para nome das criptomoedas
  static const Map<String, String> coinNames = {
    'bitcoin': 'Bitcoin',
    'ethereum': 'Ethereum',
    'ripple': 'XRP',
    'solana': 'Solana',
    'cardano': 'Cardano',
    'avalanche-2': 'Avalanche',
    'polkadot': 'Polkadot',
    'near': 'NEAR Protocol',
    'cosmos': 'Cosmos',
    'algorand': 'Algorand',
    'chainlink': 'Chainlink',
    'uniswap': 'Uniswap',
    'aave': 'Aave',
    'the-graph': 'The Graph',
    'lido-dao': 'Lido DAO',
    'matic-network': 'Polygon',
    'arbitrum': 'Arbitrum',
    'optimism': 'Optimism',
    'immutable-x': 'Immutable',
    'stellar': 'Stellar',
    'hedera-hashgraph': 'Hedera',
    'bitcoin-cash': 'Bitcoin Cash',
    'litecoin': 'Litecoin',
    'ethereum-classic': 'Ethereum Classic',
    'quant-network': 'Quant',
    'celestia': 'Celestia',
  };

  /// Mapa de ID para símbolo das criptomoedas
  static const Map<String, String> coinSymbols = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'ripple': 'XRP',
    'solana': 'SOL',
    'cardano': 'ADA',
    'avalanche-2': 'AVAX',
    'polkadot': 'DOT',
    'near': 'NEAR',
    'cosmos': 'ATOM',
    'algorand': 'ALGO',
    'chainlink': 'LINK',
    'uniswap': 'UNI',
    'aave': 'AAVE',
    'the-graph': 'GRT',
    'lido-dao': 'LDO',
    'matic-network': 'POL',
    'arbitrum': 'ARB',
    'optimism': 'OP',
    'immutable-x': 'IMX',
    'stellar': 'XLM',
    'hedera-hashgraph': 'HBAR',
    'bitcoin-cash': 'BCH',
    'litecoin': 'LTC',
    'ethereum-classic': 'ETC',
    'quant-network': 'QNT',
    'celestia': 'TIA',
  };

  /// Mapa de ID para cor das criptomoedas
  static const Map<String, int> coinColors = {
    'bitcoin': 0xFFF7931A, // Laranja Bitcoin
    'ethereum': 0xFF627EEA, // Roxo/Azul Ethereum
    'ripple': 0xFF00AAE4, // Azul claro XRP
    'solana': 0xFF9945FF, // Roxo Solana
    'cardano': 0xFF0033AD, // Azul Cardano
    'avalanche-2': 0xFFE84142, // Vermelho Avalanche
    'polkadot': 0xFFE6007A, // Pink Polkadot
    'near': 0xFF00C08B, // Verde NEAR
    'cosmos': 0xFF2E3148, // Azul escuro Cosmos
    'algorand': 0xFF000000, // Preto Algorand
    'chainlink': 0xFF375BD2, // Azul Chainlink
    'uniswap': 0xFFFF007A, // Pink Uniswap
    'aave': 0xFFB6509E, // Roxo Aave
    'the-graph': 0xFF6747ED, // Roxo The Graph
    'lido-dao': 0xFF00A3FF, // Azul Lido
    'matic-network': 0xFF8247E5, // Roxo Polygon
    'arbitrum': 0xFF28A0F0, // Azul Arbitrum
    'optimism': 0xFFFF0420, // Vermelho Optimism
    'immutable-x': 0xFF00BFFF, // Azul Immutable
    'stellar': 0xFF000000, // Preto Stellar
    'hedera-hashgraph': 0xFF222222, // Cinza escuro Hedera
    'bitcoin-cash': 0xFF8DC351, // Verde Bitcoin Cash
    'litecoin': 0xFFBFBBBB, // Cinza Litecoin
    'ethereum-classic': 0xFF328332, // Verde ETC
    'quant-network': 0xFF000000, // Preto Quant
    'celestia': 0xFF7B2BF9, // Roxo Celestia
  };

  // ============================================
  // Configurações de Gráfico
  // ============================================

  /// Dias de histórico padrão para o gráfico
  static const int chartHistoryDays = 7;

  /// Intervalo de pontos no gráfico (em horas)
  static const int chartIntervalHours = 6;
}

/// Períodos disponíveis para o gráfico
enum ChartPeriod {
  hours24('24H', 1), // 24 horas = 1 dia
  days7('7D', 7), // 7 dias
  month1('1M', 30), // 1 mês
  year1('1A', 365); // 1 ano

  final String label;
  final int days;

  const ChartPeriod(this.label, this.days);
}
