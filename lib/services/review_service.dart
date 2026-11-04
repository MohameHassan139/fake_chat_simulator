import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a Play rating once the user is happy: after the 3rd saved
/// screenshot, then again after the 15th (Google itself limits how often the
/// dialog really shows). Better ratings bring more installs from the store.
class ReviewService {
  static final ReviewService instance = ReviewService._();
  ReviewService._();

  static const String _key = 'saved_screenshots';
  static const List<int> askAt = [3, 15];

  /// Counts a saved screenshot. Returns true when the rating dialog was asked
  /// for, so no ad is shown on top of it.
  Future<bool> afterSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = (prefs.getInt(_key) ?? 0) + 1;
      await prefs.setInt(_key, saves);
      if (!askAt.contains(saves)) return false;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      return true;
    } catch (e) {
      debugPrint('ReviewService: $e');
      return false;
    }
  }
}
