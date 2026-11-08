import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plasiyer_konum_service.dart';

/// Uygulama ön plandayken (arka planda DEĞİL) periyodik olarak cihazın
/// konumunu backend'e gönderir. Kullanıcı "Benim Plasiyerim" seçmediyse
/// (Ayarlar'dan) hiçbir şey göndermez — sessizce no-op.
class PlasiyerKonumBroadcaster {
  PlasiyerKonumBroadcaster._();
  static final PlasiyerKonumBroadcaster instance = PlasiyerKonumBroadcaster._();

  static const _prefKey = 'benim_plasiyerid';
  static const _interval = Duration(seconds: 60);

  Timer? _timer;
  bool _sending = false;

  Future<void> setBenimPlasiyerId(int? plasiyerid) async {
    final prefs = await SharedPreferences.getInstance();
    if (plasiyerid == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setInt(_prefKey, plasiyerid);
    }
  }

  Future<int?> getBenimPlasiyerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKey);
  }

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_sending) return;
    _sending = true;
    try {
      final plasiyerid = await getBenimPlasiyerId();
      if (plasiyerid == null) return;

      final permission = await _ensurePermission();
      if (!permission) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      if (token.isEmpty) return;

      await PlasiyerKonumService().gonderKonum(
        token,
        plasiyerid: plasiyerid,
        enlem: pos.latitude,
        boylam: pos.longitude,
      );
    } catch (e) {
      debugPrint("Plasiyer konum gönderim hatası: $e");
    } finally {
      _sending = false;
    }
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    return true;
  }
}
