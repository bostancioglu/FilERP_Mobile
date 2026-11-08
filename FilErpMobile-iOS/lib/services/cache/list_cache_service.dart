import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../auth/authorization_session.dart';

/// Basit liste önbellek servisi — Cari/Stok gibi ağır listeleri son çekilen
/// haliyle diskte tutar, offline iken (veya istek başarısız olduğunda) bu
/// önbellekten okunur. Ham API JSON'ı ("Data" altındaki liste) saklanır,
/// çağıran servis kendi DTO'suna map eder.
class ListCacheService {
  ListCacheService._();
  static final ListCacheService instance = ListCacheService._();

  static const _boxName = 'list_cache';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> save(String key, List<dynamic> rawList) async {
    final scope = AuthorizationSession.instance.cacheScope;
    if (scope == null || !_allowed(key)) return;
    await _box.put('$scope|$key', jsonEncode(rawList));
  }

  List<dynamic>? read(String key) {
    final scope = AuthorizationSession.instance.cacheScope;
    if (scope == null || !_allowed(key)) return null;
    final raw = _box.get('$scope|$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _allowed(String key) => key.startsWith('cari')
      ? AuthorizationSession.instance.can(201, Access.read)
      : key.startsWith('stok')
          ? AuthorizationSession.instance.can(101, Access.read)
          : true;
}
