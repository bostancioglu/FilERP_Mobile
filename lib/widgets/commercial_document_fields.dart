import 'package:flutter/material.dart';
import '../helpers/stokhareket_couples.dart';

const deliveryTypes = <int, String>{
  1: 'Nakliye Satıcı',
  2: 'Nakliye Alıcı',
  3: 'Kargo',
  4: 'Kendi Aracımızla Teslim',
  5: 'İşyerinden Teslim',
  6: 'Diğer'
};
const tradeTypes = <int, String>{
  1: 'FOB',
  2: 'CIF',
  3: 'CF',
  4: 'FOT',
  5: 'İhraç Kayıtlı',
  6: 'DAF',
  7: 'EXW',
  8: 'İhracat Kur Farkı',
  9: 'CIP',
  10: 'CPT',
  11: 'DAT',
  12: 'DAP',
  13: 'DDP',
  14: 'DAS',
  15: 'DEQ',
  16: 'DDU',
  17: 'FCA',
  18: 'FAS',
  19: 'CFR',
  20: 'DPU'
};

class CommercialDocumentFields extends StatelessWidget {
  final int? deliveryType, documentType, tradeType, groupNumber, linkType;
  final String? referenceNumber;
  final bool sales, quote, enabled, linked, linkLocked;
  final ValueChanged<int?> onDelivery, onTrade;
  final ValueChanged<String> onReference;
  final ValueChanged<int?>? onDocumentType, onGroupNumber, onLinkType;
  final ValueChanged<bool>? onLinked;
  const CommercialDocumentFields(
      {super.key,
      required this.sales,
      required this.quote,
      this.enabled = true,
      this.deliveryType,
      this.documentType,
      this.tradeType,
      this.referenceNumber,
      this.groupNumber,
      this.linked = false,
      this.linkLocked = false,
      this.linkType,
      required this.onDelivery,
      required this.onTrade,
      required this.onReference,
      this.onDocumentType,
      this.onGroupNumber,
      this.onLinked,
      this.onLinkType});
  @override
  Widget build(BuildContext context) {
    Widget select(String label, int? value, Map<int, String> values,
            ValueChanged<int?>? change) =>
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int>(
                key: ValueKey('commercial-$label'),
                initialValue: values.containsKey(value) ? value : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: label),
                items: values.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: enabled ? change : null));
    return Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Teslimat ve Diğer Bilgiler',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            children: [
              select('Teslimat Tipi', deliveryType, deliveryTypes, onDelivery),
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                      initialValue: referenceNumber,
                      readOnly: !enabled,
                      maxLength: 50,
                      decoration: const InputDecoration(
                          labelText: 'Referans Belge No', counterText: ''),
                      onChanged: onReference)),
              if (quote)
                select(
                    'Belge Tipi',
                    documentType,
                    {
                      for (final item in StokHareketCouples.belgeTipleri)
                        item.value: item.text
                    },
                    onDocumentType),
              if (quote && (documentType == 5 || documentType == 6))
                select(
                    'İthalat / İhracat Tipi', tradeType, tradeTypes, onTrade),
              if (quote && !sales)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                        initialValue: groupNumber?.toString(),
                        readOnly: !enabled,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Grup No'),
                        onChanged: (v) =>
                            onGroupNumber?.call(int.tryParse(v)))),
              if (!quote)
                SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Bağlantı Siparişi'),
                    value: linked,
                    onChanged: enabled && !linkLocked ? onLinked : null),
              if (!quote && linked && !sales)
                select('Bağlantı Türü', linkType, {1: 'Bağlantı', 2: 'Taahhüt'},
                    linkLocked ? null : onLinkType),
            ]));
  }
}
