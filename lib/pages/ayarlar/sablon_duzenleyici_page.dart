import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../models/yazici/yazici_sablon.dart';
import '../../services/yazici/yazici_sablon_service.dart';

class SablonDuzenleyiciPage extends StatefulWidget {
  final YaziciSablon? editSablon;
  const SablonDuzenleyiciPage({super.key, this.editSablon});

  @override
  State<SablonDuzenleyiciPage> createState() => _SablonDuzenleyiciPageState();
}

class _SablonDuzenleyiciPageState extends State<SablonDuzenleyiciPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kRed => _scheme.primary;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;

  final _adCtrl = TextEditingController();
  final _svc = YaziciSablonService.instance;
  List<SablonSatir> _satirlar = [];
  bool _saving = false;

  bool get _isEdit => widget.editSablon != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _adCtrl.text = widget.editSablon!.ad;
      _satirlar = List.from(widget.editSablon!.satirlar);
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    super.dispose();
  }

  // ── Kaydet ──────────────────────────────────────────────────────────────────

  Future<void> _kaydet() async {
    final ad = _adCtrl.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Şablon adı boş olamaz'), backgroundColor: _kRed));
      return;
    }
    if (_satirlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('En az bir satır ekleyin'), backgroundColor: _kRed));
      return;
    }

    setState(() => _saving = true);
    final sablon = YaziciSablon(
      id: _isEdit
          ? widget.editSablon!.id
          : 'sablon_${DateTime.now().millisecondsSinceEpoch}',
      ad: ad,
      satirlar: List.from(_satirlar),
    );
    await _svc.addOrUpdate(sablon);
    if (mounted) Navigator.pop(context, true);
  }

  // ── Satır ekle bottom sheet ──────────────────────────────────────────────

  Future<void> _satirEkle() async {
    final satir = await showModalBottomSheet<SablonSatir>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SatirEkleSheet(),
    );
    if (satir != null) setState(() => _satirlar.add(satir));
  }

  Future<void> _satirDuzenle(int index) async {
    final satir = await showModalBottomSheet<SablonSatir>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SatirEkleSheet(editSatir: _satirlar[index]),
    );
    if (satir != null) setState(() => _satirlar[index] = satir);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        title: Text(_isEdit ? 'Şablonu Düzenle' : 'Yeni Şablon'),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      ),
      body: _saving
          ? Center(child: CircularProgressIndicator(color: _kRed))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // ── Şablon adı ──
                _sectionCard(
                  icon: Icons.label_outline_rounded,
                  title: 'Şablon Adı',
                  child: TextField(
                    controller: _adCtrl,
                    decoration: InputDecoration(
                      hintText: 'Şablon Adı',
                      filled: true,
                      fillColor: _scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: _scheme.outlineVariant)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: _scheme.outlineVariant)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _kRed, width: 1.5)),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // ── Satırlar ──
                _sectionCard(
                  icon: Icons.reorder_rounded,
                  title: 'Satırlar',
                  trailing: Text('${_satirlar.length} satır',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: _scheme.onSurfaceVariant)),
                  child: _satirlar.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('Henüz satır eklenmedi',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: _scheme.onSurfaceVariant,
                                    fontSize: 13)),
                          ),
                        )
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIdx, newIdx) {
                            setState(() {
                              if (newIdx > oldIdx) newIdx--;
                              final item = _satirlar.removeAt(oldIdx);
                              _satirlar.insert(newIdx, item);
                            });
                          },
                          itemCount: _satirlar.length,
                          itemBuilder: (_, i) {
                            final satir = _satirlar[i];
                            return _satirItem(satir, i, key: ValueKey(i));
                          },
                        ),
                ),

                SizedBox(height: 10),

                // ── Satır Ekle ──
                OutlinedButton.icon(
                  onPressed: _satirEkle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: BorderSide(color: _kRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text('Satır Ekle',
                      style: TextStyle(
                          fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: _scheme.surface,
          border: Border(top: BorderSide(color: _scheme.outlineVariant)),
        ),
        child: SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _kaydet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: _scheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            icon: Icon(Icons.save_outlined, size: 20),
            label: Text(_isEdit ? 'Güncelle' : 'Kaydet',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _satirItem(SablonSatir satir, int index, {required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _scheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Sürükle tutacağı
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle_rounded,
                color: _scheme.onSurfaceVariant, size: 20),
          ),
          SizedBox(width: 8),
          // Tip ikonu
          _tipIcon(satir.tip),
          SizedBox(width: 8),
          // İçerik
          Expanded(
            child: Text(
              satir.ozet,
              style:
                  TextStyle(fontFamily: 'Roboto', fontSize: 12, color: _kDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Düzenle
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 16, color: _scheme.onSurfaceVariant),
            onPressed: () => _satirDuzenle(index),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // Sil
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: _scheme.error),
            onPressed: () => setState(() => _satirlar.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _tipIcon(SatirTipi tip) {
    final (icon, color) = switch (tip) {
      SatirTipi.alan => (Icons.data_object_rounded, _scheme.primary),
      SatirTipi.metin => (Icons.text_fields_rounded, Colors.teal.shade600),
      SatirTipi.barkod => (Icons.qr_code_rounded, Colors.purple.shade600),
      SatirTipi.ayirici => (
          Icons.horizontal_rule_rounded,
          _scheme.onSurfaceVariant
        ),
      SatirTipi.bosluk => (Icons.space_bar_rounded, _scheme.onSurfaceVariant),
      SatirTipi.logo => (Icons.image_outlined, _scheme.primary),
    };
    return Icon(icon, size: 18, color: color);
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: _kRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: _kRed)),
                SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kDark)),
                Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, color: _scheme.surfaceContainerLow),
          Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 14), child: child),
        ],
      ),
    );
  }
}

