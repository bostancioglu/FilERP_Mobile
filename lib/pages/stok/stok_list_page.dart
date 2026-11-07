import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../widgets/erp_page_style.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/stok/stok_service.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../pages/stok/stok_detay_page.dart';
import '../../pages/stok/stok_ekle_page.dart';
import '../../helpers/response.dart';
import '../../widgets/yetki_hatasi_widget.dart';
import '../../services/offline/offline_service.dart';

class StokListPage extends StatefulWidget {
  const StokListPage({super.key});

  @override
  State<StokListPage> createState() => _StokListPageState();
}

class _StokMemory {
  static List<StokListDto>? list;
}

class _StokListPageState extends State<StokListPage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  List<StokListDto> allStoklar = [];
  List<int> filteredIdx = [];

  bool loading = true;
  bool _yetkiHatasi = false;
  bool refreshing = false;
  bool navigating = false;
  bool _offlineVeri = false;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  int visibleCount = 200;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    loadStoklar();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 600) {
      if (visibleCount < filteredIdx.length) {
        setState(() {
          visibleCount = min(visibleCount + 200, filteredIdx.length);
        });
      }
    }
  }

  Future<void> loadStoklar() async {
    if (navigating) return;
    setState(() => loading = true);

    try {
      final mem = _StokMemory.list;
      if (mem != null && mem.isNotEmpty) {
        allStoklar = mem;
        filteredIdx = List<int>.generate(allStoklar.length, (i) => i);
        visibleCount = min(200, filteredIdx.length);
        if (mounted) setState(() => loading = false);
        await _refreshFromApi(showLine: true);
        return;
      }
      await _refreshFromApi(showLine: false);
    } catch (e) {
      if (e is YetkiHatasi) {
        if (mounted)
          setState(() {
            _yetkiHatasi = true;
            loading = false;
            refreshing = false;
          });
      } else {
        debugPrint("Stok Listesi Hatası: $e");
        if (mounted)
          setState(() {
            loading = false;
            refreshing = false;
          });
      }
    }
  }

  Future<void> _refreshFromApi({required bool showLine}) async {
    if (!mounted || navigating) return;
    if (showLine) setState(() => refreshing = true);

    final internetYokOnceden = !OfflineService.instance.isOnline.value;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final apiData = await StokService().getStokList(token);

    _StokMemory.list = apiData;
    allStoklar = apiData;
    filteredIdx = List<int>.generate(allStoklar.length, (i) => i);
    visibleCount = min(200, filteredIdx.length);

    if (!mounted) return;
    setState(() {
      loading = false;
      refreshing = false;
      _offlineVeri = internetYokOnceden;
    });
  }

  void search(String text) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        filteredIdx = List<int>.generate(allStoklar.length, (i) => i);
        visibleCount = min(200, filteredIdx.length);
      });
      return;
    }

    const maxMatches = 5000;
    final results = <int>[];
    for (int i = 0; i < allStoklar.length; i++) {
      final x = allStoklar[i];
      if ((x.Ad ?? "").toLowerCase().contains(q) ||
          (x.Kod ?? "").toLowerCase().contains(q) ||
          (x.Barkodlar ?? "").toLowerCase().contains(q) ||
          (x.Searchtext ?? "").toLowerCase().contains(q)) {
        results.add(i);
        if (results.length >= maxMatches) break;
      }
    }
    setState(() {
      filteredIdx = results;
      visibleCount = min(200, filteredIdx.length);
    });
  }

  Future<void> _openDetay(StokListDto s) async {
    navigating = true;
    final result = await Navigator.push<bool>(
      context,
      PermissionMaterialPageRoute(builder: (_) => StokDetayPage(stokId: s.Id!)),
    );
    navigating = false;
    if (!mounted) return;
    if (result == true) {
      _StokMemory.list = null;
      await loadStoklar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? YetkiHatasiWidget()
          : loading
              ? Center(child: CircularProgressIndicator(color: _kRed))
              : Column(
                  children: [
                    if (_offlineVeri) _buildOfflineBanner(),
                    _buildSearchBar(),
                    if (refreshing)
                      LinearProgressIndicator(
                        minHeight: 2,
                        color: _kRed,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    _buildCountHeader(),
                    Expanded(child: _buildList()),
                  ],
                ),
      floatingActionButton: PermissionAction(
          modules: [101],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _kRed,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: Icon(Icons.add_box_outlined, size: 20),
            label: Text("Yeni Stok",
                style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                PermissionMaterialPageRoute(builder: (_) => StokEklePage()),
              );
              if (result == true && mounted) {
                _StokMemory.list = null;
                await loadStoklar();
              }
            },
          )),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFF8A6D3B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Çevrimdışı — son senkronize edilen veriler gösteriliyor",
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6D3B)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Stok Listesi",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            "Ürün & Hizmet",
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: "Yenile",
          icon: Icon(Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            _StokMemory.list = null;
            setState(() => refreshing = true);
            loadStoklar();
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: TextField(
        controller: _searchCtrl,
        onChanged: search,
        style: TextStyle(
            fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "Ad, kod veya barkod ile ara...",
          hintStyle: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchCtrl.clear();
                    search("");
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCountHeader() => ErpListOverview(
        count: _searchCtrl.text.isEmpty
            ? '${allStoklar.length} stok kayıtlı'
            : '${filteredIdx.length} sonuç bulundu',
      );

  Widget _buildList() {
    final count = min(visibleCount, filteredIdx.length);
    if (count == 0) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: count,
      itemBuilder: (context, index) {
        final s = allStoklar[filteredIdx[index]];
        return _buildCard(s);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? "Aramanızla eşleşen stok bulunamadı"
                : "Henüz stok kaydı yok",
            style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                search("");
              },
              child: Text("Aramayı temizle"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(StokListDto s) => ErpRecordCard(
        title: s.Ad ?? 'Adsız stok',
        code: s.Kod ?? '',
        icon: Icons.inventory_2_outlined,
        details: [
          if ((s.TemelolcubrKod ?? s.TemelolcubrAd)?.isNotEmpty == true)
            s.TemelolcubrKod ?? s.TemelolcubrAd!,
          if (s.Barkodlar?.isNotEmpty == true)
            'Barkod: ${s.Barkodlar!.split(' - ').first}',
        ],
        onTap: () => _openDetay(s),
      );
}
