# Hanbova App

> **Send protected.**

Hanbova App is the Africa-first Bitcoin payment mobile client built with Flutter.

---

## Features

- **Instant Send**: Native Lightning Network payments with instant settlement.
- **Protected Send**: Cashu NUT-10 & NUT-11 P2PK conditional escrow payments.
- **Claim Flow**: Recipient sweeps locked funds using device-generated private keys.
- **Refund Flow**: Sender recovers expired funds after locktime lapses.
- **Balance Breakdown**: Displays Spendable, Protected Outgoing, and Protected Incoming balances.
- **Secure Key Storage**: Client-side secp256k1 key management in hardware keystore.

---

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.20.0)
- Dart SDK (>= 3.4.0)

### Run Locally
```bash
# Get dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

### Run Tests & Analysis
```bash
# Analyze code
flutter analyze

# Run unit and widget tests
flutter test
```

---

## Architecture

- **State Management**: Riverpod (`StateNotifierProvider`)
- **Navigation**: GoRouter
- **Persistence**: `flutter_secure_storage`
- **Theme**: Dark-first modern design system

---

## License

MIT License. See [LICENSE](LICENSE) for details.
