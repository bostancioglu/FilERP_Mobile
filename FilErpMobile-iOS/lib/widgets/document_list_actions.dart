import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../helpers/ui_feedback.dart';
import '../services/auth/authorization_session.dart';
import '../services/ebelge/ebelge_service.dart';
import '../services/ebelge/portal_service.dart';
import 'document_action_ui.dart';
import 'permission_page.dart';

/// Shared by sales/purchase lists; only sales documents have a send action.
class DocumentListActions extends StatefulWidget {
  final int module, status, electronicStatus;
  final String id, number;
  final PortalDocument? document;
  final Future<void> Function(int status) onStatusChange;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onEdit, onDelete;
  const DocumentListActions(
      {super.key,
      required this.module,
      required this.id,
      required this.number,
      required this.status,
      required this.electronicStatus,
      required this.onStatusChange,
      required this.onRefresh,
      this.document,
      this.onEdit,
      this.onDelete});
  @override
  State<DocumentListActions> createState() => _DocumentListActionsState();
}

class _DocumentListActionsState extends State<DocumentListActions> {
  bool _busy = false;
  String get _sendLabel => AuthorizationSession.instance.automaticElectronicSend
      ? (widget.document == PortalDocument.invoice
          ? 'E-Fatura Gönder'
          : 'E-İrsaliye Gönder')
      : 'Portala Gönder';

  Future<void> _send() async {
    if (_busy) return;
    _busy = true;
    OverlayEntry? progress;
    final session = AuthorizationSession.instance;
    final revision = session.revision;
    final electronic = session.automaticElectronicSend;
    try {
      final confirmed = await DocumentSendDialog.show(context,
          title: electronic
              ? '$_sendLabel · ${ApiConfig.serverType == ServerType.canli ? 'CANLI' : 'TEST'}'
              : _sendLabel,
          documentNumber: widget.number,
          portal: !electronic);
      if (!confirmed ||
          !mounted ||
          revision != session.revision ||
          !ActionAccess.allowed([widget.module], _sendLabel)) return;
      progress = UiFeedback.showLoading(context, text: 'Belge gönderiliyor...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      if (electronic) {
        await EBelgeService().send(
            token: token,
            id: widget.id,
            companyId: prefs.getInt('sirket_id') ?? 0,
            document: widget.document!);
      } else {
        await PortalService().send(token, widget.id, widget.document!);
      }
      UiFeedback.hideLoading(progress);
      progress = null;
      if (!mounted || revision != session.revision) return;
      await widget.onRefresh();
      if (mounted)
        UiFeedback.showSent(context,
            electronic ? 'E-belge gönderildi' : 'Belge portala gönderildi');
    } catch (error) {
      if (progress != null) {
        UiFeedback.hideLoading(progress);
        progress = null;
      }
      if (!mounted || revision != session.revision) return;
      if (error is EBelgeUncertain) {
        await widget.onRefresh();
        if (!mounted) return;
        await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text('Gönderim Sonucu'),
                    content: Text(error.toString()),
                    actions: [
                      ErpDialogAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tamam'))
                    ]));
      } else {
        UiFeedback.showException(context, error);
      }
    } finally {
      if (progress != null) UiFeedback.hideLoading(progress);
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: AuthorizationSession.instance,
      builder: (context, _) {
        final session = AuthorizationSession.instance;
        final draft = widget.status == 0;
        final change = (draft || widget.status == 1) &&
            session.can(widget.module, Access.create);
        final supportsSend = (widget.module == 301 &&
                widget.document == PortalDocument.invoice) ||
            (widget.module == 501 && widget.document == PortalDocument.waybill);
        final send = supportsSend &&
            widget.status == 1 &&
            (widget.electronicStatus == 0 ||
                (session.automaticElectronicSend &&
                    widget.electronicStatus == 1)) &&
            ActionAccess.allowed([widget.module], _sendLabel);
        final edit = draft &&
            widget.onEdit != null &&
            session.can(widget.module, Access.update);
        final delete = draft &&
            widget.onDelete != null &&
            session.can(widget.module, Access.delete);
        if (widget.id.isEmpty || !(change || send || edit || delete))
          return const SizedBox.shrink();
        PopupMenuItem<String> item(
                String value, String label, IconData icon, Color color) =>
            PopupMenuItem(
                value: value,
                child: Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontSize: 13))
                ]));
        return PopupMenuButton<String>(
            tooltip: 'Belge İşlemleri',
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            onSelected: (value) async {
              if (_busy) return;
              if (value == 'send') {
                await _send();
                return;
              }
              if (value == 'edit') {
                if (widget.status != 0 ||
                    !session.can(widget.module, Access.update)) return;
                _busy = true;
                try {
                  await widget.onEdit?.call();
                } finally {
                  _busy = false;
                }
                return;
              }
              if (value == 'delete') {
                if (widget.status != 0 ||
                    !session.can(widget.module, Access.delete)) return;
                _busy = true;
                try {
                  await widget.onDelete?.call();
                } finally {
                  _busy = false;
                }
                return;
              }
              if (!session.can(widget.module, Access.create)) return;
              _busy = true;
              try {
                await widget.onStatusChange(draft ? 1 : 0);
              } finally {
                _busy = false;
              }
            },
            itemBuilder: (_) => [
                  if (edit)
                    item('edit', 'Düzenle', Icons.edit_outlined,
                        const Color(0xFF2563EB)),
                  if (change)
                    item(
                        'status',
                        draft ? 'Belgeyi Tamamla' : 'Taslağa Çek',
                        draft
                            ? Icons.check_circle_outline_rounded
                            : Icons.undo_rounded,
                        draft
                            ? const Color(0xFF15803D)
                            : const Color(0xFFD97706)),
                  if (send)
                    item(
                        'send',
                        _sendLabel,
                        session.automaticElectronicSend
                            ? Icons.send_rounded
                            : Icons.cloud_upload_outlined,
                        const Color(0xFF0F766E)),
                  if (delete && (edit || change || send))
                    const PopupMenuDivider(),
                  if (delete)
                    item('delete', 'Sil', Icons.delete_outline_rounded,
                        Theme.of(context).colorScheme.error),
                ]);
      });
}
