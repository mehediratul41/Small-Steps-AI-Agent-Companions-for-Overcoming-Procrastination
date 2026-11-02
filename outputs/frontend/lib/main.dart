import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/state.dart';
import 'app/reminders_controller.dart';
import 'data/services/device_reminders.dart';
import 'data/saved_connections.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans JP',
    ], await rootBundle.loadString('assets/fonts/NotoSansJP-OFL.txt'));
  });
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        connectionStorageProvider.overrideWithValue(
          !kIsWeb &&
                  [
                    TargetPlatform.android,
                    TargetPlatform.iOS,
                  ].contains(defaultTargetPlatform)
              ? SecureConnectionStorage()
              : MemoryConnectionStorage(),
        ),
        reminderServiceProvider.overrideWithValue(DeviceReminderService()),
      ],
      child: const SmallStepsApp(),
    ),
  );
}
