import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/user_parameters.dart';
import 'package:FilERP/widgets/permission_page.dart';

String parameterToken(dynamic parameters) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({
              UserParameters.claimName: parameters
            }))).replaceAll('=', '')}.signature';

void main() {
  test('user parameter supports the JSON-string claim and defaults to portal',
      () {
    for (final value in [true, 1, 'Evet', 'true']) {
      expect(
          UserParameters.fromToken(
                  parameterToken(jsonEncode({'Otomatikefaturagonder': value})))
              .automaticElectronicSend,
          isTrue);
    }
    for (final value in [false, null, 0, 'Hayır', 'unexpected']) {
      expect(
          UserParameters.fromToken(
                  parameterToken({'Otomatikefaturagonder': value}))
              .automaticElectronicSend,
          isFalse);
    }
    for (final token in [null, '', 'invalid', 'a.bad.b', parameterToken({})]) {
      expect(UserParameters.fromToken(token).automaticElectronicSend, isFalse);
    }
  });
  test(
      'branch token selects exactly one send action and still requires permission',
      () {
    final session = AuthorizationSession.instance;
    for (final automatic in [false, true]) {
      for (final read in [false, true]) {
        for (final module in [301, 501]) {
          session.activate([
            {'Subeid': 1, 'Modulaltid': module, 'TumunuOkuma': read}
          ],
              branch: 1,
              company: 1,
              environment: ApiConfig.serverType.name,
              token: parameterToken({'Otomatikefaturagonder': automatic}));
          expect(ActionAccess.allowed([module], 'Portala Gönder'), !automatic);
          expect(
              ActionAccess.allowed(
                  [module],
                  module == 301
                      ? 'E-Fatura Oluştur ve Gönder'
                      : 'E-İrsaliye Oluştur ve Gönder'),
              automatic && read);
          expect(ActionAccess.allowed([999], 'Portala Gönder'), isFalse);
        }
      }
    }
    session.activate([],
        branch: 2,
        company: 1,
        environment: ApiConfig.serverType.name,
        token: parameterToken({}));
    expect(session.automaticElectronicSend, isFalse);
    session.reset();
    expect(session.automaticElectronicSend, isFalse);
  });
}
