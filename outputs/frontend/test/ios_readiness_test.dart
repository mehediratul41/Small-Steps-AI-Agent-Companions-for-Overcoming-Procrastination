import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/app/config.dart';

void main() {
  test('platform defaults keep Android alias off iPhone and browser', () {
    expect(
      AppConfig.defaultBackendUrl(TargetPlatform.android),
      'http://10.0.2.2:8000',
    );
    expect(
      AppConfig.defaultBackendUrl(TargetPlatform.iOS),
      'http://127.0.0.1:8000',
    );
    expect(
      AppConfig.defaultBackendUrl(TargetPlatform.android, web: true),
      'http://127.0.0.1:8000',
    );
  });
  test(
    'distribution policy requires HTTPS and rejects embedded credentials',
    () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        for (final url in [
          'http://localhost:8000',
          'http://127.0.0.1:8000',
          'http://10.0.2.2:8000',
          'http://192.168.1.2:8000',
          'https://user:password@example.test',
          'https://example.test?token=bad',
          'https://example.test#bad',
        ]) {
          expect(
            AppConfig.acceptsBackendUrl(
              url,
              development: false,
              platform: platform,
            ),
            false,
            reason: url,
          );
        }
        expect(
          AppConfig.acceptsBackendUrl(
            'https://api.example.test',
            development: false,
            platform: platform,
          ),
          true,
        );
      }
    },
  );
  test(
    'debug iOS only accepts loopback HTTP, never the Android emulator alias',
    () {
      expect(
        AppConfig.acceptsBackendUrl(
          'http://127.0.0.1:8000',
          platform: TargetPlatform.iOS,
        ),
        true,
      );
      expect(
        AppConfig.acceptsBackendUrl(
          'http://[::1]:8000',
          platform: TargetPlatform.iOS,
        ),
        true,
      );
      expect(
        AppConfig.acceptsBackendUrl(
          'http://10.0.2.2:8000',
          platform: TargetPlatform.iOS,
        ),
        false,
      );
      expect(
        AppConfig.acceptsBackendUrl(
          'http://192.168.1.2:8000',
          platform: TargetPlatform.iOS,
        ),
        false,
      );
      expect(
        AppConfig.acceptsBackendUrl(
          'http://10.0.2.2:8000',
          platform: TargetPlatform.android,
        ),
        true,
      );
    },
  );
  test(
    'release metadata has no ATS exception and debug has local-only exception',
    () {
      final release = File('ios/Runner/Info.plist').readAsStringSync();
      final debug = File('ios/Runner/Info-Debug.plist').readAsStringSync();
      expect(release, isNot(contains('NSAppTransportSecurity')));
      expect(debug, contains('NSAllowsLocalNetworking'));
      expect(debug, isNot(contains('NSAllowsArbitraryLoads')));
      expect(release, contains('<string>ja</string>'));
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(project, contains('FlutterGeneratedPluginSwiftPackage'));
      expect(
        RegExp(
          'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;',
        ).allMatches(project),
        hasLength(3),
      );
      expect(File('ios/Runner/Runner.entitlements').existsSync(), true);
    },
  );
  test('all referenced iOS app icons exist including marketing icon', () {
    final directory = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );
    final catalog =
        jsonDecode(File('${directory.path}/Contents.json').readAsStringSync())
            as Map;
    for (final entry in catalog['images'] as List) {
      expect(File('${directory.path}/${entry['filename']}').existsSync(), true);
    }
    final bytes = File(
      '${directory.path}/Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    expect(bytes.buffer.asByteData().getUint32(16), 1024);
    expect(bytes.buffer.asByteData().getUint32(20), 1024);
  });
}
