import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/bip39_words.dart';
import 'package:hanbova_app/core/crypto/mnemonic_service.dart';

void main() {
  group('BIP-39 Mnemonic Service Tests', () {
    test('BIP-39 wordlist contains exactly 2048 words', () {
      expect(bip39EnglishWords.length, 2048);
      expect(bip39EnglishWords.first, 'abandon');
      expect(bip39EnglishWords.last, 'zoo');
    });

    test('generateMnemonic produces a valid 12-word phrase with valid checksum', () async {
      for (int i = 0; i < 5; i++) {
        final phrase = await MnemonicService.generateMnemonic();
        final words = phrase.split(' ');

        expect(words.length, 12);
        for (final word in words) {
          expect(MnemonicService.isValidWord(word), isTrue, reason: 'Word "$word" must be in BIP-39 wordlist');
        }

        final isValid = await MnemonicService.validateMnemonic(phrase);
        expect(isValid, isTrue, reason: 'Generated phrase "$phrase" must be valid');
      }
    });

    test('validateMnemonic rejects invalid phrases', () async {
      // 1. Wrong length (11 words)
      expect(
        await MnemonicService.validateMnemonic('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'),
        isFalse,
      );

      // 2. Non-dictionary word
      expect(
        await MnemonicService.validateMnemonic('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon fakebipword'),
        isFalse,
      );

      // 3. Checksum failure (12 valid words, but wrong checksum bits)
      expect(
        await MnemonicService.validateMnemonic('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'),
        isFalse,
      );
    });

    test('getWordSuggestions finds matching prefixes', () {
      final suggestions = MnemonicService.getWordSuggestions('aban');
      expect(suggestions, contains('abandon'));

      final satisfySuggestions = MnemonicService.getWordSuggestions('sat');
      expect(satisfySuggestions, contains('satisfy'));

      final none = MnemonicService.getWordSuggestions('xyz123');
      expect(none.isEmpty, isTrue);
    });
  });
}
