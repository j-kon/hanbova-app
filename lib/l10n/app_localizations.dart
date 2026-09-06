import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @recoveryPhraseBackup.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase Backup'**
  String get recoveryPhraseBackup;

  /// No description provided for @walletUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Wallet unavailable'**
  String get walletUnavailable;

  /// No description provided for @couldNotLoadRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recovery phrase.'**
  String get couldNotLoadRecoveryPhrase;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @secretRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Secret Recovery Phrase'**
  String get secretRecoveryPhrase;

  /// No description provided for @recoveryPhraseSafetyNotice.
  ///
  /// In en, this message translates to:
  /// **'Write these 12 words down in order on paper. Never share them or take a digital screenshot.'**
  String get recoveryPhraseSafetyNotice;

  /// No description provided for @revealTwelveWords.
  ///
  /// In en, this message translates to:
  /// **'Tap to Reveal 12 Words'**
  String get revealTwelveWords;

  /// No description provided for @continueAfterBackup.
  ///
  /// In en, this message translates to:
  /// **'I Have Written It Down → Continue'**
  String get continueAfterBackup;

  /// No description provided for @verifyRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Verify Recovery Phrase'**
  String get verifyRecoveryPhrase;

  /// No description provided for @verifyRecoveryPhraseDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the correct words corresponding to their positions to confirm your backup.'**
  String get verifyRecoveryPhraseDescription;

  /// No description provided for @wordPosition.
  ///
  /// In en, this message translates to:
  /// **'Word #{position}'**
  String wordPosition(int position);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @verifyAndCompleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Verify & Complete Backup'**
  String get verifyAndCompleteBackup;

  /// No description provided for @walletSuccessfullyBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Wallet Successfully Backed Up!'**
  String get walletSuccessfullyBackedUp;

  /// No description provided for @backupSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Your 12-word recovery phrase has been verified for this test environment. In this beta build, your cryptographic keys remain securely stored on this device.'**
  String get backupSuccessDescription;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @restoreFromPhrase.
  ///
  /// In en, this message translates to:
  /// **'Restore from Phrase'**
  String get restoreFromPhrase;

  /// No description provided for @enterTwelveWordPhrase.
  ///
  /// In en, this message translates to:
  /// **'Enter Your 12-Word Phrase'**
  String get enterTwelveWordPhrase;

  /// No description provided for @enterRecoveryPhraseDescription.
  ///
  /// In en, this message translates to:
  /// **'Type in your recovery words in the exact sequence they were generated.'**
  String get enterRecoveryPhraseDescription;

  /// No description provided for @restoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get restoreWallet;

  /// No description provided for @signInToRestoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Sign in to restore your wallet'**
  String get signInToRestoreWallet;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @replaceWallet.
  ///
  /// In en, this message translates to:
  /// **'Replace Wallet'**
  String get replaceWallet;

  /// No description provided for @replaceWalletIdentity.
  ///
  /// In en, this message translates to:
  /// **'Replace wallet identity?'**
  String get replaceWalletIdentity;

  /// No description provided for @replaceWalletIdentityDescription.
  ///
  /// In en, this message translates to:
  /// **'This replaces the wallet identity for the signed-in account in this wallet environment.'**
  String get replaceWalletIdentityDescription;

  /// No description provided for @walletRestored.
  ///
  /// In en, this message translates to:
  /// **'Wallet Restored'**
  String get walletRestored;

  /// No description provided for @walletRestoredSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Wallet Restored — Sync Pending'**
  String get walletRestoredSyncPending;

  /// No description provided for @goToWallet.
  ///
  /// In en, this message translates to:
  /// **'Go to Wallet'**
  String get goToWallet;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get retrySync;

  /// No description provided for @restoreAllWordsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all 12 words of your recovery phrase'**
  String get restoreAllWordsRequired;

  /// No description provided for @invalidRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Invalid recovery phrase or checksum mismatch. Please check spelling.'**
  String get invalidRecoveryPhrase;

  /// No description provided for @syncStillPending.
  ///
  /// In en, this message translates to:
  /// **'Payment-key sync is still pending.'**
  String get syncStillPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
