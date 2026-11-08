import 'package:hive/hive.dart';

class CacheManager<T> {
  final String boxName;
  final String dataKey;
  final String timeKey;

  CacheManager(this.boxName)
      : dataKey = '${boxName}_data',
        timeKey = '${boxName}_time';

  Future<Box> _box() async => await Hive.openBox(boxName);

  Future<void> save(List<T> data) async {
    final box = await _box();
    await box.put(dataKey, data);
    await box.put(timeKey, DateTime.now().toIso8601String());
  }

  Future<List<T>> get() async {
    final box = await _box();
    return (box.get(dataKey) as List?)?.cast<T>() ?? [];
  }

  Future<bool> isExpired(int minutes) async {
    final box = await _box();
    final timeStr = box.get(timeKey);
    if (timeStr == null) return true;

    final time = DateTime.parse(timeStr);
    return DateTime.now().difference(time).inMinutes > minutes;
  }

  Future<DateTime?> lastUpdate() async {
    final box = await _box();
    final t = box.get(timeKey);
    return t == null ? null : DateTime.parse(t);
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}
