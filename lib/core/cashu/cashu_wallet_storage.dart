import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/network_environment.dart';
import '../wallet/wallet_context.dart';
import 'cashu_wallet_models.dart';

class CashuWalletStorage {
  final FlutterSecureStorage _storage;

  CashuWalletStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _proofsKey(String userId, HanbovaNetwork network,
      {String? storagePrefix}) {
    final prefix =
        storagePrefix ?? NetworkConfig.fromNetwork(network).storagePrefix;
    return 'hanbova_${prefix}_${userId}_spendable_proofs';
  }

  String _escrowsKey(String userId, HanbovaNetwork network,
      {String? storagePrefix}) {
    final prefix =
        storagePrefix ?? NetworkConfig.fromNetwork(network).storagePrefix;
    return 'hanbova_${prefix}_${userId}_escrow_records';
  }

  /// Loads spendable Cashu proofs from secure persistent client storage.
  Future<List<CashuProof>> loadProofs(String userId, HanbovaNetwork network,
      {String? storagePrefix}) async {
    try {
      final jsonStr = await _storage.read(
          key: _proofsKey(userId, network, storagePrefix: storagePrefix));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => CashuProof.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves spendable Cashu proofs to secure persistent client storage.
  Future<void> saveProofs(
      String userId, HanbovaNetwork network, List<CashuProof> proofs,
      {String? storagePrefix}) async {
    final jsonStr = jsonEncode(proofs.map((p) => p.toJson()).toList());
    await _storage.write(
        key: _proofsKey(userId, network, storagePrefix: storagePrefix),
        value: jsonStr);
  }

  /// Loads protected escrow records (including client-side refund keys).
  Future<List<ProtectedEscrowRecord>> loadEscrowRecords(
      String userId, HanbovaNetwork network,
      {String? storagePrefix}) async {
    try {
      final jsonStr = await _storage.read(
          key: _escrowsKey(userId, network, storagePrefix: storagePrefix));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => ProtectedEscrowRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves or updates a protected escrow record.
  Future<void> saveEscrowRecord(
      String userId, HanbovaNetwork network, ProtectedEscrowRecord record,
      {String? storagePrefix}) async {
    final records =
        await loadEscrowRecords(userId, network, storagePrefix: storagePrefix);
    final idx = records.indexWhere((r) => r.paymentId == record.paymentId);
    if (idx >= 0) {
      records[idx] = record;
    } else {
      records.insert(0, record);
    }
    final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
    await _storage.write(
        key: _escrowsKey(userId, network, storagePrefix: storagePrefix),
        value: jsonStr);
  }

  /// Finds a specific protected escrow record by canonical payment ID.
  Future<ProtectedEscrowRecord?> getEscrowRecord(
      String userId, HanbovaNetwork network, String paymentId,
      {String? storagePrefix}) async {
    final records =
        await loadEscrowRecords(userId, network, storagePrefix: storagePrefix);
    try {
      return records.firstWhere((r) => r.paymentId == paymentId);
    } catch (_) {
      return null;
    }
  }

  Future<ProtectedEscrowRecord?> getEscrowRecordForContext(
    WalletContextKey context,
    String paymentId,
  ) {
    return getEscrowRecord(
      context.userId,
      context.network,
      paymentId,
      storagePrefix: context.storagePrefix,
    );
  }

  /// Clears wallet proofs and escrows for a given user & network (e.g. on wallet reset).
  Future<void> clearWalletData(String userId, HanbovaNetwork network,
      {String? storagePrefix}) async {
    await _storage.delete(
        key: _proofsKey(userId, network, storagePrefix: storagePrefix));
    await _storage.delete(
        key: _escrowsKey(userId, network, storagePrefix: storagePrefix));
  }
}
