import 'package:flutter/material.dart';
import '../services/auth/authorization_session.dart';
import '../services/dashboard/admin_dashboard_service.dart';
import '../pages/admin_dashboard_page.dart';

class AdminDashboardButton extends StatelessWidget {
  const AdminDashboardButton({super.key});
  Future<bool> _allowed() async {
    try {
      return await AdminDashboardService().allowed();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AuthorizationSession.instance,
        builder: (context, _) => FutureBuilder<bool>(
          future: _allowed(),
          builder: (context, snapshot) => snapshot.data != true
              ? const SizedBox.shrink()
              : TextButton.icon(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Dashboard'),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const AdminDashboardPage())),
                ),
        ),
      );
}
