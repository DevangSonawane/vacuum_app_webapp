import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/email_settings_repository.dart';
import '../domain/email_settings.dart';

final emailSettingsProvider =
    AsyncNotifierProvider<EmailSettingsNotifier, EmailSettings>(
      EmailSettingsNotifier.new,
    );

class EmailSettingsNotifier extends AsyncNotifier<EmailSettings> {
  EmailSettingsRepository get _repo =>
      ref.read(emailSettingsRepositoryProvider);

  @override
  Future<EmailSettings> build() async {
    return _repo.fetch();
  }

  Future<void> save(EmailSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _repo.upsert(settings);
    });
  }

  Future<void> sendTestEmail(String to) async {
    await _repo.sendTestEmail(to);
  }
}

final emailSettingsRepositoryProvider = Provider<EmailSettingsRepository>((ref) {
  return EmailSettingsRepository(dio: ref.read(dioProvider));
});
