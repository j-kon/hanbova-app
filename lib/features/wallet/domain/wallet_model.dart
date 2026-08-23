class WalletModel {
  final int spendableSats;
  final int protectedOutgoingSats;
  final int protectedIncomingSats;
  final String? nodeAlias;

  const WalletModel({
    required this.spendableSats,
    this.protectedOutgoingSats = 0,
    this.protectedIncomingSats = 0,
    this.nodeAlias,
  });

  int get balanceSats => spendableSats;
  int get totalSats => spendableSats + protectedOutgoingSats;
  int get totalTrackedSats => spendableSats + protectedOutgoingSats;

  WalletModel copyWith({
    int? spendableSats,
    int? protectedOutgoingSats,
    int? protectedIncomingSats,
    String? nodeAlias,
  }) {
    return WalletModel(
      spendableSats: spendableSats ?? this.spendableSats,
      protectedOutgoingSats:
          protectedOutgoingSats ?? this.protectedOutgoingSats,
      protectedIncomingSats:
          protectedIncomingSats ?? this.protectedIncomingSats,
      nodeAlias: nodeAlias ?? this.nodeAlias,
    );
  }
}
