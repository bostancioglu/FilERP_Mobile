import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/ui_feedback.dart';
import '../../models/entities/cari/cari_extra_fields.dart';
import '../../models/entities/cari/cari_dto.dart';
import '../../models/entities/helper/banka_master_dto.dart';
import '../../models/entities/muhasebe/hesapplani_dto.dart';
import '../../services/cari/cari_service.dart';
import '../../services/helper/banka_master_service.dart';
import '../../services/muhasebe/hesapplani_service.dart';
import '../erp_selector.dart';

class CariExtraController extends ChangeNotifier {
  final text = {
    for (final key in cariExtraTextFields.keys) key: TextEditingController()
  };
  final Map<String, dynamic> _values = {
    for (final key in cariExtraIdFields.keys) key: null,
    for (final key in cariExtraBoolFields.keys) key: false
  };
  final Map<String, String> labels = {};
  void load(CariDto customer) {
    final json = customer.toJson();
    for (final entry in text.entries) {
      entry.value.text = json[entry.key]?.toString() ?? '';
    }
    for (final key in _values.keys.toList()) {
      _values[key] = json[key];
    }
    labels
      ..clear()
      ..addAll(customer.selectionLabels);
  }

  int? id(String key) => _values[key] as int?;
  bool flag(String key) => _values[key] == true;
  void setFlag(String key, bool value) {
    _values[key] = value;
    notifyListeners();
  }

