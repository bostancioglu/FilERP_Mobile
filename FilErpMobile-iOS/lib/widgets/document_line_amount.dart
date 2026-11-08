import 'package:flutter/material.dart';

/// Keeps a document line's amount and currency together on narrow screens.
class DocumentLineAmount extends StatelessWidget {
  const DocumentLineAmount({
    super.key,
    required this.amount,
    required this.currency,
    required this.color,
    required this.currencyColor,
  });

  final String amount;
  final String currency;
  final Color color;
  final Color currencyColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            text: amount,
            children: [
              TextSpan(
                text: ' $currency',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: currencyColor,
                ),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
