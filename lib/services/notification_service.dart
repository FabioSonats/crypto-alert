import 'package:flutter/foundation.dart';
import '../models/crypto_price.dart';

/// Serviço para gerenciar notificações push
///
/// Por enquanto usa uma implementação local simples.
/// Para produção, integrar com firebase_messaging ou flutter_local_notifications
class NotificationService {
  static NotificationService? _instance;

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  // Thresholds para notificação (variação em %)
  double _notificationThreshold = 5.0;

  // Últimos preços notificados (para evitar spam)
  final Map<String, double> _lastNotifiedPrices = {};

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  double get notificationThreshold => _notificationThreshold;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Inicializar firebase_messaging ou flutter_local_notifications
      // await FirebaseMessaging.instance.requestPermission();
      // await FlutterLocalNotificationsPlugin().initialize(...);

      _isInitialized = true;
      debugPrint('NotificationService inicializado');
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
    }
  }

  /// Habilita/desabilita notificações
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  /// Define o threshold de variação para notificação
  void setNotificationThreshold(double threshold) {
    _notificationThreshold = threshold;
  }

  /// Verifica e envia notificação se necessário
  Future<void> checkAndNotify(List<CryptoPrice> prices) async {
    if (!_notificationsEnabled || !_isInitialized) return;

    for (final price in prices) {
      final variation = price.variationPercentageBrl;
      if (variation == null) continue;

      // Verifica se a variação é significativa
      if (variation.abs() >= _notificationThreshold) {
        // Verifica se já notificou recentemente (evita spam)
        final lastPrice = _lastNotifiedPrices[price.coinId];
        if (lastPrice != null) {
          final priceChange =
              ((price.priceBrl - lastPrice) / lastPrice).abs() * 100;
          if (priceChange < _notificationThreshold) {
            continue; // Não notifica se a mudança desde última notificação for pequena
          }
        }

        await _sendNotification(price, variation);
        _lastNotifiedPrices[price.coinId] = price.priceBrl;
      }
    }
  }

  /// Envia uma notificação
  Future<void> _sendNotification(CryptoPrice price, double variation) async {
    final isUp = variation > 0;
    final emoji = isUp ? '📈' : '📉';
    final action = isUp ? 'subiu' : 'caiu';
    final sign = isUp ? '+' : '';

    final title = '$emoji ${price.name} $action!';
    final body =
        '${price.symbol}: ${price.getFormattedPrice('BRL')} ($sign${variation.toStringAsFixed(2)}%)';

    debugPrint('Notificação: $title - $body');

    // TODO: Implementar envio real de notificação
    // await FlutterLocalNotificationsPlugin().show(
    //   price.coinId.hashCode,
    //   title,
    //   body,
    //   const NotificationDetails(...),
    // );
  }

  /// Envia notificação de teste
  Future<void> sendTestNotification() async {
    debugPrint('Enviando notificação de teste...');

    // TODO: Implementar notificação de teste real
    // await FlutterLocalNotificationsPlugin().show(
    //   0,
    //   '🔔 Crypto Alert',
    //   'Notificações configuradas com sucesso!',
    //   const NotificationDetails(...),
    // );
  }

  /// Agenda notificação diária de resumo
  Future<void> scheduleDailySummary() async {
    // TODO: Implementar agendamento de notificação diária
    debugPrint('Agendamento de resumo diário configurado');
  }

  /// Cancela todas as notificações agendadas
  Future<void> cancelAllNotifications() async {
    // TODO: Implementar cancelamento
    debugPrint('Todas as notificações canceladas');
  }
}

/// Configurações de notificação para persistência
class NotificationSettings {
  final bool enabled;
  final double threshold;
  final bool dailySummary;
  final int dailySummaryHour;

  const NotificationSettings({
    this.enabled = true,
    this.threshold = 5.0,
    this.dailySummary = false,
    this.dailySummaryHour = 9,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'threshold': threshold,
        'dailySummary': dailySummary,
        'dailySummaryHour': dailySummaryHour,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      threshold: (json['threshold'] ?? 5.0).toDouble(),
      dailySummary: json['dailySummary'] ?? false,
      dailySummaryHour: json['dailySummaryHour'] ?? 9,
    );
  }
}
