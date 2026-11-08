import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../main.dart' show appVersion;
import '../../services/login/login_service.dart';
import 'sirket_sube_secim_page.dart';
import '../../widgets/erp_auth_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool isLoading = false;
  bool autoFillEnabled = false;
  bool obscurePass = true;
  ServerType _selectedServer = ApiConfig.serverType;

  @override
  void initState() {
    super.initState();
    _loadDevCredentials();
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (ctx) => Theme(
            data: ErpAuthLayout.themeFor(context),
            child: AlertDialog(
                title: const Text('Giriş Başarısız'),
                content: Text(msg),
                actions: [
                  ErpDialogAction(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tamam'))
                ])));
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _showServerSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ErpAuthLayout.themeFor(context).colorScheme.surface,
        showDragHandle: false,
        builder: (ctx) => Theme(
            data: ErpAuthLayout.themeFor(context),
            child: Material(
                color: ErpAuthLayout.themeFor(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bağlantı Ortamı',
                                  style: TextStyle(
                                      color: ErpAuthLayout.themeFor(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              for (final type in ServerType.values)
                                RadioListTile<ServerType>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                        type == ServerType.canli
                                            ? 'Canlı'
                                            : 'Test',
                                        style: TextStyle(
                                            color:
                                                ErpAuthLayout.themeFor(context)
                                                    .colorScheme
                                                    .onSurface)),
                                    value: type,
                                    groupValue: _selectedServer,
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      await ApiConfig.setServer(value);
                                      if (!mounted || !ctx.mounted) return;
                                      setState(() => _selectedServer = value);
                                      Navigator.pop(ctx);
                                    }),
                            ]))))));
  }

  Future<void> _loadDevCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("dev_autofill") ?? false;
    if (!enabled || !mounted) return;
    setState(() {
      autoFillEnabled = true;
      userCtrl.text = prefs.getString("dev_username") ?? "";
      passCtrl.text = prefs.getString("dev_password") ?? "";
    });
  }

  Future<void> login() async {
    final user = userCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      _showError("Kullanıcı adı ve şifre boş olamaz");
      return;
    }

    setState(() => isLoading = true);

    try {
      final service = LoginService();
      final kullanici = await service.login(user, pass);

      if (autoFillEnabled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("dev_username", user);
        await prefs.setString("dev_password", pass);
        await prefs.setBool("dev_autofill", true);
      }

      if (!mounted) return;

      if (kullanici == null) {
        _showError("Kullanıcı adı veya şifre hatalı");
        return;
      }

      final lists = service.extractSirketSubeLists(kullanici);

      Navigator.pushReplacement(
        context,
        PermissionMaterialPageRoute(
          builder: (_) => SirketSubeSecimPage(
            sirketler: List.from(lists["Sirketler"]),
            subeler: List.from(lists["Subeler"]),
            kullaniciDetay: kullanici,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst("Exception:", "").trim();
        _showError(msg.isNotEmpty ? msg : "Giriş sırasında bir hata oluştu");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleAutoFill(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => autoFillEnabled = value);
    if (value) {
      await prefs.setBool('dev_autofill', true);
      await prefs.setString('dev_username', userCtrl.text.trim());
      await prefs.setString('dev_password', passCtrl.text.trim());
    } else {
      await prefs.remove('dev_username');
      await prefs.remove('dev_password');
      await prefs.setBool('dev_autofill', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ErpAuthLayout.themeFor(context),
        child: Builder(builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return ErpAuthLayout(
            onBrandLongPress: isLoading ? null : _showServerSheet,
            footer: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                      message: 'Ortam seçimi için basılı tutun',
                      child: InkWell(
                          key: const ValueKey('auth-environment'),
                          onLongPress: isLoading ? null : _showServerSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune_rounded,
                                        size: 14,
                                        color: scheme.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                        _selectedServer == ServerType.test
                                            ? 'Ortam · Test'
                                            : 'Ortam · Canlı',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant)),
                                  ])))),
                  if (appVersion.isNotEmpty)
                    Text('v$appVersion',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Giriş Yap',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: userCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          isDense: true,
                          prefixIcon:
                              Icon(Icons.person_outline_rounded, size: 20))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => login(),
                      decoration: InputDecoration(
                          labelText: 'Şifre',
                          isDense: true,
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                              tooltip: obscurePass
                                  ? 'Şifreyi Göster'
                                  : 'Şifreyi Gizle',
                              onPressed: () =>
                                  setState(() => obscurePass = !obscurePass),
                              icon: Icon(
                                  obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20)))),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Expanded(
                        child: Text('Otomatik Giriş',
                            style: TextStyle(fontSize: 12))),
                    Switch(value: autoFillEnabled, onChanged: _toggleAutoFill)
                  ]),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Giriş Yap')),
                ]),
          );
        }));
  }
}
