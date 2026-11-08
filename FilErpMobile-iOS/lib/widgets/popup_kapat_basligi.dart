import 'package:flutter/material.dart';

/// DropdownSearch alt sayfalarında (cari/plasiyer/proje/hesap rehberleri)
/// seçim yapmadan çıkabilmek için sağ üstte ✕ gösteren başlık.
class PopupKapatBasligi extends StatelessWidget {
  const PopupKapatBasligi({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Kapat',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
