import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cari/cari_service.dart';
import '../../models/entities/cari/cari_dto_lite.dart';
import 'cari_detay_page.dart';
import 'cari_ekle_page.dart';
import '../../helpers/response.dart';
import '../../widgets/yetki_hatasi_widget.dart';
import '../../services/offline/offline_service.dart';

// Avatar için isim bazlı renk paleti
class CariListPage extends StatefulWidget {
  const CariListPage({super.key});

  @override
  State<CariListPage> createState() => _CariListPageState();
}

class _CariListPageState extends State<CariListPage> {
  List<CariDtoLite> allCariler = [];
  List<CariDtoLite> filtered = [];
  bool loading = true;
  bool _yetkiHatasi = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCariler();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _offlineVeri = false;

  Future<void> loadCariler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final internetYokOnceden = !OfflineService.instance.isOnline.value;
      final data = await CariService().getCariler(token);
      setState(() {
        allCariler = data;
        filtered = List.from(data);
        loading = false;
        _offlineVeri = internetYokOnceden;
      });
    } catch (e) {
      if (e is YetkiHatasi) {
        if (mounted)
          setState(() {
            _yetkiHatasi = true;
            loading = false;
          });
      } else {
        setState(() => loading = false);
        debugPrint("Cari Listesi Hatası: $e");
      }
    }
  }

  void search(String text) {
    final s = text.toLowerCase();
    setState(() {
      filtered = s.isEmpty
          ? List.from(allCariler)
          : allCariler.where((c) {
              return (c.Ad ?? "").toLowerCase().contains(s) ||
                  (c.Kod ?? "").toLowerCase().contains(s) ||
                  (c.Vergino ?? "").toLowerCase().contains(s);
            }).toList();
    });
  }

  void _removeAnimatedById(int? id) {
    if (id == null || !mounted) return;
    setState(() {
      filtered.removeWhere((c) => c.Id == id);
      allCariler.removeWhere((c) => c.Id == id);
    });
  }

  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(scheme),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : loading
              ? const Center(child: const CircularProgressIndicator())
              : Column(
                  children: [
                    if (_offlineVeri) _buildOfflineBanner(),
                    _buildSearchBar(scheme),
                    if (!loading && !_yetkiHatasi) _buildCountHeader(scheme),
                    Expanded(child: _buildList()),
                  ],
                ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 16, color: const Color(0xFF8A6D3B)),
          SizedBox(width: 8),
          Expanded(
            child: const Text(
              "Çevrimdışı — son senkronize edilen veriler gösteriliyor",
              style:
                  const TextStyle(fontSize: 12, color: const Color(0xFF8A6D3B)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme scheme) {
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
            "Cari Listesi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            "Müşteri & Tedarikçi",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: "Yenile",
          icon: Icon(Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            setState(() => loading = true);
            loadCariler();
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

  Widget _buildSearchBar(ColorScheme scheme) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: TextField(
        controller: _searchCtrl,
        onChanged: search,
        style: TextStyle(
            fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "Ad, kod veya vergi no ile ara...",
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
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCountHeader(ColorScheme scheme) => ErpListOverview(
        count: _searchCtrl.text.isEmpty
            ? '${allCariler.length} cari kayıtlı'
            : '${filtered.length} sonuç bulundu',
      );

  Widget _buildList() {
    if (filtered.isEmpty) return _buildEmptyState();
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _buildCardContent(filtered[i]));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? "Aramanızla eşleşen cari bulunamadı"
                : "Henüz cari kaydı yok",
            style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                search("");
              },
              child: const Text("Aramayı temizle"),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCardContent(CariDtoLite c) => ErpRecordCard(
        title: c.Ad ?? 'Adsız cari',
        code: c.Kod ?? '',
        icon: Icons.business_outlined,
        details: [
          if (c.Vergino?.isNotEmpty == true) 'VKN: ${c.Vergino}',
          if (c.Vergidairesi?.isNotEmpty == true) c.Vergidairesi!,
          if (c.Vadegunu != null && c.Vadegunu! > 0) '${c.Vadegunu} gün vade',
        ],
        onTap: () async {
          final result = await Navigator.push<bool>(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => CariDetayPage(cariId: c.Id!)));
          if (result == true) _removeAnimatedById(c.Id);
        },
      );

  Widget _buildFab() {
    return PermissionAction(
        modules: [201],
        access: Access.create,
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          icon: const Icon(Icons.person_add_outlined, size: 20),
          label: const Text(
            "Yeni Cari",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PermissionMaterialPageRoute(builder: (_) => const CariEklePage()),
            );
            if (result == true) loadCariler();
          },
        ));
  }
}
