import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/backend_authorization_catalog.dart';

void grantAdministratorFixture({String? token}) {
  AuthorizationSession.instance.activate([
    for (final id in sharedModuleIds.values)
      {
        'Subeid': 1,
        'Modulaltid': id,
        'TumunuOkuma': true,
        'Ekleme': true,
        'Guncelleme': true,
        'Silme': true,
      }
  ],
      branch: 1,
      company: 1,
      environment: ApiConfig.serverType.name,
      account: 'fixture:admin',
      token: token);
}
