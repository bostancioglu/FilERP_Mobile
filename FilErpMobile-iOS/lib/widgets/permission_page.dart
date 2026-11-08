import 'package:flutter/material.dart';
import '../services/auth/authorization_session.dart';
import '../services/auth/page_permission_catalog.dart';
import '../services/auth/menu_access.dart';

class PageAccess {
  static List<int> modules(Widget page) {
    final policy = pagePermissions[page.runtimeType.toString()];
    if (policy == null)
      return [-1]; // Internal selectors/dialogs use their owning route.
    final dynamic value = page;
    if (policy.dynamicKind == 'sales') return [value.sales == true ? 601 : 602];
    if (policy.dynamicKind == 'report')
      return MenuAccess.modules(value.tanim.baslik as String);
    if (policy.dynamicKind == 'center') return MenuAccess.reportModules;
    if (policy.dynamicKind?.startsWith('report:') == true) {
      return MenuAccess.modules(value.title as String,
          parent: policy.dynamicKind!.substring(7));
    }
    return policy.modules;
  }

  static Access access(Widget page) {
    final policy = pagePermissions[page.runtimeType.toString()];
    if (policy == null || policy.modules.contains(-1)) return Access.authorized;
    if (!policy.entry) return Access.read;
    final dynamic value = page;
    final existing = switch (policy.editField) {
      'editCari' => value.editCari,
      'editStok' => value.editStok,
      'editKasa' => value.editKasa,
      'editBanka' => value.editBanka,
      'editHareket' => value.editHareket,
      'editTahsilat' => value.editTahsilat,
      'quoteId' => value.quoteId,
      'faturaId' => value.faturaId,
      'irsaliyeId' => value.irsaliyeId,
      'siparisId' => value.siparisId,
      'datId' => value.datId,
      'ambargcId' => value.ambargcId,
      _ => null,
    };
    return existing == null ? Access.create : Access.update;
  }
}

class PermissionPage extends StatelessWidget {
  final Widget child;
  const PermissionPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AuthorizationSession.instance,
        builder: (context, _) {
          final type = child.runtimeType.toString();
          if (const ['LoginPage', 'SplashPage', 'SirketSubeSecimPage']
              .contains(type)) return child;
          final modules = PageAccess.modules(child);
          if (!AuthorizationSession.instance
              .any(modules, PageAccess.access(child))) {
            return Scaffold(
                appBar: AppBar(title: const Text('Yetkisiz İşlem')),
                body: const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Bu ekran için yetkiniz yok. Yetkileriniz değiştiyse tekrar giriş yapın.',
                            textAlign: TextAlign.center))));
          }
          return PermissionScope(
              key: ValueKey(AuthorizationSession.instance.revision),
              modules: modules,
              child: child);
        },
      );
}

class PermissionScope extends InheritedWidget {
  final List<int> modules;
  const PermissionScope(
      {super.key, required this.modules, required super.child});
  static List<int>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PermissionScope>()?.modules;
  @override
  bool updateShouldNotify(PermissionScope oldWidget) =>
      modules != oldWidget.modules;
}

class PermissionMaterialPageRoute<T> extends MaterialPageRoute<T> {
  PermissionMaterialPageRoute(
      {required WidgetBuilder builder,
      super.settings,
      super.maintainState,
      super.fullscreenDialog,
      super.allowSnapshotting,
      super.barrierDismissible})
      : super(builder: (context) => PermissionPage(child: builder(context)));
}

class PermissionAction extends StatelessWidget {
  final List<int> modules;
  final Access access;
  final Widget child;
  const PermissionAction(
      {super.key,
      required this.modules,
      required this.access,
      required this.child});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: AuthorizationSession.instance,
      builder: (_, __) => AuthorizationSession.instance.any(modules, access)
          ? child
          : const SizedBox.shrink());
}

class ActionAccess {
  static bool allowed(List<int> modules, String title,
      {bool allowChanges = true}) {
    final text = MenuAccess.normalize(title);
    if (text.contains('portala'))
      return !AuthorizationSession.instance.automaticElectronicSend &&
          AuthorizationSession.instance.any(modules);
    if (text.contains('e-fatura') || text.contains('e-irsaliye'))
      return AuthorizationSession.instance.automaticElectronicSend &&
          AuthorizationSession.instance.any(modules, Access.read);
    if (text.contains('tahsilat yap'))
      return AuthorizationSession.instance.can(1025, Access.create) &&
          AuthorizationSession.instance.can(1025, Access.read);
    final access = RegExp(r'(^|\s)sil($|\s)').hasMatch(text)
        ? Access.delete
        : text.contains('duzenle') || text.contains('guncelle')
            ? Access.update
            : text.contains('taslag') ||
                    text.contains('tamamla') ||
                    text.contains('yeni') ||
                    text.contains('ekle')
                ? Access.create
                : text.contains('kaydet')
                    ? Access.write
                    : Access.read;
    if (!allowChanges &&
        (access == Access.update ||
            access == Access.delete ||
            access == Access.write)) return false;
    return AuthorizationSession.instance.any(modules, access);
  }
}
