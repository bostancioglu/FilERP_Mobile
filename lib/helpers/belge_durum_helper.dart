import 'package:flutter/material.dart';

class BelgeDurumHelper {
  /// BelgeDurum:
  /// 0 = Taslak
  /// 1 = Tamamlandı
  static String adById(int? belgeDurum) {
    switch (belgeDurum) {
      case 0:
        return "Taslak";
      case 1:
        return "Tamamlandı";
      default:
        return "-";
    }
  }

  static Color renkById(int? belgeDurum) {
    switch (belgeDurum) {
      case 0:
        return Colors.orange; // Taslak
      case 1:
        return Colors.green; // Tamamlandı
      default:
        return Colors.grey;
    }
  }

  static Color arkaPlanById(int? belgeDurum) {
    switch (belgeDurum) {
      case 0:
        return Colors.orange.shade50;
      case 1:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade200;
    }
  }
}
