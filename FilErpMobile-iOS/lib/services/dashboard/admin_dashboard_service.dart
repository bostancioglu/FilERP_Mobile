import 'dart:convert';
import '../../config/api_config.dart';
import '../auth/authorization_session.dart';
import '../auth/authorized_http.dart' as http;

class DashboardMetric {
  final String title;
  final List<Map<String, dynamic>>? rows;
  final String amountField;
  const DashboardMetric(this.title, this.rows,
      {this.amountField = 'Geneltoplam'});
  List<Map<String, dynamic>> between(DateTime start, DateTime end) =>
      (rows ?? []).where((r) {
        final date = DateTime.tryParse(r['Tarih']?.toString() ?? '');
        return date != null && !date.isBefore(start) && date.isBefore(end);
      }).toList();
  double total(DateTime start, DateTime end) => between(start, end).fold(
      0.0,
      (sum, row) =>
          sum +
          ((row[amountField] as num?)?.toDouble() ??
              (amountField == 'Songeneltoplam'
                  ? (row['Geneltoplam'] as num?)?.toDouble()
                  : null) ??
              0));
}

class AdminDashboardService {
  // The backend still enforces each source's existing module permissions.
  Future<bool> allowed() async {
    final session = AuthorizationSession.instance;
    if (!session.signedIn) return false;
    return session.isAdmin;
  }

  Future<List<DashboardMetric>> load() async {
    if (!await allowed()) {
      throw StateError('Dashboard için yönetici erişimi gerekli.');
    }
    final session = AuthorizationSession.instance;
    final revision = session.revision;
    final base = ApiConfig.baseUrl;
    final token = session.activeToken ?? '';
    Future<List<Map<String, dynamic>>> get(String path) async {
      if (revision != session.revision) throw StateError('Oturum değişti.');
      final response = await http.get(Uri.parse('$base/$path'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw StateError('Veri alınamadı');
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map ||
          body['Data'] is! List ||
          (body['Errors'] is List && (body['Errors'] as List).isNotEmpty)) {
        throw StateError('Geçersiz veri');
      }
      return (body['Data'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    }

    Future<DashboardMetric> source(
        String title, Future<List<Map<String, dynamic>>> Function() read,
        {String amountField = 'Geneltoplam'}) async {
      try {
        return DashboardMetric(title, await read(), amountField: amountField);
      } catch (_) {
        return DashboardMetric(title, null, amountField: amountField);
      }
    }

    Future<List<Map<String, dynamic>>> movements(
        String account, String path) async {
      final accounts = await get(account);
      final result = <Map<String, dynamic>>[];
      // Sequential requests avoid overwhelming the existing per-account API.
      for (final a in accounts) {
        result.addAll(await get('$path/${a['Id']}'));
      }
      return result;
    }

    final data = await Future.wait([
      source(
          'Satış faturası',
          () async => (await get('Fatura'))
              .where((r) => r['Belgedurum'] == 1 && r['Belgeturu'] == 1)
              .toList(),
          amountField: 'Songeneltoplam'),
      source(
          'Satış siparişi',
          () async => (await get('Siparis'))
              .where((r) => r['Belgedurum'] == 1)
              .toList()),
      source(
          'Satış irsaliyesi',
          () async => (await get('Irsaliye'))
              .where((r) => r['Belgedurum'] == 1 && r['Belgeturu'] == 3)
              .toList()),
      source(
          'Depo çıkışı',
          () async => (await get('Ambargc'))
              .where((r) => r['Belgedurum'] == 1 && r['Giriscikis'] == 2)
              .toList()),
      source('Kasa hareketleri',
          () => movements('Kasa/AllWithoutAuth', 'Kasahareket/GetByKasaid'),
          amountField: 'Tutar'),
      source(
          'Banka hareketleri',
          () => movements(
              'Bankahesap/AllWithoutAuth', 'Bankahareket/GetByBankahesapid'),
          amountField: 'Tutar'),
    ]);
    if (revision != session.revision || base != ApiConfig.baseUrl) {
      throw StateError('Oturum değişti.');
    }
    return data;
  }
}
