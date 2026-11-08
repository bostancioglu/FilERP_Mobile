import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import 'authorization_session.dart';
import 'backend_authorization_catalog.dart';
export 'package:http/http.dart' hide get, post, put, delete, patch, head;

final _rules = backendAccessRules
    .map((r) => (r, RegExp(r.pattern, caseSensitive: false)))
    .toList();

void checkRequest(String method, Uri url, {Map<String, String>? headers}) {
  final erp = Uri.parse(ApiConfig.baseUrl);
  final electronic = Uri.parse(ApiConfig.eBelgeBaseUrl);
  final api = url.origin == erp.origin
      ? 'erp'
      : url.origin == electronic.origin
          ? 'ebelge'
          : null;
  if (api == null) return;
  final prefix = (api == 'erp' ? erp : electronic).path;
  if (!url.path.startsWith('$prefix/') && url.path != prefix) return;
  final path = url.path.substring(prefix.length).replaceAll(RegExp(r'/+$'), '');
  final session = AuthorizationSession.instance;
  if (!session.signedIn) throw const YetkiHatasi();
  if (session.activeToken != null && headers != null) {
    final bearer = headers.entries
        .where((e) => e.key.toLowerCase() == 'authorization')
        .firstOrNull
        ?.value;
    if (bearer != 'Bearer ${session.activeToken}')
      throw const YetkiHatasi('Oturum değişti. Ekranı yeniden açın.');
  }

  for (final (rule, pattern) in _rules) {
    if (rule.api == api && rule.method == method && pattern.hasMatch(path)) {
      AuthorizationSession.instance.require(rule.module, rule.access);
      return;
    }
  }
  final controller =
      path.split('/').where((s) => s.isNotEmpty).firstOrNull?.toLowerCase();
  final viewModules = _viewModules[controller];
  if (api == 'erp' &&
      viewModules != null &&
      !AuthorizationSession.instance.any(viewModules, Access.read)) {
    throw const YetkiHatasi();
  }
}

const _viewModules = <String, List<int>>{
  'vw_carihareket': [6000, 6001, 201, 5101, 5103],
  'vw_cariborcalacaktry': [6001, 201, 5101],
  'vw_cariborcalacakdoviz': [6001, 201, 5101],
  'vw_stokhareket': [5001, 101],
  'vw_stokbakiyesubedepo': [5002, 5007, 6002, 101, 801, 5103],
  'vw_faturairsaliyeicmali': [5045, 5048, 5103],
  'vw_faturahareket': [5044, 5047],
  'vw_finanskasahareket': [5031, 1003, 5101],
  'vw_finanskasatoplam': [5031, 1003, 5101],
  'vw_finansbankahareket': [5030, 1004, 5101],
  'vw_finansbankatoplam': [5030, 1004, 5101],
  'vw_datdetay': [801, 5103],
  'vw_finanscekalinan': [5032],
  'vw_finanscekalinanportfoy': [5033],
  'vw_finanscekalinanprotesto': [5034],
  'vw_finanscekalinantahsil': [5035],
  'vw_finanscekalinanteminat': [5036],
  'vw_finanscekalinanciro': [5037],
  'vw_finanscekverilen': [5050, 5038],
  'vw_finanssenetalinan': [5051],
  'vw_finanssenetalinanportfoy': [5052],
  'vw_finanssenetalinanprotesto': [5053],
  'vw_finanssenetalinantahsil': [5054],
  'vw_finanssenetalinanteminat': [5055],
  'vw_finanssenetalinanciro': [5056],
  'vw_finanssenetverilen': [5058, 5057],
};

Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
  checkRequest('GET', url, headers: headers);
  return http.get(url, headers: headers);
}

Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
  checkRequest('HEAD', url, headers: headers);
  return http.head(url, headers: headers);
}

Future<http.Response> post(Uri url,
    {Map<String, String>? headers, Object? body, Encoding? encoding}) {
  checkRequest('POST', url, headers: headers);
  return http.post(url, headers: headers, body: body, encoding: encoding);
}

Future<http.Response> put(Uri url,
    {Map<String, String>? headers, Object? body, Encoding? encoding}) {
  checkRequest('PUT', url, headers: headers);
  return http.put(url, headers: headers, body: body, encoding: encoding);
}

Future<http.Response> patch(Uri url,
    {Map<String, String>? headers, Object? body, Encoding? encoding}) {
  checkRequest('PATCH', url, headers: headers);
  return http.patch(url, headers: headers, body: body, encoding: encoding);
}

Future<http.Response> delete(Uri url,
    {Map<String, String>? headers, Object? body, Encoding? encoding}) {
  checkRequest('DELETE', url, headers: headers);
  return http.delete(url, headers: headers, body: body, encoding: encoding);
}