  void select(String key, int? value, String? label) {
    if (key == 'Bankaid' && value != id(key)) {
      _values['Bankasubeid'] = null;
      labels.remove('Bankasubeid');
    }
    _values[key] = value;
    if (label == null) {
      labels.remove(key);
    } else {
      labels[key] = label;
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        ..._values,
        for (final entry in text.entries)
          entry.key: entry.value.text.trim().isEmpty
              ? null
              : (entry.key == 'Iban' || entry.key == 'Efaturaiban'
                  ? entry.value.text.replaceAll(RegExp(r'\s'), '').toUpperCase()
                  : entry.value.text.trim()),
      };
  @override
  void dispose() {
    for (final ctrl in text.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
}

enum CariExtraSection {
  bank,
  electronic,
  accounts,
  relations,
  corporate,
  contact,
  sharedCodes
}

class CariExtraSections extends StatelessWidget {
  final CariExtraController controller;
  final CariExtraSection section;
  final int? customerId;
  const CariExtraSections(
      {super.key,
      required this.controller,
      required this.section,
      this.customerId});
  Future<String> _token() async =>
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';
  Future<void> _pick(BuildContext context, String key) async {
    try {
      final token = await _token();
      if (!context.mounted) return;
      final title = cariExtraIdFields[key]!;
      if (key == 'Bankaid') {
        final rows = await BankaMasterService().getBankalar(token);
        if (!context.mounted) return;
        final row = await showErpSelector<BankaMasterDto>(
            context: context,
            title: title,
            hintText: title,
            items: rows,
            itemText: (e) => [e.Kod, e.Ad].whereType<String>().join(' · '));
        if (row != null && context.mounted)
          controller.select(
              key, row.Id, [row.Kod, row.Ad].whereType<String>().join(' · '));
      } else if (key == 'Bankasubeid') {
        final bankId = controller.id('Bankaid');
        if (bankId == null) return;
        final rows =
            await BankaMasterService().getSubeler(token, bankaid: bankId);
        if (!context.mounted || controller.id('Bankaid') != bankId) return;
        final row = await showErpSelector<BankasubeMasterDto>(
            context: context,
            title: title,
            hintText: title,
            items: rows.where((e) => e.Bankaid == bankId).toList(),
            itemText: (e) => [e.Kod, e.Ad].whereType<String>().join(' · '));
        if (row != null &&
            context.mounted &&
            controller.id('Bankaid') == bankId)
          controller.select(
              key, row.Id, [row.Kod, row.Ad].whereType<String>().join(' · '));
      } else if (key == 'Baglicariid' || key == 'Komisyoncucariid') {
        final rows = await CariService().getCariList(token);
        if (!context.mounted) return;
        final row = await showErpSelector<CariDto>(
            context: context,
            title: title,
            hintText: title,
            items: rows.where((e) => e.Id != customerId).toList(),
            itemText: (e) => [e.Kod, e.Ad].whereType<String>().join(' · '));
        if (row != null && context.mounted)
          controller.select(
              key, row.Id, [row.Kod, row.Ad].whereType<String>().join(' · '));
      } else {
        final rows = await HesapplaniService().getForSelection(token);
        if (!context.mounted) return;
        final row = await showErpSelector<HesapplaniDto>(
            context: context,
            title: title,
            hintText: title,
            items: rows,
            itemText: (e) => [e.kod, e.ad].whereType<String>().join(' · '));
        if (row != null && context.mounted)
          controller.select(
              key, row.id, [row.kod, row.ad].whereType<String>().join(' · '));
      }
    } catch (e) {
      if (context.mounted) UiFeedback.showException(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget text(String key) => TextFormField(
        key: ValueKey('cari-extra-$key'),
        controller: controller.text[key],
        keyboardType: key.toLowerCase().contains('email')
            ? TextInputType.emailAddress
            : (key.contains('tel') ||
                    key.contains('mobil') ||
                    key.contains('fax'))
                ? TextInputType.phone
                : key == 'Kurumsalweb'
                    ? TextInputType.url
                    : TextInputType.text,
        decoration: InputDecoration(labelText: cariExtraTextFields[key]));
    Widget flag(String key) => SwitchListTile.adaptive(
        key: ValueKey('cari-extra-$key'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(cariExtraBoolFields[key]!,
            style: const TextStyle(fontSize: 13)),
        value: controller.flag(key),
        onChanged: (v) => controller.setFlag(key, v));
    Widget select(String key) {
      final enabled = key != 'Bankasubeid' || controller.id('Bankaid') != null;
      final id = controller.id(key);
      final label = cariExtraIdFields[key]!;
      return InkWell(
          key: ValueKey('cari-extra-$key'),
          onTap: enabled ? () => _pick(context, key) : null,
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: label,
                  enabled: enabled,
                  suffixIcon: id == null
                      ? const Icon(Icons.expand_more_rounded)
                      : IconButton(
                          tooltip: '$label temizle',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => controller.select(key, null, null))),
              child: Text(
                  id == null ? '' : controller.labels[key] ?? '$label seçili',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)));
    }

    late String title;
    late IconData icon;
    late List<Widget> fields;
    switch (section) {
      case CariExtraSection.bank:
        title = 'Banka Bilgileri';
        icon = Icons.account_balance_outlined;
        fields = [
          select('Bankaid'),
          select('Bankasubeid'),
          text('Hesapno'),
          text('Iban'),
          text('Bankaaciklama')
        ];
      case CariExtraSection.electronic:
        title = 'E-Belge Bilgileri';
        icon = Icons.receipt_long_outlined;
        fields = [
          flag('Efaturamukkellefi'),
          text('Efaturaalias'),
          flag('Eirsaliyemukkellefi'),
          text('Eirsaliyealias'),
          text('Efaturaiban')
        ];
      case CariExtraSection.accounts:
        title = 'Muhasebe Hesapları';
        icon = Icons.account_tree_outlined;
        fields = [
          select('Hesapplaniid'),
          select('Kurfarkigelirhesapplaniid'),
          select('Kurfarkigiderhesapplaniid')
        ];
      case CariExtraSection.relations:
        title = 'Risk ve Cari İlişkileri';
        icon = Icons.link_rounded;
        fields = [
          flag('Riskkontroluvar'),
          flag('Plasiyerortak'),
          text('Kosulkodu'),
          text('Vat'),
          select('Baglicariid'),
          select('Komisyoncucariid')
        ];
      case CariExtraSection.corporate:
        title = 'Kurumsal İletişim';
        icon = Icons.business_outlined;
        fields = [
          text('Kurumsalfax'),
          text('Kurumsalmobil'),
          text('Kurumsalweb'),
          text('Kurumsalemail')
        ];
      case CariExtraSection.contact:
        title = 'Yetkili Bilgileri';
        icon = Icons.person_outline_rounded;
        fields = [
          text('Yetkiliunvan'),
          text('Yetkiliad'),
          text('Yetkilitel'),
          text('Yetkiliemail')
        ];
      case CariExtraSection.sharedCodes:
        title = 'Ortak Kodlar';
        icon = Icons.tag_rounded;
        fields = [
          flag('Ortakkoduvar'),
          if (controller.flag('Ortakkoduvar')) ...[
            text('Ortakkod'),
            text('Muhasebeortakkod')
          ]
        ];
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
        decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .45))),
        child: Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
                key: ValueKey('cari-section-${section.name}'),
                maintainState: true,
                leading: Icon(icon, size: 20),
                title: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                children: [
                  for (final field in fields)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: field)
                ])));
  }
}
