// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get recoveryPhraseBackup => 'Recovery Phrase Backup';

  @override
  String get walletUnavailable => 'Wallet unavailable';

  @override
  String get couldNotLoadRecoveryPhrase =>
      'Could not load the recovery phrase.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get secretRecoveryPhrase => 'Secret Recovery Phrase';

  @override
  String get recoveryPhraseSafetyNotice =>
      'Write these 12 words down in order on paper. Never share them or take a digital screenshot.';

  @override
  String get revealTwelveWords => 'Tap to Reveal 12 Words';

  @override
  String get continueAfterBackup => 'I Have Written It Down → Continue';

  @override
  String get verifyRecoveryPhrase => 'Verify Recovery Phrase';

  @override
  String get verifyRecoveryPhraseDescription =>
      'Select the correct words corresponding to their positions to confirm your backup.';

  @override
  String wordPosition(int position) {
    return 'Word #$position';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get verifyAndCompleteBackup => 'Verify & Complete Backup';

  @override
  String get walletSuccessfullyBackedUp => 'Wallet Successfully Backed Up!';

  @override
  String get backupSuccessDescription =>
      'Your 12-word recovery phrase has been verified for this test environment. In this beta build, your cryptographic keys remain securely stored on this device.';

  @override
  String get done => 'Done';

  @override
  String get restoreFromPhrase => 'Restore from Phrase';

  @override
  String get enterTwelveWordPhrase => 'Enter Your 12-Word Phrase';

  @override
  String get enterRecoveryPhraseDescription =>
      'Type in your recovery words in the exact sequence they were generated.';

  @override
  String get restoreWallet => 'Restore Wallet';

  @override
  String get signInToRestoreWallet => 'Sign in to restore your wallet';

  @override
  String get signIn => 'Sign in';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get replaceWallet => 'Replace Wallet';

  @override
  String get replaceWalletIdentity => 'Replace wallet identity?';

  @override
  String get replaceWalletIdentityDescription =>
      'This replaces the wallet identity for the signed-in account in this wallet environment.';

  @override
  String get walletRestored => 'Wallet Restored';

  @override
  String get walletRestoredSyncPending => 'Wallet Restored — Sync Pending';

  @override
  String get goToWallet => 'Go to Wallet';

  @override
  String get retrySync => 'Retry sync';

  @override
  String get restoreAllWordsRequired =>
      'Please fill in all 12 words of your recovery phrase';

  @override
  String get invalidRecoveryPhrase =>
      'Invalid recovery phrase or checksum mismatch. Please check spelling.';

  @override
  String get syncStillPending => 'Payment-key sync is still pending.';
}
