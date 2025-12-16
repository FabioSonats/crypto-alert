import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../utils/store_config.dart';
import '../utils/config.dart';

/// Serviço para gerenciar assinaturas in-app
///
/// Utiliza o SDK nativo in_app_purchase para comunicação com as lojas
class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Subscription _subscription = const Subscription.free();
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<ProductDetails> _products = [];

  /// Assinatura atual do usuário
  Subscription get subscription => _subscription;

  /// Se a loja está disponível
  bool get isAvailable => _isAvailable;

  /// Se está carregando
  bool get isLoading => _isLoading;

  /// Mensagem de erro (se houver)
  String? get errorMessage => _errorMessage;

  /// Produtos disponíveis para compra
  List<ProductDetails> get products => _products;

  /// Atalhos para verificar status
  bool get isPremium => _subscription.isPremium && _subscription.isActive;
  bool get showAds => !isPremium;

  /// Retorna o intervalo de atualização (10s para todos)
  int get updateInterval => Config.defaultUpdateInterval;

  /// Retorna o máximo de alertas
  int get maxAlerts => Config.maxAlerts;

  /// Retorna as moedas disponíveis
  List<String> get availableCoins => Config.supportedCoins;

  /// Inicializa o serviço de assinaturas
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Carrega assinatura salva localmente
      await _loadSavedSubscription();

      // Verifica se a loja está disponível
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        debugPrint('Loja não disponível');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Configura listener para compras
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (error) {
          debugPrint('Erro no stream de compras: $error');
          _errorMessage = 'Erro ao processar compra';
          notifyListeners();
        },
      );

      // Carrega produtos disponíveis
      await _loadProducts();

      _errorMessage = null;
    } catch (e) {
      debugPrint('Erro ao inicializar SubscriptionService: $e');
      _errorMessage = 'Erro ao inicializar loja';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega os produtos da loja
  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails(
      StoreConfig.productIds,
    );

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Produtos não encontrados: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('Erro ao carregar produtos: ${response.error}');
      _errorMessage = 'Erro ao carregar produtos';
      return;
    }

    _products = response.productDetails;
    debugPrint('Produtos carregados: ${_products.length}');
  }

  /// Processa atualizações de compras
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  /// Processa uma compra individual
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('Status da compra: ${purchaseDetails.status}');

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        _isLoading = true;
        notifyListeners();
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verifica e ativa a assinatura
        final valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _activatePremium(purchaseDetails);
        }

        // Completa a compra
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        _isLoading = false;
        notifyListeners();
        break;

      case PurchaseStatus.error:
        debugPrint('Erro na compra: ${purchaseDetails.error}');
        _errorMessage = 'Erro ao processar compra';
        _isLoading = false;
        notifyListeners();
        break;

      case PurchaseStatus.canceled:
        debugPrint('Compra cancelada');
        _isLoading = false;
        notifyListeners();
        break;
    }
  }

  /// Verifica se a compra é válida
  /// Em produção, deve verificar com servidor backend
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Em produção, verificar recibo com servidor backend
    // Por enquanto, aceita todas as compras
    return true;
  }

  /// Ativa a assinatura premium
  Future<void> _activatePremium(PurchaseDetails purchaseDetails) async {
    // Calcula data de expiração (1 mês ou 1 ano)
    final now = DateTime.now();
    final isYearly =
        purchaseDetails.productID == StoreConfig.yearlySubscriptionId;
    final expiresAt = isYearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    _subscription = Subscription(
      tier: SubscriptionTier.premium,
      expiresAt: expiresAt,
      productId: purchaseDetails.productID,
    );

    await _saveSubscription();
    notifyListeners();

    debugPrint('Premium ativado até: $expiresAt');
  }

  /// Inicia uma compra
  Future<void> buySubscription(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Produto não encontrado'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Para assinaturas, usar buyNonConsumable
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Erro ao iniciar compra: $e');
      _errorMessage = 'Erro ao iniciar compra';
      notifyListeners();
    }
  }

  /// Restaura compras anteriores
  Future<void> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Erro ao restaurar compras: $e');
      _errorMessage = 'Erro ao restaurar compras';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva a assinatura localmente
  Future<void> _saveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_subscription.toJson());
    await prefs.setString('subscription', json);
  }

  /// Carrega a assinatura salva
  Future<void> _loadSavedSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('subscription');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _subscription = Subscription.fromJson(data);

        // Verifica se expirou
        if (!_subscription.isActive) {
          _subscription = const Subscription.free();
          await _saveSubscription();
        }
      } catch (e) {
        debugPrint('Erro ao carregar assinatura: $e');
        _subscription = const Subscription.free();
      }
    }
  }

  /// Para uso em desenvolvimento - ativa premium temporariamente
  void debugActivatePremium() {
    if (kDebugMode) {
      _subscription = Subscription(
        tier: SubscriptionTier.premium,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        productId: 'debug_premium',
      );
      notifyListeners();
    }
  }

  /// Para uso em desenvolvimento - desativa premium
  void debugDeactivatePremium() {
    if (kDebugMode) {
      _subscription = const Subscription.free();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
