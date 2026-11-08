import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<int>? requiredModules;
  const DashboardModule(this.title, this.subtitle, this.icon, this.onTap,
      {this.requiredModules});
}

class MobileDashboard extends StatefulWidget {
  final String userName;
  final String company;
  final String branch;
  final List<DashboardModule> sales;
  final List<DashboardModule> inventory;
  final List<DashboardModule> finance;
  final VoidCallback onReports;
  const MobileDashboard(
      {super.key,
      required this.userName,
      required this.company,
      required this.branch,
      required this.sales,
      required this.inventory,
      required this.finance,
      required this.onReports});

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard> {
  List<String>? _selected;
  final _quickScroll = ScrollController();
  @override
  void dispose() {
    _quickScroll.dispose();
    super.dispose();
  }

  String get _storageKey => 'dashboard_quick_access_v1_${widget.userName}';
  List<DashboardModule> get _modules => [
        ...widget.sales,
        ...widget.inventory,
        ...widget.finance,
        DashboardModule(
            'Raporlar', '', Icons.insights_rounded, widget.onReports),
      ]
          .where((m) => AuthorizationSession.instance
              .any(m.requiredModules ?? MenuAccess.modules(m.title)))
          .toList();
  List<String> get _defaults => [
        if (widget.sales.isNotEmpty) widget.sales.first.title,
        if (widget.finance.isNotEmpty) widget.finance.last.title,
        if (widget.inventory.isNotEmpty) widget.inventory.first.title,
      ];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MobileDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName) {
      _selected = null;
      _load();
    }
  }

  Future<void> _load() async {
    final key = _storageKey;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && key == _storageKey)
      setState(() => _selected = prefs.getStringList(key));
  }

  Future<void> _edit() async {
    final chosen = (_selected ?? _defaults).toSet();
    final modules = _modules;
    final key = _storageKey;
    final result = await showDialog<List<String>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: const Text('Hızlı Erişim'),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  content: SizedBox(
                      width: 380,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final module in modules)
                          CheckboxListTile(
                              dense: true,
                              secondary: CorporateMenuIcon(module.title,
                                  size: 26, fallback: module.icon),
                              title: Text(module.title),
                              value: chosen.contains(module.title),
                              onChanged: (value) => update(() {
                                    if (value == true) {
                                      chosen.add(module.title);
                                    } else {
                                      chosen.remove(module.title);
                                    }
                                  })),
                      ]))),
                  actions: [
                    ErpDialogAction(
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Vazgeç')),
                    FilledButton(
                        onPressed: () => Navigator.pop(
                            ctx,
                            modules
                                .where((m) => chosen.contains(m.title))
                                .map((m) => m.title)
                                .toList()),
                        child: const Text('Kaydet'))
                  ],
                )));
    if (result == null || !mounted || key != _storageKey) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, result);
    if (mounted && key == _storageKey) setState(() => _selected = result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Row(children: [
          Expanded(child: _heading('Hızlı Erişim')),
          TextButton.icon(
              key: const ValueKey('quick-access-edit'),
              onPressed: _edit,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Düzenle'))
        ]),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final selected = _selected ?? _defaults;
          final actions =
              _modules.where((m) => selected.contains(m.title)).toList();
          if (actions.isEmpty)
            return Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Kart Ekle')));
          final tileWidth = (constraints.maxWidth - 20) / 3;
          final tileHeight = 88.0 +
              (MediaQuery.textScalerOf(context).scale(13) - 13)
                  .clamp(0.0, 30.0);
          return SizedBox(
            height: tileHeight * 2 + 24,
            child: Scrollbar(
              controller: _quickScroll,
              thumbVisibility: true,
              child: GridView.builder(
                key: const ValueKey('quick-access-grid'),
                controller: _quickScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: tileWidth,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemCount: (actions.length ~/ 6) * 6 +
                    ((actions.length % 6).clamp(0, 3) * 2),
                itemBuilder: (context, index) {
                  // Each group of six fills the top row before the bottom row.
                  final slot = index % 6;
                  final actionIndex =
                      (index ~/ 6) * 6 + slot ~/ 2 + (slot % 2) * 3;
                  if (actionIndex >= actions.length)
                    return const SizedBox.shrink();
                  final m = actions[actionIndex];
                  return Material(
                    color: scheme.primaryContainer.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: m.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CorporateMenuIcon(m.title,
                                    size: 30, fallback: m.icon),
                                const SizedBox(height: 8),
                                Flexible(
                                    child: Text(m.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: scheme.onSurface,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600))),
                              ])),
                    ),
                  );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 28),
        _group(context, 'Satış & Satın Alma', widget.sales),
        _group(context, 'Stok & Lojistik', widget.inventory),
        _group(context, 'Finans & Cariler', widget.finance),
        if (MenuAccess.visible('Raporlar'))
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
                onTap: widget.onReports,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      const CorporateMenuIcon('Raporlar', size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text('Rapor Merkezi',
                              style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700))),
                      Icon(Icons.arrow_forward_rounded,
                          color: scheme.primary, size: 20),
                    ]))),
          ),
      ],
    );
  }

  Widget _heading(String title) => Text(title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700));

  Widget _group(
      BuildContext context, String title, List<DashboardModule> modules) {
    final scheme = Theme.of(context).colorScheme;
    modules = modules
        .where((m) => AuthorizationSession.instance
            .any(m.requiredModules ?? MenuAccess.modules(m.title)))
        .toList();
    if (modules.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heading(title),
          const SizedBox(height: 14),
          Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.45))),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < modules.length; i++) ...[
                  if (i > 0) const Divider(indent: 74, endIndent: 16),
                  InkWell(
                      onTap: modules[i].onTap,
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color:
                                        scheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(13)),
                                child: CorporateMenuIcon(modules[i].title,
                                    size: 30, fallback: modules[i].icon)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(modules[i].title,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  if (modules[i].subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(modules[i].subtitle,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: scheme.onSurfaceVariant)),
                                  ],
                                ])),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant, size: 20),
                          ]))),
                ]
              ])),
        ]));
  }
}
