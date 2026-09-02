import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/travel/domain/esim_models.dart';

void main() {
  group('M3B.1 Travel & eSIM Domain Models', () {
    test('EsimPackage formatted data and price', () {
      final pkgJson = {
        'id': 'esim_ke_3gb',
        'country': 'KE',
        'region': 'Africa',
        'name': 'Kenya Traveler 3 GB',
        'data_allowance_mb': 3072,
        'validity_days': 15,
        'price_sats': 12000,
        'price_fiat': 8.0,
        'currency': 'USD',
        'carrier': 'Safaricom / Airtel',
        'network_speed': '4G/5G',
        'top_up_supported': true,
      };

      final pkg = EsimPackage.fromJson(pkgJson);
      expect(pkg.id, 'esim_ke_3gb');
      expect(pkg.formattedData, '3 GB');
      expect(pkg.priceSats, 12000);
      expect(pkg.topUpSupported, isTrue);
    });

    test('EsimProfile remaining fraction and formatting', () {
      final profJson = {
        'id': 'prof_111',
        'package_id': 'esim_ke_3gb',
        'package_name': 'Kenya Traveler 3 GB',
        'country': 'KE',
        'iccid': '89234021000012345678',
        'matching_id': 'MATCH-1234',
        'smdp_address': 'rsp.dtone.com',
        'qr_code_data': 'LPA:1\$rsp.dtone.com\$MATCH-1234',
        'ios_installation_url':
            'https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=LPA:1\$rsp.dtone.com\$MATCH-1234',
        'android_installation_url':
            'intent:#Intent;action=android.telephony.euicc.action.DOWNLOAD_SUBSCRIPTION;S.activation_code=LPA:1\$rsp.dtone.com\$MATCH-1234;end',
        'data_allowance_mb': 3072,
        'remaining_data_mb': 1536,
        'status': 'active',
        'top_up_supported': true,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      };

      final prof = EsimProfile.fromJson(profJson);
      expect(prof.iccid, '89234021000012345678');
      expect(prof.dataRemainingFraction, 0.5);
      expect(prof.formattedRemaining, '1.5 GB');
      expect(prof.qrCodeData, startsWith('LPA:1\$'));
      expect(prof.iosInstallationUrl, contains('esimsetup.apple.com'));
      expect(prof.androidInstallationUrl, contains('android.telephony.euicc'));
    });

    test('PayoutCorridor and CardEligibilityInfo parsing', () {
      final corridorJson = {
        'id': 'ke_mpesa',
        'country': 'KE',
        'currency': 'KES',
        'channel': 'm_pesa',
        'name': 'M-Pesa Kenya',
        'min_amount_fiat': 100.0,
        'max_amount_fiat': 150000.0,
        'estimated_fee_sats': 250,
      };

      final corridor = PayoutCorridor.fromJson(corridorJson);
      expect(corridor.id, 'ke_mpesa');
      expect(corridor.channel, 'm_pesa');
      expect(corridor.minAmountFiat, 100.0);
      expect(corridor.estimatedFeeSats, 250);

      final cardJson = {
        'is_eligible': true,
        'country': 'KE',
        'supported_types': ['virtual_visa', 'virtual_mastercard'],
        'min_funding_sats': 5000,
        'reason': null,
      };

      final card = CardEligibilityInfo.fromJson(cardJson);
      expect(card.isEligible, isTrue);
      expect(card.supportedTypes, contains('virtual_visa'));
    });
  });
}
