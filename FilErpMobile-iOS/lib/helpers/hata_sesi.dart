import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hata anında yüksek sesli uyarı (+ titreşim). Gürültülü depo / saha ortamında ekrana
/// bakmadan hatayı fark ettirmek için; el terminali ve telefonda çalışır.
///
/// Ses, Android'de "alarm" akışından çalınır: medya sesi kısık / sessiz olsa bile duyulur
/// (alarm ses seviyesine bağlıdır).
///
/// ARAYÜZÜ ASLA BEKLETMEZ: çağrı hemen döner, çalma arka planda yapılır. Ses çalınamazsa
/// (emülatör, ses aygıtı yok vb.) sessizce titreşim / sistem sesine düşer; arka arkaya gelen
/// hatalarda ses üst üste bindirilmez.
class HataSesi {
  HataSesi._();

  static AudioPlayer? _player;
  static bool _hazir = false;
  static DateTime? _son;
  static bool _calisiyor = false;

  /// Senkron çağrılır (await gerekmez).
  static void cal() {
    final simdi = DateTime.now();
    if (_son != null && simdi.difference(_son!) < const Duration(milliseconds: 700)) return;
    _son = simdi;

    // Titreşim her durumda (ses kapalı olsa da hissedilsin)
    HapticFeedback.heavyImpact();
    unawaited(_sesiCal());
  }

  static Future<void> _sesiCal() async {
    if (_calisiyor) return;
    _calisiyor = true;
    try {
      final p = _player ??= AudioPlayer();
      if (!_hazir) {
        await p
            .setAudioContext(AudioContext(
              android: const AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.alarm,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              ),
              iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
            ))
            .timeout(const Duration(seconds: 2));
        await p.setReleaseMode(ReleaseMode.stop).timeout(const Duration(seconds: 2));
        _hazir = true;
      }
      await p.setVolume(1.0).timeout(const Duration(seconds: 2));
      await p.play(AssetSource('sounds/hata.wav'), volume: 1.0).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Hata sesi çalınamadı: $e');
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    } finally {
      _calisiyor = false;
    }
  }
}
