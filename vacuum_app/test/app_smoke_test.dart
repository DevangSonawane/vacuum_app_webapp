import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacuum_app/core/network/api_client.dart';
import 'package:vacuum_app/core/storage/token_storage.dart';
import 'package:vacuum_app/main.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> deleteToken() async {
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }
}

void main() {
  testWidgets('Shows Login screen when unauthenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_MemoryTokenStorage())],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}

