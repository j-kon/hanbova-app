import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/transaction_model.dart';
import 'transaction_ledger.dart';

final class SecureTransactionLedger implements TransactionLedger {
  static const schemaVersion = 1;
  static const maxEntries = 500;

  final FlutterSecureStorage storage;
  final DateTime Function() _now;

  SecureTransactionLedger({
    required this.storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  String _key(String walletKey) => 'hanbova_ledger_v1_$walletKey';

  String _quarantineKey(String walletKey) =>
      'hanbova_ledger_corrupt_${_now().toUtc().microsecondsSinceEpoch}_$walletKey';

  @override
  Future<List<TransactionModel>> load(String walletKey) async {
    final key = _key(walletKey);
    final raw = await storage.read(key: key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != schemaVersion ||
          decoded['transactions'] is! List) {
        throw const FormatException('Unsupported transaction ledger.');
      }
      final records = (decoded['transactions'] as List).map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid transaction record.');
        }
        return TransactionModel.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(records.take(maxEntries));
    } catch (_) {
      await storage.write(key: _quarantineKey(walletKey), value: raw);
      await storage.delete(key: key);
      return const [];
    }
  }

  @override
  Future<void> upsert(
    String walletKey,
    TransactionModel transaction,
  ) async {
    final records = List<TransactionModel>.of(await load(walletKey));
    records.removeWhere((item) => item.id == transaction.id);
    records.add(transaction);
    await replace(walletKey, records);
  }

  @override
  Future<void> replace(
    String walletKey,
    List<TransactionModel> transactions,
  ) async {
    final byId = <String, TransactionModel>{};
    for (final transaction in transactions) {
      byId[transaction.id] = transaction;
    }
    final normalized = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final capped = normalized.take(maxEntries).toList(growable: false);
    await storage.write(
      key: _key(walletKey),
      value: jsonEncode({
        'version': schemaVersion,
        'transactions': capped.map((item) => item.toJson()).toList(),
      }),
    );
  }
}
