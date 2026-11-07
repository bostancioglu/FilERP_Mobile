import 'package:intl/intl.dart';

class NumberFormatHelper {
  /// double → "1.250,53"
  /// HER ZAMAN 2 ondalık gösterir
  static String format(double? value, {int decimal = 2}) {
    if (value == null) return _zero(decimal);

    final format = NumberFormat(
      "#,##0.${'0' * decimal}", // 🔥 ZORUNLU 0
      "tr_TR",
    );

    return format.format(value);
  }

  /// "1.250,53" → 1250.53
  static double parse(String input) {
    if (input.trim().isEmpty) return 0;

    return double.tryParse(
          input
              .replaceAll('.', '')   // binlik ayırıcı
              .replaceAll(',', '.'), // ondalık ayırıcı
        ) ??
        0;
  }

  static String _zero(int decimal) {
    return "0,${'0' * decimal}";
  }
}
