/// Configurações centralizadas do aplicativo Crypto Alert
/// 
/// Este arquivo contém todas as constantes de configuração
/// seguindo o princípio de Single Responsibility (SOLID)
class Config {
  // Percentual de variação para sugerir ação de compra/venda
  // Padrão: 3.0% (valor configurável)
  static const double defaultVariationThreshold = 3.0;
  
  // Intervalo de atualização automática em segundos
  // Padrão: 60 segundos
  static const int defaultUpdateInterval = 60;
  
  // Moeda padrão para exibição
  // Opções: 'BRL' ou 'USD'
  static const String defaultCurrency = 'BRL';
  
  // Timeout de requisições HTTP em segundos
  static const int requestTimeout = 10;
  
  // URL base da API CoinGecko
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  // ID da criptomoeda (Bitcoin)
  static const String bitcoinId = 'bitcoin';
  
  // Moedas suportadas para conversão
  static const List<String> supportedCurrencies = ['usd', 'brl'];
}

