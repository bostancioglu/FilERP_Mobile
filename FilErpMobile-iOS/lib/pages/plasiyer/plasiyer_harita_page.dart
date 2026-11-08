import '../../widgets/erp_page_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/entities/plasiyer/plasiyer_konum_dto.dart';
import '../../services/plasiyer/plasiyer_konum_service.dart';
import '../../helpers/response.dart';
import '../../widgets/yetki_hatasi_widget.dart';

// Türkiye'nin ortalama merkezi — hiç konum yoksa haritanın açılacağı yer
const _kTurkiyeMerkezi = LatLng(39.0, 35.0);

class PlasiyerHaritaPage extends StatefulWidget {
  const PlasiyerHaritaPage({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  State<PlasiyerHaritaPage> createState() => _PlasiyerHaritaPageState();
}

class _PlasiyerHaritaPageState extends State<PlasiyerHaritaPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  bool _konumVar(PlasiyerKonumDto k) => k.Enlem != null && k.Boylam != null;
  void _odaklan(PlasiyerKonumDto k) {
    if (_konumVar(k)) _mapController.move(LatLng(k.Enlem!, k.Boylam!), 15);
  }

  final MapController _mapController = MapController();

  List<PlasiyerKonumDto> _konumlar = [];
  bool _loading = true;
  bool _yetkiHatasi = false;
  String? _hata;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _load(sessiz: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load({bool sessiz = false}) async {
    if (!sessiz) setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final data = await PlasiyerKonumService().getSonKonumlar(token);
      if (!mounted) return;
      setState(() {
        _konumlar = data;
        _loading = false;
        _yetkiHatasi = false;
        _hata = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is YetkiHatasi) {
        setState(() {
          _yetkiHatasi = true;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _hata = sessiz ? _hata : e.toString();
        });
      }
    }
  }

  String _zamanFarki(DateTime? t) {
    if (t == null) return "";
    final fark = DateTime.now().difference(t);
    if (fark.inSeconds < 60) return "az önce";
    if (fark.inMinutes < 60) return "${fark.inMinutes} dk önce";
    if (fark.inHours < 24) return "${fark.inHours} sa önce";
    return "${fark.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    final points = _konumlar.where(_konumVar).toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ErpPageAppBar(
          context: context,
          title: const Text('Plasiyer Konumları'),
          backgroundColor: _scheme.surface,
          foregroundColor: _scheme.onSurface,
          actions: [
            IconButton(
                tooltip: 'Yenile',
                onPressed: _loading ? null : () => _load(),
                icon: const Icon(Icons.refresh_rounded))
          ]),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _hata != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_off_outlined,
                                color: _scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(_hata!, textAlign: TextAlign.center),
                            TextButton(
                                onPressed: () => _load(),
                                child: const Text('Tekrar Dene'))
                          ])))
                  : Column(children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(children: [
                            Expanded(
                                child: Text('${points.length} Konum',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _scheme.onSurfaceVariant))),
                            Icon(Icons.sync_rounded,
                                size: 14, color: _scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('30 sn',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _scheme.onSurfaceVariant)),
                          ])),
                      Expanded(
                          child: Stack(children: [
                        FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: points.isEmpty
                                  ? _kTurkiyeMerkezi
                                  : LatLng(points.first.Enlem!,
                                      points.first.Boylam!),
                              initialZoom: points.isEmpty ? 5.5 : 12,
                              backgroundColor: _scheme.surfaceContainerLow,
                            ),
                            children: [
                              TileLayer(
                                  tileProvider: widget.tileProvider,
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.filerp.rotakod'),
                              MarkerLayer(
                                  markers: points
                                      .map((k) => Marker(
                                            point: LatLng(k.Enlem!, k.Boylam!),
                                            width: 150,
                                            height: 66,
                                            child: GestureDetector(
                                                onTap: () =>
                                                    _showPlasiyerBilgi(k),
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Material(
                                                          color:
                                                              _scheme.surface,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          elevation: 2,
                                                          child: Padding(
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                              child: Text(
                                                                  k.PlasiyerAdi ??
                                                                      'Plasiyer',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: _scheme
                                                                          .onSurface)))),
                                                      Icon(
                                                          Icons
                                                              .location_on_rounded,
                                                          color:
                                                              _scheme.primary,
                                                          size: 30),
                                                    ])),
                                          ))
                                      .toList()),
                            ]),
                        Positioned(
                            bottom: 4,
                            left: 8,
                            child: Material(
                                color: _scheme.surface.withValues(alpha: .9),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text('© OpenStreetMap',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _scheme.onSurfaceVariant))))),
                        if (points.isNotEmpty)
                          Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                  color: _scheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 2,
                                  child: IconButton(
                                      tooltip: 'Tüm Konumlar',
                                      icon: const Icon(
                                          Icons.center_focus_strong_rounded),
                                      onPressed: () => _mapController.fitCamera(
                                          CameraFit.coordinates(
                                              coordinates: points
                                                  .map((k) => LatLng(
                                                      k.Enlem!, k.Boylam!))
                                                  .toList(),
                                              padding: const EdgeInsets.all(48),
                                              maxZoom: 15))))),
                        if (points.isEmpty)
                          Center(
                              child: Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text('Konum bulunamadı',
                                          style: TextStyle(
                                              color:
                                                  _scheme.onSurfaceVariant))))),
                      ])),
                      if (_konumlar.isNotEmpty)
                        SafeArea(
                            top: false,
                            child: SizedBox(
                                height: 156,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  itemCount: _konumlar.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) {
                                    final k = _konumlar[i];
                                    final has = _konumVar(k);
                                    return Material(
                                      color: _scheme.surface,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: _scheme.outlineVariant)),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                          onTap: () {
                                            _odaklan(k);
                                            _showPlasiyerBilgi(k);
                                          },
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 9),
                                              child: Row(children: [
                                                Icon(
                                                    has
                                                        ? Icons
                                                            .person_pin_circle_outlined
                                                        : Icons
                                                            .location_off_outlined,
                                                    size: 22,
                                                    color: has
                                                        ? _scheme.primary
                                                        : _scheme
                                                            .onSurfaceVariant),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                          k.PlasiyerAdi ??
                                                              'Plasiyer',
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                      Text(
                                                          has
                                                              ? (k.Tarih == null
                                                                  ? 'Güncelleme yok'
                                                                  : _zamanFarki(
                                                                      k.Tarih))
                                                              : 'Konum yok',
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: _scheme
                                                                  .onSurfaceVariant))
                                                    ])),
                                                Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 18,
                                                    color: _scheme
                                                        .onSurfaceVariant),
                                              ]))),
                                    );
                                  },
                                ))),
                    ]),
    );
  }

  void _showPlasiyerBilgi(PlasiyerKonumDto k) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.PlasiyerAdi ?? 'Plasiyer',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                        _konumVar(k)
                            ? (k.Tarih == null
                                ? 'Güncelleme yok'
                                : 'Son güncelleme: ${_zamanFarki(k.Tarih)}')
                            : 'Konum yok',
                        style: TextStyle(
                            fontSize: 12, color: _scheme.onSurfaceVariant)),
                    if (_konumVar(k)) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _odaklan(k);
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text('Haritada Göster'))
                    ],
                  ]),
            )));
  }
}
