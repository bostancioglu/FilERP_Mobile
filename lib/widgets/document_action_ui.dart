import 'package:flutter/material.dart';
import 'permission_page.dart';
import '../services/auth/authorization_session.dart';

class DocumentAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const DocumentAction(this.label, this.icon, this.color, this.onTap);
}

class DocumentActionsSheet extends StatelessWidget {
  final int moduleId;
  final bool canModify;
  final List<DocumentAction> actions, electronicActions;
  final DocumentAction deleteAction;
  const DocumentActionsSheet(
      {super.key,
      required this.moduleId,
      this.canModify = true,
      required this.actions,
      required this.electronicActions,
      required this.deleteAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final permittedElectronicActions = electronicActions
        .where((a) => ActionAccess.allowed([moduleId], a.label))
        .toList();
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
        );
    Widget tile(DocumentAction action) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minTileHeight: 50,
          leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: action.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(action.icon, color: action.color, size: 19)),
          title: Text(action.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: action == deleteAction
                      ? scheme.error
                      : scheme.onSurface)),
          trailing: Icon(Icons.chevron_right_rounded,
              size: 18, color: scheme.outline),
          onTap: action.onTap,
        );
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
      child: SingleChildScrollView(
          child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      heading('Belge İşlemleri'),
                      ...actions
                          .where((a) => ActionAccess.allowed(
                              [moduleId], a.label,
                              allowChanges: canModify))
                          .map(tile),
                      if (permittedElectronicActions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Material(
                            color: scheme.primary.withValues(alpha: .045),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: .6)),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  heading('Gönderim'),
                                  ...permittedElectronicActions.map(tile),
                                ])),
                      ],
                      const SizedBox(height: 8),
                      if (ActionAccess.allowed([moduleId], deleteAction.label,
                          allowChanges: canModify))
                        tile(deleteAction),
                    ]),
              ))),
    );
  }
}

class DocumentSendDialog extends StatelessWidget {
  final String title, documentNumber;
  final bool portal;
  const DocumentSendDialog(
      {super.key,
      required this.title,
      required this.documentNumber,
      this.portal = false});

  static Future<bool> show(BuildContext context,
          {required String title,
          required String documentNumber,
          bool portal = false}) async =>
      await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => DocumentSendDialog(
              title: title, documentNumber: documentNumber, portal: portal)) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final color = portal ? const Color(0xFF7C3AED) : const Color(0xFF0F766E);
    final icon = portal ? Icons.cloud_upload_outlined : Icons.send_rounded;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(18)),
                          child: Icon(icon, color: color, size: 28))),
                  const SizedBox(height: 18),
                  Text(title,
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: s.onSurface)),
                  const SizedBox(height: 14),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: s.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 20, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(documentNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)))
                      ])),
                  const SizedBox(height: 14),
                  Text(
                      portal
                          ? 'Belge e-belge portalına aktarılsın mı?'
                          : 'Gerçek e-belge gönderimini onaylıyor musunuz?',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: s.onSurfaceVariant)),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                      icon: Icon(icon, size: 19),
                      label: Text(
                          portal ? 'Portala Gönder' : 'Oluştur ve Gönder')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: s.onSurfaceVariant,
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: s.outlineVariant),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                      child: const Text('Vazgeç')),
                ]),
          ))),
    );
  }
}

class InvoiceCompletedDialog extends StatelessWidget {
  const InvoiceCompletedDialog({super.key});
  static Future<String?> show(BuildContext context) => showDialog<String>(
      context: context, builder: (_) => const InvoiceCompletedDialog());

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFE2F6EC),
                          child: Icon(Icons.check_rounded,
                              color: Color(0xFF15803D), size: 28))),
                  const SizedBox(height: 16),
                  const Text('Fatura Tamamlandı',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  if (AuthorizationSession.instance.can(1025, Access.create) &&
                      AuthorizationSession.instance.can(1025, Access.read))
                    FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'tahsilat'),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        icon: const Icon(Icons.payments_outlined, size: 21),
                        label: const Text('Tahsilat Yap')),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'yazdir'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                      icon: const Icon(Icons.print_outlined, size: 21),
                      label: const Text('Yazdır')),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'kapat'),
                      style: TextButton.styleFrom(
                          foregroundColor: s.onSurfaceVariant,
                          minimumSize: const Size.fromHeight(44)),
                      child: const Text('Kapat')),
                ]),
          ))),
    );
  }
}
