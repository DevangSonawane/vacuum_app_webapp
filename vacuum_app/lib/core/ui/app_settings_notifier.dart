import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, bool>(AppSettingsNotifier.new);

class AppSettingsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.darkModeKey) ?? false;
  }

  Future<void> toggleDarkMode() async {
    final current = state.valueOrNull ?? false;
    await setDarkMode(!current);
  }

  Future<void> setDarkMode(bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.darkModeKey, value);
      return value;
    });
  }
}

