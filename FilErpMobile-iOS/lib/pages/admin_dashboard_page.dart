import '../widgets/dashboard_donut.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/dashboard/admin_dashboard_service.dart';
import '../services/auth/authorization_session.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<DashboardMetric>? _data;
  String? _error;
  bool _loading = true;
  late DateTimeRange _range;
  final _money = NumberFormat('#,##0.00', 'tr_TR');
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month, now.day));
    AuthorizationSession.instance.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) {
      setState(() {
        _data = null;
        _error = 'Oturum değişti. Dashboard’u yeniden açın.';
      });
    }
  }

  @override
  void dispose() {
    AuthorizationSession.instance.removeListener(_changed);
    super.dispose();
  }

  Future<void> _load() async {
    final revision = AuthorizationSession.instance.revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminDashboardService().load();
      if (mounted && revision == AuthorizationSession.instance.revision) {
        setState(() => _data = data);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = null;
          _error =
              'Dashboard yüklenemedi. Yönetici erişiminizi ve bağlantınızı kontrol edin.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _range.start;
    final end = DateTime(_range.end.year, _range.end.month, _range.end.day + 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetici Dashboard'), actions: [
        IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile')
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    OutlinedButton.icon(
                      key: const ValueKey('dashboard-date-range'),
                      onPressed: _selectDates,
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                          '${DateFormat('dd.MM.yyyy').format(_range.start)} – ${DateFormat('dd.MM.yyyy').format(_range.end)}'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16)),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 340 &&
                              MediaQuery.textScalerOf(context).scale(1) < 1.5
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(spacing: 12, runSpacing: 12, children: [
                        for (var i = 0; i < (_data?.length ?? 0); i++)
                          SizedBox(
                              width: width,
                              child: _metricCard(_data![i], start, end, i)),
                      ]);
                    }),
                    if (_data != null && _data!.first.rows != null)
                      _trend(start, end, _data!.first),
                    if (_data != null) ...[
                      const SizedBox(height: 8),
                      _distribution(start, end, 2),
                      _distribution(start, end, 1),
                      _customers(start, end),
                      _flow(start, end),
                    ],
                  ])),
    );
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Tarih aralığı',
      saveText: 'Uygula',
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Widget _metricCard(
      DashboardMetric metric, DateTime start, DateTime end, int index) {
    const icons = [
      Icons.receipt_long_outlined,
      Icons.shopping_bag_outlined,
      Icons.local_shipping_outlined,
      Icons.warehouse_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_outlined
    ];
    final scheme = Theme.of(context).colorScheme;
    final finance = metric.amountField == 'Tutar';
    final outgoing = DashboardMetric(
        '', metric.rows?.where((r) => r['Giriscikis'] == 2).toList(),
        amountField: metric.amountField);
    final amount =
        finance ? outgoing.total(start, end) : metric.total(start, end);
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icons[index], size: 22, color: scheme.primary)),
          const SizedBox(height: 14),
          Text(metric.title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          if (metric.rows == null)
            const Text('Veri alınamadı / erişim yok')
          else ...[
            Text('${_money.format(amount)} TL',
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5)),
            const SizedBox(height: 4),
            Text(
                finance
                    ? '${outgoing.between(start, end).length} çıkış işlemi'
                    : '${metric.between(start, end).length} belge',
                style: Theme.of(context).textTheme.bodySmall),
            if (finance)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Çıkış tutarı',
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant))),
          ],
        ]));
  }

  Widget _distribution(DateTime start, DateTime end, int direction) {
    final sources = _data!.where((m) => m.amountField == 'Tutar').toList();
    final complete =
        sources.length == 2 && sources.every((m) => m.rows != null);
    return DashboardDonut(
      title: direction == 2
          ? 'Ödemeler nereden yapıldı?'
          : 'Para girişlerinin dağılımı',
      subtitle: '',
      slices: !complete
          ? null
          : [
              for (var i = 0; i < sources.length; i++)
                DashboardSlice(
                    sources[i].title.startsWith('Kasa') ? 'Kasa' : 'Banka',
                    DashboardMetric(
                            '',
                            sources[i]
                                .rows!
                                .where((r) => r['Giriscikis'] == direction)
                                .toList(),
                            amountField: 'Tutar')
                        .total(start, end),
                    i == 0 ? const Color(0xFF14B8A6) : const Color(0xFF6366F1)),
            ],
    );
  }

  Widget _customers(DateTime start, DateTime end) {
    final sales = _data!.first;
    final groups = <String, double>{};
    for (final row in sales.between(start, end)) {
      final customer = row['Cari'];
      final name = customer is Map
          ? customer['Ad']?.toString() ?? 'Cari bilgisi yok'
          : 'Cari bilgisi yok';
      final value = DashboardMetric('', [row], amountField: sales.amountField)
          .total(start, end);
      groups.update(name, (old) => old + value, ifAbsent: () => value);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(4).toList();
    final other = entries.skip(4).fold<double>(0, (sum, e) => sum + e.value);
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFFEC4899)
    ];
    return DashboardDonut(
        title: 'Satışın müşteri dağılımı',
        subtitle: '',
        slices: sales.rows == null
            ? null
            : [
                for (var i = 0; i < top.length; i++)
                  DashboardSlice(top[i].key, top[i].value, colors[i]),
                if (entries.length > 4)
                  DashboardSlice(
                      'Diğer cariler', other, const Color(0xFF94A3B8)),
              ]);
  }

  Widget _flow(DateTime start, DateTime end) {
    final bars = <(String, double)>[];
    for (final metric
        in _data!.where((m) => m.amountField == 'Tutar' && m.rows != null)) {
      for (final direction in [1, 2]) {
        final rows =
            metric.rows!.where((r) => r['Giriscikis'] == direction).toList();
        bars.add((
          '${metric.title.startsWith('Kasa') ? 'Kasa' : 'Banka'} ${direction == 1 ? 'giriş' : 'çıkış'}',
          DashboardMetric('', rows, amountField: 'Tutar').total(start, end)
        ));
      }
    }
    final maximum = bars.fold<double>(0, (a, b) => a > b.$2 ? a : b.$2);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nakit hareketleri · TL',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (bars.isEmpty) const Text('Kasa/banka verisi alınamadı.'),
              for (final bar in bars) ...[
                Text('${bar.$1}: ${_money.format(bar.$2)} TL'),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                    value: maximum > 0 ? (bar.$2 / maximum).clamp(0.0, 1.0) : 0,
                    minHeight: 8),
                const SizedBox(height: 14),
              ],
            ])));
  }

  Widget _trend(DateTime start, DateTime end, DashboardMetric metric) {
    final dayCount = end.difference(start).inDays;
    final step = (dayCount / 12).ceil().clamp(1, 100000);
    final days = [
      for (var i = 0; i < dayCount; i += step)
        DateTime(start.year, start.month, start.day + i)
    ];
    final values = [
      for (final day in days)
        metric.total(
            day,
            DateTime(day.year, day.month, day.day + step).isAfter(end)
                ? end
                : DateTime(day.year, day.month, day.day + step))
    ];
    final maximum = values.fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Satış trendi',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (maximum == 0)
                const Text('Bu dönemde satış faturası bulunmuyor.')
              else
                SizedBox(
                    height: 150,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < days.length; i++)
                            Expanded(
                                child: Tooltip(
                                    message:
                                        '${DateFormat('dd.MM').format(days[i])}: ${_money.format(values[i])} TL',
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                  height:
                                                      110 * values[i] / maximum,
                                                  decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4))),
                                              const SizedBox(height: 6),
                                              Text(
                                                  '${days[i].day}',
                                                  style: const TextStyle(
                                                      fontSize: 10)),
                                            ])))),
                        ])),
            ])));
  }
}