// ── Satır Ekle / Düzenle Sheet ────────────────────────────────────────────────

class _SatirEkleSheet extends StatefulWidget {
  final SablonSatir? editSatir;
  const _SatirEkleSheet({this.editSatir});

  @override
  State<_SatirEkleSheet> createState() => _SatirEkleSheetState();
}

class _SatirEkleSheetState extends State<_SatirEkleSheet> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kRed => _scheme.primary;

  late SatirTipi _tip;
  late AlanKodu _alanKodu;
  late Hizalama _hizalama;
  late bool _kalin;
  late YaziBoyutu _boy;
  late String _ayiriciKar;
  late LogoBoyu _logoBoyu;
  final _metinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.editSatir;
    _tip = s?.tip ?? SatirTipi.alan;
    _alanKodu = s?.alanKodu ?? AlanKodu.stokAdi;
    _hizalama = s?.hizalama ?? Hizalama.sol;
    _kalin = s?.kalin ?? false;
    _boy = s?.boy ?? YaziBoyutu.normal;
    _ayiriciKar = s?.ayiriciKar ?? '-';
    _logoBoyu = s?.logoBoyu ?? LogoBoyu.kucuk;
    _metinCtrl.text = s?.staticMetin ?? '';
  }

  @override
  void dispose() {
    _metinCtrl.dispose();
    super.dispose();
  }

  void _onayla() {
    SablonSatir satir;
    switch (_tip) {
      case SatirTipi.alan:
        satir = SablonSatir(
            tip: _tip,
            alanKodu: _alanKodu,
            hizalama: _hizalama,
            kalin: _kalin,
            boy: _boy);
      case SatirTipi.metin:
        satir = SablonSatir(
            tip: _tip,
            staticMetin: _metinCtrl.text.trim(),
            hizalama: _hizalama,
            kalin: _kalin,
            boy: _boy);
      case SatirTipi.barkod:
        satir = SablonSatir(tip: SatirTipi.barkod);
      case SatirTipi.logo:
        satir = SablonSatir(
            tip: SatirTipi.logo, logoBoyu: _logoBoyu, hizalama: _hizalama);
      case SatirTipi.ayirici:
        satir = SablonSatir(
            tip: _tip, ayiriciKar: _ayiriciKar.isEmpty ? '-' : _ayiriciKar[0]);
      case SatirTipi.bosluk:
        satir = SablonSatir(tip: SatirTipi.bosluk);
    }
    Navigator.pop(context, satir);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, mq.viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.editSatir != null ? 'Satırı Düzenle' : 'Satır Ekle',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // ── Tip seçimi ──
              Text('Satır Tipi',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _scheme.onSurfaceVariant)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SatirTipi.values.map((t) {
                  final selected = _tip == t;
                  final (label, icon) = switch (t) {
                    SatirTipi.alan => ('Alan', Icons.data_object_rounded),
                    SatirTipi.metin => ('Metin', Icons.text_fields_rounded),
                    SatirTipi.barkod => ('Barkod', Icons.qr_code_rounded),
                    SatirTipi.ayirici => (
                        'Ayırıcı',
                        Icons.horizontal_rule_rounded
                      ),
                    SatirTipi.bosluk => ('Boşluk', Icons.space_bar_rounded),
                    SatirTipi.logo => ('Logo', Icons.image_outlined),
                  };
                  return GestureDetector(
                    onTap: () => setState(() => _tip = t),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _kRed.withOpacity(0.08)
                            : _scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected ? _kRed : _scheme.outlineVariant,
                            width: selected ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 14,
                              color:
                                  selected ? _kRed : _scheme.onSurfaceVariant),
                          SizedBox(width: 5),
                          Text(label,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: selected
                                      ? _kRed
                                      : _scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              // ── Tipe özel seçenekler ──
              if (_tip == SatirTipi.alan) ...[
                _label('Alan'),
                DropdownButtonFormField<AlanKodu>(
                  isExpanded: true,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurface),
                  value: _alanKodu,
                  decoration: _dec(),
                  items: AlanKodu.values
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text(a.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _alanKodu = v!),
                ),
                SizedBox(height: 12),
                _hizalamaKalinBoy(),
              ],

              if (_tip == SatirTipi.metin) ...[
                _label('Metin'),
                TextFormField(
                  controller: _metinCtrl,
                  decoration: _dec().copyWith(hintText: 'Metin'),
                ),
                SizedBox(height: 12),
                _hizalamaKalinBoy(),
              ],

              if (_tip == SatirTipi.barkod)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade100)),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded,
                          color: Colors.purple.shade600, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Code128 barkod görseli yazdırılır.\n'
                              'Barkod numarası alt kısımda otomatik görünür.',
                              style: TextStyle(
                                  fontFamily: 'Roboto', fontSize: 12))),
                    ],
                  ),
                ),

              if (_tip == SatirTipi.ayirici) ...[
                _label('Ayırıcı Karakter'),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ['-', '=', '*', '~'].map((k) {
                    final sel = _ayiriciKar == k;
                    return GestureDetector(
                      onTap: () => setState(() => _ayiriciKar = k),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 120),
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                            color: sel
                                ? _kRed.withOpacity(0.08)
                                : _scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? _kRed : _scheme.outlineVariant,
                                width: sel ? 1.5 : 1)),
                        child: Text(k * 5,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                                color: sel ? _kRed : _scheme.onSurfaceVariant,
                                fontFamily: 'monospace')),
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (_tip == SatirTipi.logo) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _scheme.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _scheme.primary.withValues(alpha: .08))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo_filerp.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FilERP Logosu',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _scheme.primary)),
                            SizedBox(height: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                _label('Logo Boyutu'),
                Row(
                  children: LogoBoyu.values.map((lb) {
                    final sel = _logoBoyu == lb;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _logoBoyu = lb),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 120),
                          margin: EdgeInsets.only(
                              right: lb != LogoBoyu.buyuk ? 8 : 0),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? _scheme.primary.withValues(alpha: .08)
                                : _scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel
                                    ? _scheme.primary
                                    : _scheme.outlineVariant,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.image_outlined,
                                  size: lb == LogoBoyu.kucuk
                                      ? 14
                                      : lb == LogoBoyu.orta
                                          ? 18
                                          : 22,
                                  color: sel
                                      ? _scheme.primary
                                      : _scheme.onSurfaceVariant),
                              SizedBox(height: 3),
                              Text(lb.label,
                                  style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: sel
                                          ? _scheme.primary
                                          : _scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                // Hizalama
                Row(children: [
                  _label('Hizalama', padding: false),
                  Spacer(),
                  ...Hizalama.values.map((h) => GestureDetector(
                        onTap: () => setState(() => _hizalama = h),
                        child: Container(
                          margin: EdgeInsets.only(left: 6),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: _hizalama == h
                                  ? _kRed.withOpacity(0.08)
                                  : _scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _hizalama == h
                                      ? _kRed
                                      : _scheme.outlineVariant,
                                  width: _hizalama == h ? 1.5 : 1)),
                          child: Text(h.label,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: _hizalama == h
                                      ? _kRed
                                      : _scheme.onSurfaceVariant,
                                  fontWeight: _hizalama == h
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      )),
                ]),
              ],

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onayla,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: _scheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.editSatir != null ? 'Güncelle' : 'Ekle',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _hizalamaKalinBoy() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hizalama
          Row(children: [
            _label('Hizalama', padding: false),
            Spacer(),
            ...Hizalama.values.map((h) => GestureDetector(
                  onTap: () => setState(() => _hizalama = h),
                  child: Container(
                    margin: EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: _hizalama == h
                            ? _kRed.withOpacity(0.08)
                            : _scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                _hizalama == h ? _kRed : _scheme.outlineVariant,
                            width: _hizalama == h ? 1.5 : 1)),
                    child: Text(h.label,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: _hizalama == h
                                ? _kRed
                                : _scheme.onSurfaceVariant,
                            fontWeight: _hizalama == h
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                )),
          ]),
          SizedBox(height: 10),
          // Kalın + Büyük
          Row(children: [
            _toggleChip(
                'Kalın', _kalin, () => setState(() => _kalin = !_kalin)),
            SizedBox(width: 8),
            _toggleChip(
                'Büyük Boy',
                _boy == YaziBoyutu.buyuk,
                () => setState(() => _boy = _boy == YaziBoyutu.buyuk
                    ? YaziBoyutu.normal
                    : YaziBoyutu.buyuk)),
          ]),
          SizedBox(height: 4),
        ],
      );

  Widget _toggleChip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: active
                  ? _kRed.withOpacity(0.08)
                  : _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? _kRed : _scheme.outlineVariant,
                  width: active ? 1.5 : 1)),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? _kRed : _scheme.onSurfaceVariant)),
        ),
      );

  Widget _label(String text, {bool padding = true}) => Padding(
        padding: EdgeInsets.only(bottom: padding ? 8.0 : 0),
        child: Text(text,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _scheme.onSurfaceVariant)),
      );

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: _scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _kRed, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}
