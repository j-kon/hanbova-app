import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/security/sensitive_screen_protection.dart';

final class RecordingSensitiveScreenGateway implements SensitiveScreenGateway {
  final List<bool> changes = [];

  @override
  Future<void> setEnabled(bool enabled) async => changes.add(enabled);
}

void main() {
  testWidgets('enables native protection while its child is visible',
      (tester) async {
    final gateway = RecordingSensitiveScreenGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sensitiveScreenGatewayProvider.overrideWithValue(gateway)],
        child: const MaterialApp(
          home: SensitiveScreenProtection(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    expect(gateway.changes, [true]);
  });

  testWidgets('disables native protection after its child is removed',
      (tester) async {
    final gateway = RecordingSensitiveScreenGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sensitiveScreenGatewayProvider.overrideWithValue(gateway)],
        child: const MaterialApp(
          home: SensitiveScreenProtection(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(gateway.changes, [true, false]);
  });
}
