import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Serviço para gerenciar anúncios do Google AdMob
///
/// Gerencia Banner Ads e Interstitial Ads
class AdService {
  static AdService? _instance;

  /// Singleton instance
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  AdService._();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;

  /// Se o SDK foi inicializado
  bool get isInitialized => _isInitialized;

  /// Se o banner está carregado
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// Se o interstitial está carregado
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  /// Banner Ad carregado (pode ser null)
  BannerAd? get bannerAd => _bannerAd;

  // ============================================
  // IDs de Anúncio (Teste)
  // ============================================

  /// ID do Banner para teste
  String get _bannerAdUnitId {
    if (kDebugMode) {
      // IDs de teste do Google
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }
    // TODO: Substituir por IDs reais de produção
    if (Platform.isAndroid) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return '';
  }

  /// ID do Interstitial para teste
  String get _interstitialAdUnitId {
    if (kDebugMode) {
      // IDs de teste do Google
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }
    // TODO: Substituir por IDs reais de produção
    if (Platform.isAndroid) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return '';
  }

  // ============================================
  // Inicialização
  // ============================================

  /// Inicializa o SDK de anúncios
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob inicializado com sucesso');

      // Pré-carrega os anúncios
      await loadBannerAd();
      await loadInterstitialAd();
    } catch (e) {
      debugPrint('Erro ao inicializar AdMob: $e');
    }
  }

  // ============================================
  // Banner Ad
  // ============================================

  /// Carrega um Banner Ad
  Future<void> loadBannerAd() async {
    if (!_isInitialized) {
      debugPrint('AdMob não inicializado');
      return;
    }

    // Dispõe o banner anterior se existir
    await _bannerAd?.dispose();
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner Ad carregado');
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner Ad falhou ao carregar: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
        },
        onAdOpened: (ad) => debugPrint('Banner Ad aberto'),
        onAdClosed: (ad) => debugPrint('Banner Ad fechado'),
        onAdImpression: (ad) => debugPrint('Banner Ad impressão'),
      ),
    );

    await _bannerAd!.load();
  }

  /// Dispõe o Banner Ad
  Future<void> disposeBannerAd() async {
    await _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // ============================================
  // Interstitial Ad
  // ============================================

  /// Carrega um Interstitial Ad
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) {
      debugPrint('AdMob não inicializado');
      return;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial Ad carregado');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          // Configura callbacks
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial Ad fechado');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Pré-carrega o próximo
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial Ad falhou ao exibir: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial Ad falhou ao carregar: ${error.message}');
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  /// Exibe o Interstitial Ad se estiver carregado
  /// Retorna true se o anúncio foi exibido
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('Interstitial Ad não está pronto');
      // Tenta carregar para a próxima vez
      loadInterstitialAd();
      return false;
    }

    await _interstitialAd!.show();
    return true;
  }

  /// Dispõe o Interstitial Ad
  Future<void> disposeInterstitialAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  // ============================================
  // Limpeza
  // ============================================

  /// Dispõe todos os anúncios
  Future<void> dispose() async {
    await disposeBannerAd();
    await disposeInterstitialAd();
    _isInitialized = false;
  }
}
