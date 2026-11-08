import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/yonetim/masraf_service.dart';
import '../services/plasiyer/plasiyer_service.dart';
import '../services/muhasebe/hesapplani_service.dart';
import '../helpers/number_format_helper.dart';
import 'erp_record_fields.dart';

const expenseField = RecordField(
    'Islemmasrafid', 'Masraf', RecordFieldType.lookup,
    lookup: 'expense', required: true);
const cashSalespersonFields = [
  RecordField('Plasiyerkasasi', 'Plasiyer Kasası', RecordFieldType.flag),
  RecordField('Plasiyerid', 'Plasiyer', RecordFieldType.lookup,
      lookup: 'salesperson', required: true),
];
const bankAccountExtraFields = [
  RecordField('Faizhesapplaniid', 'Faiz Hesabı', RecordFieldType.lookup,
      lookup: 'account'),
  RecordField('Kkdfhesapplaniid', 'KKDF Hesabı', RecordFieldType.lookup,
      lookup: 'account'),
  RecordField('Cezahesapplaniid', 'Ceza Hesabı', RecordFieldType.lookup,
      lookup: 'account'),
];
Future<List<RecordChoice>> financeFieldChoices(String type) async {
  final token =
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';
  if (type == 'expense')
    return (await MasrafService().getAll(token))
        .where((r) => r.id != null)
        .map((r) =>
            RecordChoice(r.id!, [r.kod, r.ad].whereType<String>().join(' · ')))
        .toList();
  if (type == 'salesperson')
    return (await PlasiyerService().getPlasiyerler(token))
        .where((r) => r.Id != null)
        .map((r) => RecordChoice(r.Id!, r.Adsoyad ?? ''))
        .toList();
  return (await HesapplaniService().getForSelection(token))
      .where((r) => r.id != null)
      .map((r) =>
          RecordChoice(r.id!, [r.kod, r.ad].whereType<String>().join(' · ')))
      .toList();
}

const bankChargePairs = {
  'Faiz': 'Faizdoviz',
  'Kkdf': 'Kkdfdoviz',
  'Bsmv': 'Dovizbsmv',
  'Komisyon': 'Dovizkomisyon',
  'Ceza': 'Cezadoviz',
  'Digerucretler': 'Dovizdigerucretler',
};
const bankChargeLabels = {
  'Faiz': 'Faiz',
  'Kkdf': 'KKDF',
  'Bsmv': 'BSMV',
  'Komisyon': 'Komisyon',
  'Ceza': 'Ceza',
  'Digerucretler': 'Diğer Ücretler'
};

class BankChargesController extends RecordFieldsController {
  bool foreign = false;
  double rate = 0;
  BankChargesController({Map<String, dynamic> initial = const {}})
      : super([
          for (final p in bankChargePairs.entries) ...[
            RecordField(p.key, bankChargeLabels[p.key]!, RecordFieldType.number,
                minimum: 0),
            RecordField(
                p.value,
                p.key == 'Digerucretler'
                    ? 'Döviz Diğer'
                    : 'Döviz ${bankChargeLabels[p.key]}',
                RecordFieldType.number,
                minimum: 0),
          ],
        ], initial: initial) {
    for (final pair in bankChargePairs.entries) {
      text[pair.value]!.addListener(() => _convert(pair.key, pair.value));
    }
  }
  void _convert(String local, String fx) {
    if (foreign && rate > 0 && text[fx]!.text.trim().isNotEmpty) {
      text[local]!.text = (NumberFormatHelper.parse(text[fx]!.text) * rate)
          .toString()
          .replaceAll('.', ',');
    }
  }

  void currency(bool isForeign, double currentRate, {bool reprice = true}) {
    foreign = isForeign;
    rate = currentRate;
    if (reprice) {
      for (final pair in bankChargePairs.entries) {
        _convert(pair.key, pair.value);
      }
    }
  }

  double amount(String key, {required bool outgoing, bool fx = false}) =>
      outgoing && (!fx || foreign)
          ? NumberFormatHelper.parse(text[key]!.text)
          : 0;
}

class BankChargesSection extends StatelessWidget {
  final BankChargesController controller;
  final bool foreign;
  const BankChargesSection(
      {super.key, required this.controller, required this.foreign});
  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
          key: const ValueKey('bank-charges'),
          maintainState: true,
          title: const Text('Faiz ve Masraflar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  for (final p in bankChargePairs.entries)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (foreign) ...[
                            Expanded(child: _field(p.value)),
                            const SizedBox(width: 10)
                          ],
                          Expanded(child: _field(p.key)),
                        ]),
                ]))
          ]));
  Widget _field(String key) => ErpRecordFields(
      controller: controller,
      fields: controller.fields.where((f) => f.key == key).toList(),
      lookup: financeFieldChoices,
      prefix: 'bank-charge');
}
