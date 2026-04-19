import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/email_settings.dart';

final emailSettingsProvider =
    AsyncNotifierProvider<EmailSettingsNotifier, EmailSettings>(EmailSettingsNotifier.new);

class EmailSettingsNotifier extends AsyncNotifier<EmailSettings> {
  static const _prefsKey = 'vdti_email_settings';

  @override
  Future<EmailSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return EmailSettings.defaults;
    return EmailSettings.fromJsonString(raw);
  }

  Future<void> save(EmailSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, settings.toJsonString());
      return settings;
    });
  }
}

