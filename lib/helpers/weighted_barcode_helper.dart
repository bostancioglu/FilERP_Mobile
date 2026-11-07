import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class WeightedBarcodeData {
  final String rawBarcode;
  final String stockBarcode;
  final double quantity;
  final WeightedBarcodeRule rule;

  const WeightedBarcodeData({
    required this.rawBarcode,
    required this.stockBarcode,
    required this.quantity,
    required this.rule,
  });
}

class WeightedBarcodeRule {
  final String prefix;
  final int stockBarcodeLength;
  final int quantityLength;
  final int controlLength;
  final int quantityDecimalDigits;

  const WeightedBarcodeRule({
    required this.prefix,
    required this.stockBarcodeLength,
    required this.quantityLength,
    required this.controlLength,
    required this.quantityDecimalDigits,
  });

  int get totalLength => stockBarcodeLength + quantityLength + controlLength;

  Map<String, dynamic> toMap() => {
        'prefix': prefix,
        'stockBarcodeLength': stockBarcodeLength,
        'quantityLength': quantityLength,
        'controlLength': controlLength,
        'quantityDecimalDigits': quantityDecimalDigits,
      };

  factory WeightedBarcodeRule.fromMap(Map<String, dynamic> map) {
    return WeightedBarcodeRule(
      prefix: (map['prefix'] ?? '').toString().trim(),
      stockBarcodeLength: (map['stockBarcodeLength'] as num?)?.toInt() ?? 0,
      quantityLength: (map['quantityLength'] as num?)?.toInt() ?? 0,
      controlLength: (map['controlLength'] as num?)?.toInt() ?? 0,
      quantityDecimalDigits:
          (map['quantityDecimalDigits'] as num?)?.toInt() ?? 3,
    );
  }

  WeightedBarcodeRule copyWith({
    String? prefix,
    int? stockBarcodeLength,
    int? quantityLength,
    int? controlLength,
    int? quantityDecimalDigits,
  }) {
    return WeightedBarcodeRule(
      prefix: prefix ?? this.prefix,
      stockBarcodeLength: stockBarcodeLength ?? this.stockBarcodeLength,
      quantityLength: quantityLength ?? this.quantityLength,
      controlLength: controlLength ?? this.controlLength,
      quantityDecimalDigits:
          quantityDecimalDigits ?? this.quantityDecimalDigits,
    );
  }

  bool get isValid =>
      prefix.isNotEmpty &&
      stockBarcodeLength > 0 &&
      quantityLength > 0 &&
      controlLength >= 0 &&
      quantityDecimalDigits >= 0 &&
      stockBarcodeLength >= prefix.length;

  String get summary =>
      '$prefix | stok:$stockBarcodeLength miktar:$quantityLength '
      'kontrol:$controlLength ondalik:$quantityDecimalDigits';
}

class WeightedBarcodeHelper {
  const WeightedBarcodeHelper._();

  static const _prefsKey = 'weighted_barcode_rules_v1';

  static const List<WeightedBarcodeRule> _defaultRules = [
    WeightedBarcodeRule(
      prefix: '27',
      stockBarcodeLength: 6,
      quantityLength: 5,
      controlLength: 2,
      quantityDecimalDigits: 3,
    ),
    WeightedBarcodeRule(
      prefix: '29',
      stockBarcodeLength: 6,
      quantityLength: 5,
      controlLength: 2,
      quantityDecimalDigits: 3,
    ),
  ];

  static List<WeightedBarcodeRule> _cachedRules = List.of(_defaultRules);
  static bool _loaded = false;

  static List<WeightedBarcodeRule> get defaultRules => List.of(_defaultRules);

  static List<WeightedBarcodeRule> getCachedRules() => List.of(_cachedRules);

  static void setCachedRules(List<WeightedBarcodeRule> rules) {
    final normalized = _normalizeRules(rules);
    _cachedRules = normalized.isEmpty ? List.of(_defaultRules) : normalized;
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _cachedRules = List.of(_defaultRules);
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final rules = decoded
            .whereType<Map>()
            .map((e) => WeightedBarcodeRule.fromMap(
                Map<String, dynamic>.from(e.cast<String, dynamic>())))
            .toList();
        setCachedRules(rules);
        return;
      }
    } catch (_) {}

    _cachedRules = List.of(_defaultRules);
    _loaded = true;
  }

  static Future<void> saveRules(List<WeightedBarcodeRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeRules(rules);
    await prefs.setString(
      _prefsKey,
      jsonEncode(normalized.map((e) => e.toMap()).toList()),
    );
    _cachedRules = normalized.isEmpty ? List.of(_defaultRules) : normalized;
    _loaded = true;
  }

  static Future<void> resetRules() => saveRules(_defaultRules);

  static List<WeightedBarcodeRule> _normalizeRules(
    List<WeightedBarcodeRule> rules,
  ) {
    return rules
        .map((e) => e.copyWith(prefix: e.prefix.trim()))
        .where((e) => e.isValid)
        .toList()
      ..sort((a, b) {
        final prefixCompare = b.prefix.length.compareTo(a.prefix.length);
        if (prefixCompare != 0) {
          return prefixCompare;
        }
        return a.prefix.compareTo(b.prefix);
      });
  }

  static WeightedBarcodeData? tryParse(
    String raw, {
    List<WeightedBarcodeRule>? rules,
  }) {
    final barcode = raw.trim();
    if (barcode.isEmpty || !RegExp(r'^\d+$').hasMatch(barcode)) {
      return null;
    }

    final activeRules = _normalizeRules(rules ?? _cachedRules);
    for (final rule in activeRules) {
      if (!barcode.startsWith(rule.prefix)) {
        continue;
      }
      if (barcode.length != rule.totalLength) {
        continue;
      }

      final stockBarcode = barcode.substring(0, rule.stockBarcodeLength);
      final quantityEnd = rule.stockBarcodeLength + rule.quantityLength;
      final quantityText =
          barcode.substring(rule.stockBarcodeLength, quantityEnd);
      final quantityValue = int.tryParse(quantityText);
      if (quantityValue == null || quantityValue <= 0) {
        continue;
      }

      final divisor = math.pow(10, rule.quantityDecimalDigits).toDouble();
      return WeightedBarcodeData(
        rawBarcode: barcode,
        stockBarcode: stockBarcode,
        quantity: quantityValue / divisor,
        rule: rule,
      );
    }
    return null;
  }
}
