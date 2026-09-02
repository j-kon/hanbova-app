import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/travel/domain/esim_models.dart';

final travelServiceProvider = Provider<TravelService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TravelService(apiClient);
});

class TravelService {
  final ApiClient _apiClient;

  TravelService(this._apiClient);

  Future<List<EsimPackage>> getEsimPackages(String country) async {
    final clean = country.trim().toUpperCase();
    try {
      final data = await _apiClient.get('/esim/packages?country=$clean');
      final list = (data['packages'] as List<dynamic>? ?? [])
          .map((e) => EsimPackage.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {}
    return [];
  }

  Future<EsimProfile> purchaseEsim(String packageId) async {
    final data = await _apiClient.post(
      '/esim/purchase',
      {'package_id': packageId},
    );
    return EsimProfile.fromJson(data);
  }

  Future<List<EsimProfile>> getMyProfiles() async {
    try {
      final data = await _apiClient.get('/esim/profiles');
      final list = (data['profiles'] as List<dynamic>? ?? [])
          .map((e) => EsimProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {}
    return [];
  }

  Future<List<PayoutCorridor>> getPayoutCorridors(String country) async {
    final clean = country.trim().toUpperCase();
    try {
      final data = await _apiClient.get('/payouts/corridors?country=$clean');
      final list = (data['corridors'] as List<dynamic>? ?? [])
          .map((e) => PayoutCorridor.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {}
    return [];
  }

  Future<CardEligibilityInfo> checkCardEligibility(String country) async {
    final clean = country.trim().toUpperCase();
    try {
      final data = await _apiClient.get('/cards/eligibility?country=$clean');
      return CardEligibilityInfo.fromJson(data);
    } catch (_) {}
    return CardEligibilityInfo(
      isEligible: true,
      country: clean,
      supportedTypes: const ['virtual_visa', 'virtual_mastercard'],
      minFundingSats: 5000,
    );
  }
}
