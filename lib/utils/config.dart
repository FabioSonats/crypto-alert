/// Configurações centralizadas do aplicativo Crypto Alert
///
/// Este arquivo contém todas as constantes de configuração
/// seguindo o princípio de Single Responsibility (SOLID)
class Config {
  // ============================================
  // Configurações de Variação e Sugestão
  // ============================================

  /// Percentual de variação para sugerir ação de compra/venda
  /// Padrão: 3.0% (valor configurável)
  static const double defaultVariationThreshold = 3.0;

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

  /// Intervalo de atualização padrão em segundos (10s para todos)
  static const int defaultUpdateInterval = 10;

  /// Máximo de alertas
  static const int maxAlerts = 999;

  // ============================================
  // Moedas Suportadas
  // ============================================

  /// Lista de criptomoedas monitoradas
  static const List<String> supportedCoins = [
    'bitcoin',
    'ethereum',
    'ripple',
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
  };

  /// Mapa de ID para símbolo das criptomoedas
  static const Map<String, String> coinSymbols = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'ripple': 'XRP',
  };

  /// Mapa de ID para cor das criptomoedas
  static const Map<String, int> coinColors = {
    'bitcoin': 0xFFF7931A, // Laranja Bitcoin
    'ethereum': 0xFF627EEA, // Roxo/Azul Ethereum
    'ripple': 0xFF23292F, // Cinza escuro XRP
  };

  // ============================================
  // Configurações de Gráfico
  // ============================================

  /// Dias de histórico para o gráfico
  static const int chartHistoryDays = 7;

  /// Intervalo de pontos no gráfico (em horas)
  static const int chartIntervalHours = 6;
}
