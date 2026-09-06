import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/l10n/app_localizations.dart';

void main() {
  testWidgets('English recovery strings are available through app delegates',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.recoveryPhraseBackup,
          ),
        ),
      ),
    );

    expect(find.text('Recovery Phrase Backup'), findsOneWidget);
  });
}
