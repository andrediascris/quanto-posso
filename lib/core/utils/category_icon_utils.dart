import 'package:flutter/material.dart';

class CategoryIconUtils {
  CategoryIconUtils._();

  static const _supportedIcons = <IconData>[
    Icons.restaurant_rounded,
    Icons.shopping_cart_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.water_drop_rounded,
    Icons.lightbulb_rounded,
    Icons.wifi_rounded,
    Icons.health_and_safety_rounded,
    Icons.sports_esports_rounded,
    Icons.credit_card_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.checkroom_rounded,
    Icons.phone_android_rounded,
    Icons.receipt_long_rounded,
    Icons.work_rounded,
    Icons.child_care_rounded,
    Icons.build_rounded,
    Icons.more_horiz_rounded,
    Icons.category_rounded,
  ];

  static IconData resolve(int codePoint) {
    for (final icon in _supportedIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category_rounded;
  }
}
