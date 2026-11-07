import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/entities/fatura/fatura_create_dto.dart';
import '../../helpers/stokhareket_couples.dart';

class UpperInfoForm extends StatefulWidget {
  final FaturaCreateDto fatura;
  final VoidCallback? onCariSelected;
  final ValueChanged<bool>? onKdvChanged;

  const UpperInfoForm({
    super.key,
    required this.fatura,
    this.onCariSelected,
    this.onKdvChanged,
  });

  @override
  State<UpperInfoForm> createState() => _UpperInfoFormState();
}

class _UpperInfoFormState extends State<UpperInfoForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _aciklamaCtrl = TextEditingController();
  final TextEditingController _belgeNoCtrl = TextEditingController();

  DateTime tarih = DateTime.now();
  int? _belgetipi;

  @override
  void initState() {
    super.initState();

    tarih = widget.fatura.tarih ?? DateTime.now();
    widget.fatura.tarih ??= tarih;
    widget.fatura.kdvdahil ??= true;
    widget.fatura.belgeyil ??= tarih.year;
    _belgetipi = widget.fatura.belgetipi;

    _aciklamaCtrl.text = widget.fatura.aciklama ?? "";
    _belgeNoCtrl.text = widget.fatura.belgeno ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Üst Bilgiler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// ---------------- CARİ ----------------
              _requiredLabel("Cari"),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  widget.onCariSelected?.call();
                  setState(() {});
                },
                child: InputDecorator(
                  decoration: _boxDeco(),
                  child: Text(
                    widget.fatura.cariid == null
                        ? "Cari seçiniz"
                        : "Cari #${widget.fatura.cariid}",
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ---------------- KDV ----------------
              _requiredLabel("KDV"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: widget.fatura.kdvdahil,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => widget.fatura.kdvdahil = v);
                        widget.onKdvChanged?.call(v);
                      },
                      title: const Text("Dahil"),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: widget.fatura.kdvdahil,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => widget.fatura.kdvdahil = v);
                        widget.onKdvChanged?.call(v);
                      },
                      title: const Text("Hariç"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// -------- BELGE SERİ / BELGE TİPİ --------
              Row(
                children: [
                  Expanded(
                    child: _dropdown<int>(
                      label: "Belge Seri *",
                      value: widget.fatura.belgeseri == null ? null : 1,
                      items: const {
                        1: "SFT",
                        2: "FTR",
                      },
                      onChanged: (v) {
                        if (v == null) return;
                        widget.fatura.belgeseri = v == 1 ? "SFT" : "FTR";
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _belgetipi,
                      decoration: _boxDeco(label: "Belge Tipi *"),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Açık")),
                        DropdownMenuItem(value: 2, child: Text("Kapalı")),
                        DropdownMenuItem(value: 3, child: Text("İade")),
                        DropdownMenuItem(value: 5, child: Text("İthalat")),
                        DropdownMenuItem(value: 6, child: Text("İhracat")),
                        DropdownMenuItem(
                            value: 7, child: Text("İhracat Kayıtlı")),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _belgetipi = v;
                          widget.fatura.belgetipi = v;
                          if (!StokHareketCouples.isIhracatTipi(v)) {
                            widget.fatura.ithalatihracattipi = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              // İthalat/İhracat Tipi — sadece ilgili belge tipi seçilince görünür
              if (StokHareketCouples.isIhracatTipi(_belgetipi)) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: widget.fatura.ithalatihracattipi,
                  decoration: _boxDeco(label: "İthalat/İhracat Tipi *"),
                  items: StokHareketCouples.ihracatTipleri
                      .map((e) => DropdownMenuItem<int>(
                          value: e.value, child: Text(e.text)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => widget.fatura.ithalatihracattipi = v),
                  validator: (v) => v == null ? "Zorunlu alan" : null,
                ),
              ],

              const SizedBox(height: 12),

              /// ---------------- BELGE NO ----------------
              _requiredLabel("Belge No"),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      readOnly: true,
                      initialValue: widget.fatura.belgeyil.toString(),
                      decoration: _boxDeco(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _belgeNoCtrl,
                      maxLength: 9,
                      decoration: _boxDeco(hint: "Belge No"),
                      onChanged: (v) => widget.fatura.belgeno = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Zorunlu" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ---------------- TARİH ----------------
              _requiredLabel("Tarih"),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365 * 5)),
                    lastDate: DateTime.now(),
                    initialDate: tarih,
                  );
                  if (d != null) {
                    setState(() {
                      tarih = d;
                      widget.fatura.tarih = d;
                      widget.fatura.belgeyil = d.year;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: _boxDeco(),
                  child: Text(DateFormat("dd.MM.yyyy").format(tarih)),
                ),
              ),

              const SizedBox(height: 12),

              /// ---------------- DÖVİZ / KUR ----------------
              Row(
                children: [
                  Expanded(
                    child: _dropdown<int>(
                      label: "Döviz",
                      value: widget.fatura.dovizid,
                      items: const {
                        1: "TL",
                        2: "USD",
                        3: "EUR",
                      },
                      onChanged: (v) {
                        widget.fatura.dovizid = v;
                        widget.fatura.kur = v == 1 ? 1 : widget.fatura.kur;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      enabled: widget.fatura.dovizid != 1,
                      initialValue: widget.fatura.kur?.toString() ?? "1",
                      decoration: _boxDeco(label: "Kur"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => widget.fatura.kur = double.tryParse(v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ---------------- PROJE / PLASİYER ----------------
              Row(
                children: [
                  Expanded(
                    child: _dropdown<int>(
                      label: "Proje",
                      value: widget.fatura.projeid,
                      items: const {
                        1: "Fabrika",
                        2: "Şube",
                      },
                      onChanged: (v) => widget.fatura.projeid = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown<int>(
                      label: "Plasiyer",
                      value: widget.fatura.plasiyerid,
                      items: const {
                        1: "Ahmet",
                        2: "Mehmet",
                      },
                      onChanged: (v) => widget.fatura.plasiyerid = v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ---------------- AÇIKLAMA ----------------
              TextFormField(
                controller: _aciklamaCtrl,
                maxLines: 2,
                decoration: _boxDeco(label: "Açıklama"),
                onChanged: (v) => widget.fatura.aciklama = v,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _requiredLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          "$t *",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _boxDeco({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      counterText: "",
      isDense: true,
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _boxDeco(label: label),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<T>(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
