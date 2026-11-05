import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_service.dart';

/// One-time "Remove ads" purchase (Play Console > Monetize > In-app products,
/// product id [productId]). Bought once, it turns every ad off and opens the
/// premium features for good; "Restore" brings it back on a new phone.
class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  static const String productId = 'remove_ads';
  static const String _key = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  /// The store price ("$1.99", "٤٩٫٩٩ ج.م."), null until the store answered.
  final ValueNotifier<String?> price = ValueNotifier(null);

  /// Called before the ads start, so a buyer never sees one.
  Future<void> init() async {
    if (!AdService.supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      AdService.instance.setAdsRemoved(prefs.getBool(_key) ?? false);
      unawaited(_connect());                         // the store may be slow: never hold the ads back
    } catch (e) {
      debugPrint('PurchaseService.init failed: $e');
    }
  }

  Future<void> _connect() async {
    try {
      if (!await _iap.isAvailable()) return;
      _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (e) => debugPrint('IAP: $e'));
      final res = await _iap.queryProductDetails({productId});
      if (res.productDetails.isNotEmpty) {
        _product = res.productDetails.first;
        price.value = _product!.price;
      }
    } catch (e) {
      debugPrint('PurchaseService store: $e');
    }
  }

  bool get canBuy => _product != null;

  Future<bool> buy() async {
    final product = _product;
    if (product == null) return false;
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_key, true);
        AdService.instance.setAdsRemoved(true);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }
}
