import 'package:flutter/foundation.dart';

class AppEvents {
  AppEvents._();

  /// Fired whenever an offer is successfully redeemed so that screens like
  /// ProfileScreen and RedeemHistoryScreen can immediately refresh.
  static final ValueNotifier<int> offerRedeemedNotifier = ValueNotifier<int>(0);

  static void notifyOfferRedeemed() {
    offerRedeemedNotifier.value++;
  }
}

