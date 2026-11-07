import 'dart:convert';

/// The company/user parameters are refreshed by the final branch-login token.
class UserParameters {
  static const claimName = 'G129-134F-4323';
  final bool automaticElectronicSend;
  const UserParameters({this.automaticElectronicSend = false});

  factory UserParameters.fromToken(String? token) {
    try {
      final parts = (token ?? '').split('.');
      if (parts.length != 3) return const UserParameters();
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is! Map) return const UserParameters();
      var parameters = payload[claimName];
      if (parameters is String) parameters = jsonDecode(parameters);
      if (parameters is! Map) return const UserParameters();
      final value = parameters.entries
          .where(
              (e) => e.key.toString().toLowerCase() == 'otomatikefaturagonder')
          .firstOrNull
          ?.value;
      final yes = value == true ||
          value == 1 ||
          (value is String &&
              const ['true', 'evet', '1'].contains(value.trim().toLowerCase()));
      return UserParameters(automaticElectronicSend: yes);
    } catch (_) {
      return const UserParameters();
    }
  }
}
