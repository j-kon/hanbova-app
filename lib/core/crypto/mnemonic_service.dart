import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'bip39_words.dart';

class MnemonicService {
  static final _wordSet = bip39EnglishWords.toSet();
  static final _wordMap = {for (int i = 0; i < bip39EnglishWords.length; i++) bip39EnglishWords[i]: i};

  /// Generates a new cryptographically secure 12-word BIP-39 mnemonic.
  static Future<String> generateMnemonic() async {
    final random = Random.secure();
    final entropy = Uint8List(16); // 128 bits
    for (int i = 0; i < 16; i++) {
      entropy[i] = random.nextInt(256);
    }

    // SHA-256 hash of entropy for checksum
    final sha256 = Sha256();
    final hash = await sha256.hash(entropy);
    final checksumByte = hash.bytes[0];

    // Combine 128 bits of entropy + 4 bits of checksum = 132 bits = 12 * 11 bits
    final bits = <int>[];
    for (final byte in entropy) {
      for (int i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    for (int i = 7; i >= 4; i--) {
      bits.add((checksumByte >> i) & 1);
    }

    // Convert 11-bit chunks into word indices
    final words = <String>[];
    for (int i = 0; i < 12; i++) {
      int index = 0;
      for (int j = 0; j < 11; j++) {
        index = (index << 1) | bits[i * 11 + j];
      }
      words.add(bip39EnglishWords[index]);
    }

    return words.join(' ');
  }

  /// Validates whether a given mnemonic string is a valid 12-word BIP-39 phrase.
  static Future<bool> validateMnemonic(String mnemonic) async {
    final words = mnemonic.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length != 12) return false;

    final indices = <int>[];
    for (final word in words) {
      final idx = _wordMap[word];
      if (idx == null) return false;
      indices.add(idx);
    }

    // Convert 12 * 11-bit indices back to 132 bits
    final bits = <int>[];
    for (final idx in indices) {
      for (int i = 10; i >= 0; i--) {
        bits.add((idx >> i) & 1);
      }
    }

    // First 128 bits are entropy
    final entropy = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        byte = (byte << 1) | bits[i * 8 + j];
      }
      entropy[i] = byte;
    }

    // Remaining 4 bits are checksum
    int expectedChecksum = 0;
    for (int i = 128; i < 132; i++) {
      expectedChecksum = (expectedChecksum << 1) | bits[i];
    }

    final sha256 = Sha256();
    final hash = await sha256.hash(entropy);
    final actualChecksum = (hash.bytes[0] >> 4) & 0x0F;

    return expectedChecksum == actualChecksum;
  }

  /// Autocomplete lookup for BIP-39 words matching a prefix.
  static List<String> getWordSuggestions(String prefix, {int limit = 5}) {
    final clean = prefix.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final matches = <String>[];
    for (final word in bip39EnglishWords) {
      if (word.startsWith(clean)) {
        matches.add(word);
        if (matches.length >= limit) break;
      }
    }
    return matches;
  }

  /// Check if a single word is in the BIP-39 dictionary.
  static bool isValidWord(String word) {
    return _wordSet.contains(word.trim().toLowerCase());
  }
}
