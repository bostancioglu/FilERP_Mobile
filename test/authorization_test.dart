import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hive/hive.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/helpers/response.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/authorized_http.dart' as secured;
import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/services/login/login_service.dart';
import 'package:FilERP/pages/stok/stok_ekle_page.dart';
import 'package:FilERP/pages/rapor/rapor_merkezi_page.dart';
import 'package:FilERP/pages/ana_sayfa_yeni_tasarim_page.dart';
import 'package:FilERP/widgets/mobile_dashboard.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/erp_module_menu.dart';
import 'package:FilERP/widgets/document_action_ui.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/helpers/bordro_durum_islem.dart';
import 'package:FilERP/services/offline/offline_service.dart';

class MountProbe extends StatefulWidget {
  final VoidCallback onMount;
  const MountProbe({required this.onMount});
  @override
  State<MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

Map<String, dynamic> permission(int module,
        {int branch = 1,
        bool read = false,
        bool create = false,
        bool update = false,
        bool delete = false}) =>
    {
      'Subeid': branch,
      'Modulaltid': module,
      'TumunuOkuma': read,
      'Ekleme': create,
      'Guncelleme': update,
      'Silme': delete,
    };
void activate(List rows, {int branch = 1, String account = '5:42'}) =>
    AuthorizationSession.instance.activate(rows,
        branch: branch,
        company: 3,
        environment: ApiConfig.serverType.name,
        account: account);

void main() {
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('permission_cache_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await cache.delete(recursive: true);
  });

