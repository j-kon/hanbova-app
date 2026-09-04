import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/data/payment_intent_repository.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_provider.dart';
import 'package:http/http.dart' as http;

final _contextState = StateProvider<WalletContextKey>((ref) => _cashuContext);

const _cashuContext = WalletContextKey(
  userId: 'alice_id',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

final _user = UserProfile(
  id: 'alice_id',
  username: 'alice',
  handle: '@alice',
  email: 'alice@example.com',
  firstName: 'Alice',
  lastName: 'Example',
  displayName: 'Alice Example',
  emailVerified: true,
  createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
);

final class _AuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _AuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingWallet implements CashuWalletService {
  var lockCalls = 0;

  @override
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  }) async {
    lockCalls++;
    return 'cashuA_token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingRepository extends PaymentIntentRepository {
  _RecordingRepository()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  var createCalls = 0;

  @override
  Future<ProtectedPaymentIntent> createPaymentIntent({
    required String paymentType,
    required int amountSats,
    required String recipientIdentifier,
    String? senderId,
    String? description,
    int? expiresInSeconds,
  }) async {
    createCalls++;
    return ProtectedPaymentIntent(
      id: 'intent_1',
      paymentType: paymentType,
      status: 'created',
      amountSats: amountSats,
      senderId: senderId,
      recipientIdentifier: recipientIdentifier,
      description: description,
      expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds ?? 60)),
      createdAt: DateTime.now(),
    );
  }
}

final class _MessageService extends ProtectedMessageService {
  _MessageService()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<UserPaymentProfile> resolveUserPaymentProfile(
    String username, {
    String? environment,
  }) async {
    return UserPaymentProfile(
      username: 'amina',
      handle: '@amina',
      walletEnvironment: environment ?? '',
      protectedPaymentPubkey:
          '02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5af',
      transportEncryptionPubkey:
          '6d9b4b9b9c9f0b83e3c09f8e434f0e9d6d9b4b9b9c9f0b83e3c09f8e434f0e9d',
    );
  }
}

void main() {
  test('prepare resolves username without creating intent or locking funds',
      () async {
    final wallet = _RecordingWallet();
    final repository = _RecordingRepository();
    final container = _container(wallet, repository);
    addTearDown(container.dispose);

    final draft =
        await container.read(protectedSendProvider.notifier).prepareDraft(
              username: '@amina',
              amountSats: 2500,
              description: 'Order',
              expirationSeconds: 86400,
            );

    expect(draft.recipient.username, 'amina');
    expect(draft.walletContext, _cashuContext);
    expect(repository.createCalls, 0);
    expect(wallet.lockCalls, 0);
  });

  test('confirm rejects a draft created for a stale wallet context', () async {
    final wallet = _RecordingWallet();
    final repository = _RecordingRepository();
    final container = _container(wallet, repository);
    addTearDown(container.dispose);
    final notifier = container.read(protectedSendProvider.notifier);
    final draft = await notifier.prepareDraft(
      username: '@amina',
      amountSats: 2500,
      description: 'Order',
      expirationSeconds: 86400,
    );
    container.read(_contextState.notifier).state = const WalletContextKey(
      userId: 'alice_id',
      network: HanbovaNetwork.mainnet,
      storagePrefix: 'wallet_mainnet_pilot',
    );

    await expectLater(notifier.confirmDraft(draft), throwsStateError);
    expect(repository.createCalls, 0);
    expect(wallet.lockCalls, 0);
  });
}

ProviderContainer _container(
  _RecordingWallet wallet,
  _RecordingRepository repository,
) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith(
        (ref) => _AuthNotifier(AuthState.authenticated(_user, 'jwt')),
      ),
      activeNetworkConfigProvider.overrideWithValue(NetworkConfig.cashuTest),
      activeWalletContextKeyProvider.overrideWith(
        (ref) => ref.watch(_contextState),
      ),
      cashuWalletServiceProvider.overrideWithValue(wallet),
      paymentIntentRepositoryProvider.overrideWithValue(repository),
      protectedMessageServiceProvider.overrideWithValue(_MessageService()),
    ],
  );
}
