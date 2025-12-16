/// Configurações centralizadas do aplicativo Crypto Alert
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

  /// URL da API do Banco Central para taxa SELIC
  static const String bcbSelicUrl =
      'https://api.bcb.gov.br/dados/serie/bcdata.sgs.4189/dados?formato=json';

  // ============================================
  // Configurações de Atualização
  // ============================================

  /// Intervalo de atualização padrão em segundos (60s = 1 minuto)
  static const int defaultUpdateInterval = 60;

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
    'ripple': 0xFF00AAE4, // Azul claro XRP (cor oficial)
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
  hours24('24H', 1),    // 24 horas = 1 dia
  days7('7D', 7),       // 7 dias
  month1('1M', 30),     // 1 mês
  year1('1A', 365);     // 1 ano

  final String label;
  final int days;

  const ChartPeriod(this.label, this.days);
}