  test('permission absence and nullable flags fail closed', () {
    final session = AuthorizationSession();
    expect(session.can(301), false);
    session.activate([
      {'Subeid': 1, 'Modulaltid': 301}
    ], branch: 1, company: 3, environment: 'canli');
    expect(session.can(301), true);
    for (final access in [
      Access.read,
      Access.create,
      Access.update,
      Access.delete
    ]) {
      expect(session.can(301, access), false);
    }
    expect(session.can(302), false);
  });
  test('branch isolation and first-record semantics match Shared AuthExtension',
      () {
    activate([
      permission(301, read: true),
      permission(301, delete: true),
      permission(302, branch: 2, create: true)
    ]);
    expect(AuthorizationSession.instance.can(301, Access.read), true);
    expect(AuthorizationSession.instance.can(301, Access.delete), false);
    expect(AuthorizationSession.instance.can(302), false);
    activate(
        [permission(301, read: true), permission(302, branch: 2, create: true)],
        branch: 2);
    expect(AuthorizationSession.instance.can(301), false);
    expect(AuthorizationSession.instance.can(302, Access.create), true);
  });
  test('Login effective permissions survive raw SS reply and branch switches',
      () async {
    final service = LoginService();
    final loginData = {
      'Id': 42,
      'Firmaid': 5,
      'Kullaniciadi': 'restricted',
      'Token': 'initial',
      'Yetki': [
        {
          ...permission(301, read: true),
          'Sube': {
            'Id': 1,
            'Sirket': {'Id': 3, 'Efaturaentegratorsifre': 'do-not-persist'}
          }
        },
        permission(302, branch: 2, create: true),
      ],
    };
    var ss = 0;
    await http.runWithClient(() async {
      await service.login('restricted', 'fake-password');
      expect(AuthorizationSession.instance.signedIn, false);
      await service.loginSirketSube(3, 1);
      expect(AuthorizationSession.instance.can(301, Access.read), true);
      expect(AuthorizationSession.instance.can(302), false);
      expect(AuthorizationSession.instance.activeToken, 'final-1');
      await service.loginSirketSube(3, 2);
      expect(AuthorizationSession.instance.can(301), false);
      expect(AuthorizationSession.instance.can(302, Access.create), true);
      expect(AuthorizationSession.instance.activeToken, 'final-2');
    },
        () => MockClient((r) async {
              if (r.url.path.endsWith('/Login'))
                return http.Response(jsonEncode({'Data': loginData}), 200);
              ss++;
              return http.Response(
                  jsonEncode({
                    'Data': {
                      'Token': 'final-$ss',
                      'Yetki': [permission(999, read: true, delete: true)]
                    }
                  }),
                  200);
            }));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('permission_login_v1'),
        isNot(contains('do-not-persist')));
    expect(prefs.getString('permission_login_v1'),
        isNot(contains('fake-password')));
    AuthorizationSession.instance.reset();
    await AuthorizationSession.instance.restore();
    expect(AuthorizationSession.instance.can(302, Access.create), true);
    await prefs.setInt('sube_id', 9);
    await AuthorizationSession.instance.restore();
    expect(AuthorizationSession.instance.signedIn, false);
  });
  test('environment change clears tokens and permissions', () async {
    SharedPreferences.setMockInitialValues(
        {'token': 'first', 'token_final': 'final'});
    activate([permission(301, read: true)]);
    await ApiConfig.setServer(ServerType.test, save: false);
    expect(AuthorizationSession.instance.can(301), false);
    expect(
        (await SharedPreferences.getInstance()).getString('token_final'), null);
  });
  test(
      'client blocks forbidden reads and writes before transport; completion uses create',
      () async {
    activate([permission(301, read: true), permission(501, create: true)]);
    final requests = <String>[];
    await http.runWithClient(() async {
      await secured.get(Uri.parse('${ApiConfig.baseUrl}/Fatura'));
      await expectLater(
          () =>
              secured.post(Uri.parse('${ApiConfig.baseUrl}/Fatura/SaveSingle')),
          throwsA(isA<YetkiHatasi>()));
      await expectLater(
          () =>
              secured.put(Uri.parse('${ApiConfig.baseUrl}/Fatura/Complete/id')),
          throwsA(isA<YetkiHatasi>()));
      await expectLater(
          () => secured.delete(
              Uri.parse('${ApiConfig.baseUrl}/Fatura/RemoveWithItems/id')),
          throwsA(isA<YetkiHatasi>()));
      await expectLater(
          () => secured.get(Uri.parse('${ApiConfig.baseUrl}/Irsaliye')),
          throwsA(isA<YetkiHatasi>()));
      await secured.put(Uri.parse('${ApiConfig.baseUrl}/Irsaliye/Complete/id'));
      await expectLater(
          () => secured
              .post(Uri.parse('${ApiConfig.baseUrl}/VW_Carihareket/Filter')),
          throwsA(isA<YetkiHatasi>()));
    },
        () => MockClient((r) async {
              requests.add('${r.method} ${r.url.path}');
              return http.Response('{}', 200);
            }));
    expect(requests, ['GET /api/Fatura', 'PUT /api/Irsaliye/Complete/id']);
  });
  test(
      'portal requires module record; e-document sending requires read permission',
      () {
    activate([permission(301)]);
    expect(
        () => secured.checkRequest(
            'POST', Uri.parse('${ApiConfig.baseUrl}/Fatura/portala-gonder/id')),
        returnsNormally);
    expect(
        () => secured.checkRequest('POST',
            Uri.parse('${ApiConfig.eBelgeBaseUrl}/EFatura/send-invoice')),
        throwsA(isA<YetkiHatasi>()));
  });
  test('old token cannot be used in the new active branch session', () {
    AuthorizationSession.instance.activate([permission(301, read: true)],
        branch: 1, company: 3, environment: 'canli', token: 'new-token');
    expect(
        () => secured.checkRequest(
            'GET', Uri.parse('${ApiConfig.baseUrl}/Fatura'),
            headers: {'Authorization': 'Bearer old-token'}),
        throwsA(isA<YetkiHatasi>()));
  });
  test('list cache is isolated by user and branch, and read permission',
      () async {
    final rows = [
      permission(201, read: true),
      permission(201, branch: 2, read: true)
    ];
    activate(rows);
    await ListCacheService.instance.save('cari_list', [
      {'Id': 42}
    ]);
    expect(ListCacheService.instance.read('cari_list'), [
      {'Id': 42}
    ]);
    activate(rows, account: '5:99');
    expect(ListCacheService.instance.read('cari_list'), null);
    activate(rows, branch: 2);
    expect(ListCacheService.instance.read('cari_list'), null);
    activate([permission(201)]);
    expect(ListCacheService.instance.read('cari_list'), null);
  });
  testWidgets(
      'route guard never mounts unauthorized entry page or runs its lookups',
      (tester) async {
    activate([permission(101, read: true)]);
    var requests = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: PermissionPage(child: StokEklePage())));
      await tester.pumpAndSettle();
      expect(find.text('Yetkisiz İşlem'), findsOneWidget);
      expect(find.byType(StokEklePage), findsNothing);
    },
        () => MockClient((_) async {
              requests++;
              return http.Response('{"Data":[]}', 200);
            }));
    expect(requests, 0);
  });
  for (final design in ErpDesign.values) {
    testWidgets(
        '${design.name} home hides unauthorized groups and saved shortcuts; summary makes no extra calls',
        (tester) async {
      activate([permission(301, read: true)]);
      SharedPreferences.setMockInitialValues({
        'modern_quick_access_v1_user': ['Fatura', 'Stok', 'Cari'],
        'dashboard_quick_access_v1_user': ['Fatura', 'Stok', 'Cari']
      });
      final requests = <String>[];
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(Brightness.light, design: design),
              home: Scaffold(
                  body: design == ErpDesign.modern
                      ? AnaSayfaYeniTasarimPage(
                          kullanici: 'user',
                          firma: '',
                          sube: '',
                          aksiyonlar: {
                              for (final t in [
                                'Fatura',
                                'Stok',
                                'Cari',
                                'Finans'
                              ])
                                t: () {}
                            })
                      : MobileDashboard(
                          userName: 'user',
                          company: '',
                          branch: '',
                          sales: [
                            DashboardModule('Fatura', '', Icons.receipt, () {})
                          ],
                          inventory: [
                            DashboardModule('Stok', '', Icons.inventory, () {})
                          ],
                          finance: [
                            DashboardModule('Cari', '', Icons.people, () {})
                          ],
                          onReports: () {}))));
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pumpAndSettle();
        expect(find.text('Fatura'), findsWidgets);
        expect(find.text('Stok'), findsNothing);
        expect(find.text('Cari'), findsNothing);
        expect(find.text('Finans'), findsNothing);
        expect(find.text('Raporlar'), findsNothing);
        expect(requests.where((p) => p != '/api/Fatura'), isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((r) async {
                requests.add(r.url.path);
                return http.Response('{"Data":[]}', 200);
              }));
    });
    testWidgets(
        '${design.name} invoice menu and read-only actions respect permissions',
        (tester) async {
      activate([permission(301, read: true)]);
      final actions = DocumentActionsSheet(
          moduleId: 301,
          actions: [
            DocumentAction('Faturayı Düzenle', Icons.edit, Colors.blue, () {}),
            DocumentAction('Belgeyi Tamamla', Icons.check, Colors.green, () {}),
            DocumentAction('Fişi Yazdır', Icons.print, Colors.blue, () {}),
          ],
          electronicActions: [
            DocumentAction('Portala Gönder', Icons.cloud, Colors.purple, () {})
          ],
          deleteAction:
              DocumentAction('Faturayı Sil', Icons.delete, Colors.red, () {}));
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(Brightness.light, design: design),
          home: Scaffold(body: actions)));
      await tester.pumpAndSettle();
      expect(find.text('Faturayı Düzenle'), findsNothing);
      expect(find.text('Faturayı Sil'), findsNothing);
      expect(find.text('Belgeyi Tamamla'), findsNothing);
      expect(find.text('Fişi Yazdır'), findsOneWidget);
      expect(find.text('Portala Gönder'), findsOneWidget);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ErpModuleMenu(title: 'Faturalar', design: design, items: [
        ErpModuleMenuTile(
            title: 'Satış Faturası', design: design, onTap: () {}),
        ErpModuleMenuTile(title: 'Alış Faturası', design: design, onTap: () {}),
      ]))));
      await tester.pumpAndSettle();
      expect(find.text('Satış Faturası'), findsOneWidget);
      expect(find.text('Alış Faturası'), findsNothing);
    });
  }
  test('finance and payable reports map only to their actual child modules',
      () {
    activate([permission(5044, read: true)]);
    expect(MenuAccess.visible('Finans'), isFalse);
    expect(MenuAccess.modules('Ödenecek Çekler', parent: 'Borç Çek Raporları'),
        [5038]);
    expect(MenuAccess.modules('Genel Rapor', parent: 'Borç Çek Raporları'),
        [5050]);
    final item = OfflineQueueItem(
        localId: 'local',
        type: 'single_full',
        payload: {},
        createdAt: DateTime(2026),
        ownerScope: 'test:5:42:3:4');
    expect(
        OfflineQueueItem.fromJson(item.toJson()).ownerScope, item.ownerScope);
    expect(
        OfflineQueueItem.fromJson({...item.toJson()}..remove('ownerScope'))
            .ownerScope,
        isNull);
  });
  testWidgets('allowed screens remount when the active branch changes',
      (tester) async {
    activate([]);
    var mounts = 0;
    await tester.pumpWidget(MaterialApp(
        home: PermissionPage(child: MountProbe(onMount: () => mounts++))));
    expect(mounts, 1);
    activate([], branch: 2);
    await tester.pump();
    expect(mounts, 2);
  });
  testWidgets('read-only cheque status action opens no mutation sheet',
      (tester) async {
    activate([permission(1007, read: true)]);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      ctx = context;
      return const Scaffold();
    })));
    await BordroDurumIslem.goster(ctx,
        prefix: 'Cekalinantahsil',
        id: '1',
        taslak: true,
        baslik: 'Bordro',
        yenile: () {});
    await tester.pumpAndSettle();
    expect(find.text('Belgeyi Tamamla'), findsNothing);
  });
  testWidgets(
      'report search cannot reveal an unauthorized report by its number',
      (tester) async {
    activate([permission(5001, read: true)]);
    await tester.pumpWidget(const MaterialApp(home: RaporMerkeziPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();
    expect(find.text('Cari Hesap Ekstresi'), findsNothing);
  });
}
