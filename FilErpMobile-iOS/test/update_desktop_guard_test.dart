import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/services/update/update_service.dart';

void main() {
  test('desktop never fetches or installs an Android APK', () async {
    if (Platform.isAndroid) return;
    expect(await UpdateService.instance.checkForUpdate(), isNull);
    await expectLater(
      UpdateService.instance.downloadAndInstall(UpdateInfo(
        versionCode: 999, versionName: 'test',
        downloadUrl: 'https://invalid.example/test.apk', releaseNotes: '',
      )),
      throwsUnsupportedError,
    );
  });
}
