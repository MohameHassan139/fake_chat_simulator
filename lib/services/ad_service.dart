import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob for Fake Chat: a small banner on the dashboard only (never on the chat
/// screen, so screenshots stay clean) and an interstitial after a saved
/// screenshot, at most every 2nd save and 2 minutes apart.
///
/// Real AdMob ids (app ca-app-pub-2509095132117735~9332794603). Debug builds
/// always get Google's TEST ids: tapping real ads on our own phones counts as
/// invalid traffic and can close the AdMob account.
class AdIds {
  static const bool useTestAds = kDebugMode;

  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  static const String _banner = 'ca-app-pub-2509095132117735/2090114233';
  static const String _interstitial = 'ca-app-pub-2509095132117735/8220583328';

  static String get banner => useTestAds ? _testBanner : _banner;
  static String get interstitial => useTestAds ? _testInterstitial : _interstitial;
}

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  static const int savesPerAd = 2;
  static const Duration minGap = Duration(minutes: 2);

  bool _ready = false;
  InterstitialAd? _interstitial;
  int _saves = 0;
  DateTime? _lastShown;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Ask for consent where the law needs it (EEA/UK), then start the SDK.
  /// Never blocks the app: called without await from main().
  Future<void> init() async {
    if (!supported) return;
    try {
      await _consent();
      final info = ConsentInformation.instance;
      if (!await info.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService.init failed: $e');
    }
  }

  Future<void> _consent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('Consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  bool get ready => _ready;

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitial = null;
        },
      ),
    );
  }

  /// Called after a screenshot was saved: shows an ad every [savesPerAd]
  /// saves, never twice within [minGap].
  void afterSave() {
    _saves++;
    final ad = _interstitial;
    final now = DateTime.now();
    final tooSoon = _lastShown != null && now.difference(_lastShown!) < minGap;
    if (ad == null || _saves % savesPerAd != 0 || tooSoon) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _interstitial = null;
    _lastShown = now;
    ad.show();
  }
}

/// A standard banner that takes no space until an ad has loaded.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _tryLoad();
  }

  void _tryLoad() {
    if (!AdService.supported) return;
    if (!AdService.instance.ready) {                 // consent and the SDK start in the background
      _wait = Timer(const Duration(seconds: 2), _tryLoad);
      return;
    }
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _wait?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
