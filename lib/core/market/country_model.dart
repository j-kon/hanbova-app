import 'package:hanbova_app/core/currency/currency_provider.dart';

/// KYC status enum preserved for future architecture without fake KYC workflows.
enum KycStatus {
  unverified,
  pendingVerification,
  verified,
  restricted,
}

/// Static reference metadata for countries across the globe.
class CountryInfo {
  final String code; // 2-letter ISO (e.g. "US", "NG", "KE")
  final String name;
  final String flagEmoji;
  final FiatCurrency defaultCurrency;
  final String dialCode;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.defaultCurrency,
    required this.dialCode,
  });

  /// The 7 mock-supported local markets for frontend capability fixtures.
  static const List<String> supportedLocalMarketCodes = [
    'NG',
    'KE',
    'GH',
    'RW',
    'UG',
    'TZ',
    'ZA',
  ];

  static bool isSupportedLocalMarket(String code) {
    return supportedLocalMarketCodes.contains(code.trim().toUpperCase());
  }

  /// Supported countries alias for backward compatibility.
  static List<CountryInfo> get supportedCountries =>
      supportedLocalMarketCodes.map(findByCode).toList(growable: false);

  /// Complete global country dataset with ISO code, name, flag, currency, and dial code.
  static const List<CountryInfo> allCountries = [
    CountryInfo(
        code: 'AF',
        name: 'Afghanistan',
        flagEmoji: '🇦🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+93'),
    CountryInfo(
        code: 'AL',
        name: 'Albania',
        flagEmoji: '🇦🇱',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+355'),
    CountryInfo(
        code: 'DZ',
        name: 'Algeria',
        flagEmoji: '🇩🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+213'),
    CountryInfo(
        code: 'AD',
        name: 'Andorra',
        flagEmoji: '🇦🇩',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+376'),
    CountryInfo(
        code: 'AO',
        name: 'Angola',
        flagEmoji: '🇦🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+244'),
    CountryInfo(
        code: 'AG',
        name: 'Antigua and Barbuda',
        flagEmoji: '🇦🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1268'),
    CountryInfo(
        code: 'AR',
        name: 'Argentina',
        flagEmoji: '🇦🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+54'),
    CountryInfo(
        code: 'AM',
        name: 'Armenia',
        flagEmoji: '🇦🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+374'),
    CountryInfo(
        code: 'AU',
        name: 'Australia',
        flagEmoji: '🇦🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+61'),
    CountryInfo(
        code: 'AT',
        name: 'Austria',
        flagEmoji: '🇦🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+43'),
    CountryInfo(
        code: 'AZ',
        name: 'Azerbaijan',
        flagEmoji: '🇦🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+994'),
    CountryInfo(
        code: 'BS',
        name: 'Bahamas',
        flagEmoji: '🇧🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1242'),
    CountryInfo(
        code: 'BH',
        name: 'Bahrain',
        flagEmoji: '🇧🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+973'),
    CountryInfo(
        code: 'BD',
        name: 'Bangladesh',
        flagEmoji: '🇧🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+880'),
    CountryInfo(
        code: 'BB',
        name: 'Barbados',
        flagEmoji: '🇧🇧',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1246'),
    CountryInfo(
        code: 'BY',
        name: 'Belarus',
        flagEmoji: '🇧🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+375'),
    CountryInfo(
        code: 'BE',
        name: 'Belgium',
        flagEmoji: '🇧🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+32'),
    CountryInfo(
        code: 'BZ',
        name: 'Belize',
        flagEmoji: '🇧🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+501'),
    CountryInfo(
        code: 'BJ',
        name: 'Benin',
        flagEmoji: '🇧🇯',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+229'),
    CountryInfo(
        code: 'BT',
        name: 'Bhutan',
        flagEmoji: '🇧🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+975'),
    CountryInfo(
        code: 'BO',
        name: 'Bolivia',
        flagEmoji: '🇧🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+591'),
    CountryInfo(
        code: 'BA',
        name: 'Bosnia and Herzegovina',
        flagEmoji: '🇧🇦',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+387'),
    CountryInfo(
        code: 'BW',
        name: 'Botswana',
        flagEmoji: '🇧🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+267'),
    CountryInfo(
        code: 'BR',
        name: 'Brazil',
        flagEmoji: '🇧🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+55'),
    CountryInfo(
        code: 'BN',
        name: 'Brunei',
        flagEmoji: '🇧🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+673'),
    CountryInfo(
        code: 'BG',
        name: 'Bulgaria',
        flagEmoji: '🇧🇬',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+359'),
    CountryInfo(
        code: 'BF',
        name: 'Burkina Faso',
        flagEmoji: '🇧🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+226'),
    CountryInfo(
        code: 'BI',
        name: 'Burundi',
        flagEmoji: '🇧🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+257'),
    CountryInfo(
        code: 'CV',
        name: 'Cabo Verde',
        flagEmoji: '🇨🇻',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+238'),
    CountryInfo(
        code: 'KH',
        name: 'Cambodia',
        flagEmoji: '🇰🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+855'),
    CountryInfo(
        code: 'CM',
        name: 'Cameroon',
        flagEmoji: '🇨🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+237'),
    CountryInfo(
        code: 'CA',
        name: 'Canada',
        flagEmoji: '🇨🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1'),
    CountryInfo(
        code: 'CF',
        name: 'Central African Republic',
        flagEmoji: '🇨🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+236'),
    CountryInfo(
        code: 'TD',
        name: 'Chad',
        flagEmoji: '🇹🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+235'),
    CountryInfo(
        code: 'CL',
        name: 'Chile',
        flagEmoji: '🇨🇱',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+56'),
    CountryInfo(
        code: 'CN',
        name: 'China',
        flagEmoji: '🇨🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+86'),
    CountryInfo(
        code: 'CO',
        name: 'Colombia',
        flagEmoji: '🇨🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+57'),
    CountryInfo(
        code: 'KM',
        name: 'Comoros',
        flagEmoji: '🇰🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+269'),
    CountryInfo(
        code: 'CG',
        name: 'Congo',
        flagEmoji: '🇨🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+242'),
    CountryInfo(
        code: 'CD',
        name: 'Congo (DRC)',
        flagEmoji: '🇨🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+243'),
    CountryInfo(
        code: 'CR',
        name: 'Costa Rica',
        flagEmoji: '🇨🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+506'),
    CountryInfo(
        code: 'CI',
        name: "Côte d'Ivoire",
        flagEmoji: '🇨🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+225'),
    CountryInfo(
        code: 'HR',
        name: 'Croatia',
        flagEmoji: '🇭🇷',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+385'),
    CountryInfo(
        code: 'CU',
        name: 'Cuba',
        flagEmoji: '🇨🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+53'),
    CountryInfo(
        code: 'CY',
        name: 'Cyprus',
        flagEmoji: '🇨🇾',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+357'),
    CountryInfo(
        code: 'CZ',
        name: 'Czechia',
        flagEmoji: '🇨🇿',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+420'),
    CountryInfo(
        code: 'DK',
        name: 'Denmark',
        flagEmoji: '🇩🇰',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+45'),
    CountryInfo(
        code: 'DJ',
        name: 'Djibouti',
        flagEmoji: '🇩🇯',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+253'),
    CountryInfo(
        code: 'DM',
        name: 'Dominica',
        flagEmoji: '🇩🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1767'),
    CountryInfo(
        code: 'DO',
        name: 'Dominican Republic',
        flagEmoji: '🇩🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1809'),
    CountryInfo(
        code: 'EC',
        name: 'Ecuador',
        flagEmoji: '🇪🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+593'),
    CountryInfo(
        code: 'EG',
        name: 'Egypt',
        flagEmoji: '🇪🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+20'),
    CountryInfo(
        code: 'SV',
        name: 'El Salvador',
        flagEmoji: '🇸🇻',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+503'),
    CountryInfo(
        code: 'GQ',
        name: 'Equatorial Guinea',
        flagEmoji: '🇬🇶',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+240'),
    CountryInfo(
        code: 'ER',
        name: 'Eritrea',
        flagEmoji: '🇪🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+291'),
    CountryInfo(
        code: 'EE',
        name: 'Estonia',
        flagEmoji: '🇪🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+372'),
    CountryInfo(
        code: 'SZ',
        name: 'Eswatini',
        flagEmoji: '🇸🇿',
        defaultCurrency: FiatCurrency.zar,
        dialCode: '+268'),
    CountryInfo(
        code: 'ET',
        name: 'Ethiopia',
        flagEmoji: '🇪🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+251'),
    CountryInfo(
        code: 'FJ',
        name: 'Fiji',
        flagEmoji: '🇫🇯',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+679'),
    CountryInfo(
        code: 'FI',
        name: 'Finland',
        flagEmoji: '🇫🇮',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+358'),
    CountryInfo(
        code: 'FR',
        name: 'France',
        flagEmoji: '🇫🇷',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+33'),
    CountryInfo(
        code: 'GA',
        name: 'Gabon',
        flagEmoji: '🇬🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+241'),
    CountryInfo(
        code: 'GM',
        name: 'Gambia',
        flagEmoji: '🇬🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+220'),
    CountryInfo(
        code: 'GE',
        name: 'Georgia',
        flagEmoji: '🇬🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+995'),
    CountryInfo(
        code: 'DE',
        name: 'Germany',
        flagEmoji: '🇩🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+49'),
    CountryInfo(
        code: 'GH',
        name: 'Ghana',
        flagEmoji: '🇬🇭',
        defaultCurrency: FiatCurrency.ghs,
        dialCode: '+233'),
    CountryInfo(
        code: 'GR',
        name: 'Greece',
        flagEmoji: '🇬🇷',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+30'),
    CountryInfo(
        code: 'GD',
        name: 'Grenada',
        flagEmoji: '🇬🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1473'),
    CountryInfo(
        code: 'GT',
        name: 'Guatemala',
        flagEmoji: '🇬🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+502'),
    CountryInfo(
        code: 'GN',
        name: 'Guinea',
        flagEmoji: '🇬🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+224'),
    CountryInfo(
        code: 'GW',
        name: 'Guinea-Bissau',
        flagEmoji: '🇬🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+245'),
    CountryInfo(
        code: 'GY',
        name: 'Guyana',
        flagEmoji: '🇬🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+592'),
    CountryInfo(
        code: 'HT',
        name: 'Haiti',
        flagEmoji: '🇭🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+509'),
    CountryInfo(
        code: 'HN',
        name: 'Honduras',
        flagEmoji: '🇭🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+504'),
    CountryInfo(
        code: 'HK',
        name: 'Hong Kong',
        flagEmoji: '🇭🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+852'),
    CountryInfo(
        code: 'HU',
        name: 'Hungary',
        flagEmoji: '🇭🇺',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+36'),
    CountryInfo(
        code: 'IS',
        name: 'Iceland',
        flagEmoji: '🇮🇸',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+354'),
    CountryInfo(
        code: 'IN',
        name: 'India',
        flagEmoji: '🇮🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+91'),
    CountryInfo(
        code: 'ID',
        name: 'Indonesia',
        flagEmoji: '🇮🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+62'),
    CountryInfo(
        code: 'IR',
        name: 'Iran',
        flagEmoji: '🇮🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+98'),
    CountryInfo(
        code: 'IQ',
        name: 'Iraq',
        flagEmoji: '🇮🇶',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+964'),
    CountryInfo(
        code: 'IE',
        name: 'Ireland',
        flagEmoji: '🇮🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+353'),
    CountryInfo(
        code: 'IL',
        name: 'Israel',
        flagEmoji: '🇮🇱',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+972'),
    CountryInfo(
        code: 'IT',
        name: 'Italy',
        flagEmoji: '🇮🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+39'),
    CountryInfo(
        code: 'JM',
        name: 'Jamaica',
        flagEmoji: '🇯🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1876'),
    CountryInfo(
        code: 'JP',
        name: 'Japan',
        flagEmoji: '🇯🇵',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+81'),
    CountryInfo(
        code: 'JO',
        name: 'Jordan',
        flagEmoji: '🇯🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+962'),
    CountryInfo(
        code: 'KZ',
        name: 'Kazakhstan',
        flagEmoji: '🇰🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+7'),
    CountryInfo(
        code: 'KE',
        name: 'Kenya',
        flagEmoji: '🇰🇪',
        defaultCurrency: FiatCurrency.kes,
        dialCode: '+254'),
    CountryInfo(
        code: 'KI',
        name: 'Kiribati',
        flagEmoji: '🇰🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+686'),
    CountryInfo(
        code: 'KP',
        name: 'North Korea',
        flagEmoji: '🇰🇵',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+850'),
    CountryInfo(
        code: 'KR',
        name: 'South Korea',
        flagEmoji: '🇰🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+82'),
    CountryInfo(
        code: 'KW',
        name: 'Kuwait',
        flagEmoji: '🇰🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+965'),
    CountryInfo(
        code: 'KG',
        name: 'Kyrgyzstan',
        flagEmoji: '🇰🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+996'),
    CountryInfo(
        code: 'LA',
        name: 'Laos',
        flagEmoji: '🇱🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+856'),
    CountryInfo(
        code: 'LV',
        name: 'Latvia',
        flagEmoji: '🇱🇻',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+371'),
    CountryInfo(
        code: 'LB',
        name: 'Lebanon',
        flagEmoji: '🇱🇧',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+961'),
    CountryInfo(
        code: 'LS',
        name: 'Lesotho',
        flagEmoji: '🇱🇸',
        defaultCurrency: FiatCurrency.zar,
        dialCode: '+266'),
    CountryInfo(
        code: 'LR',
        name: 'Liberia',
        flagEmoji: '🇱🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+231'),
    CountryInfo(
        code: 'LY',
        name: 'Libya',
        flagEmoji: '🇱🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+218'),
    CountryInfo(
        code: 'LI',
        name: 'Liechtenstein',
        flagEmoji: '🇱🇮',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+423'),
    CountryInfo(
        code: 'LT',
        name: 'Lithuania',
        flagEmoji: '🇱🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+370'),
    CountryInfo(
        code: 'LU',
        name: 'Luxembourg',
        flagEmoji: '🇱🇺',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+352'),
    CountryInfo(
        code: 'MG',
        name: 'Madagascar',
        flagEmoji: '🇲🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+261'),
    CountryInfo(
        code: 'MW',
        name: 'Malawi',
        flagEmoji: '🇲🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+265'),
    CountryInfo(
        code: 'MY',
        name: 'Malaysia',
        flagEmoji: '🇲🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+60'),
    CountryInfo(
        code: 'MV',
        name: 'Maldives',
        flagEmoji: '🇲🇻',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+960'),
    CountryInfo(
        code: 'ML',
        name: 'Mali',
        flagEmoji: '🇲🇱',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+223'),
    CountryInfo(
        code: 'MT',
        name: 'Malta',
        flagEmoji: '🇲🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+356'),
    CountryInfo(
        code: 'MH',
        name: 'Marshall Islands',
        flagEmoji: '🇲🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+692'),
    CountryInfo(
        code: 'MR',
        name: 'Mauritania',
        flagEmoji: '🇲🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+222'),
    CountryInfo(
        code: 'MU',
        name: 'Mauritius',
        flagEmoji: '🇲🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+230'),
    CountryInfo(
        code: 'MX',
        name: 'Mexico',
        flagEmoji: '🇲🇽',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+52'),
    CountryInfo(
        code: 'FM',
        name: 'Micronesia',
        flagEmoji: '🇫🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+691'),
    CountryInfo(
        code: 'MD',
        name: 'Moldova',
        flagEmoji: '🇲🇩',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+373'),
    CountryInfo(
        code: 'MC',
        name: 'Monaco',
        flagEmoji: '🇲🇨',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+377'),
    CountryInfo(
        code: 'MN',
        name: 'Mongolia',
        flagEmoji: '🇲🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+976'),
    CountryInfo(
        code: 'ME',
        name: 'Montenegro',
        flagEmoji: '🇲🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+382'),
    CountryInfo(
        code: 'MA',
        name: 'Morocco',
        flagEmoji: '🇲🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+212'),
    CountryInfo(
        code: 'MZ',
        name: 'Mozambique',
        flagEmoji: '🇲🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+258'),
    CountryInfo(
        code: 'MM',
        name: 'Myanmar',
        flagEmoji: '🇲🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+95'),
    CountryInfo(
        code: 'NA',
        name: 'Namibia',
        flagEmoji: '🇳🇦',
        defaultCurrency: FiatCurrency.zar,
        dialCode: '+264'),
    CountryInfo(
        code: 'NR',
        name: 'Nauru',
        flagEmoji: '🇳🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+674'),
    CountryInfo(
        code: 'NP',
        name: 'Nepal',
        flagEmoji: '🇳🇵',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+977'),
    CountryInfo(
        code: 'NL',
        name: 'Netherlands',
        flagEmoji: '🇳🇱',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+31'),
    CountryInfo(
        code: 'NZ',
        name: 'New Zealand',
        flagEmoji: '🇳🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+64'),
    CountryInfo(
        code: 'NI',
        name: 'Nicaragua',
        flagEmoji: '🇳🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+505'),
    CountryInfo(
        code: 'NE',
        name: 'Niger',
        flagEmoji: '🇳🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+227'),
    CountryInfo(
        code: 'NG',
        name: 'Nigeria',
        flagEmoji: '🇳🇬',
        defaultCurrency: FiatCurrency.ngn,
        dialCode: '+234'),
    CountryInfo(
        code: 'MK',
        name: 'North Macedonia',
        flagEmoji: '🇲🇰',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+389'),
    CountryInfo(
        code: 'NO',
        name: 'Norway',
        flagEmoji: '🇳🇴',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+47'),
    CountryInfo(
        code: 'OM',
        name: 'Oman',
        flagEmoji: '🇴🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+968'),
    CountryInfo(
        code: 'PK',
        name: 'Pakistan',
        flagEmoji: '🇵🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+92'),
    CountryInfo(
        code: 'PW',
        name: 'Palau',
        flagEmoji: '🇵🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+680'),
    CountryInfo(
        code: 'PA',
        name: 'Panama',
        flagEmoji: '🇵🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+507'),
    CountryInfo(
        code: 'PG',
        name: 'Papua New Guinea',
        flagEmoji: '🇵🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+675'),
    CountryInfo(
        code: 'PY',
        name: 'Paraguay',
        flagEmoji: '🇵🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+595'),
    CountryInfo(
        code: 'PE',
        name: 'Peru',
        flagEmoji: '🇵🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+51'),
    CountryInfo(
        code: 'PH',
        name: 'Philippines',
        flagEmoji: '🇵🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+63'),
    CountryInfo(
        code: 'PL',
        name: 'Poland',
        flagEmoji: '🇵🇱',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+48'),
    CountryInfo(
        code: 'PT',
        name: 'Portugal',
        flagEmoji: '🇵🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+351'),
    CountryInfo(
        code: 'QA',
        name: 'Qatar',
        flagEmoji: '🇶🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+974'),
    CountryInfo(
        code: 'RO',
        name: 'Romania',
        flagEmoji: '🇷🇴',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+40'),
    CountryInfo(
        code: 'RU',
        name: 'Russia',
        flagEmoji: '🇷🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+7'),
    CountryInfo(
        code: 'RW',
        name: 'Rwanda',
        flagEmoji: '🇷🇼',
        defaultCurrency: FiatCurrency.rwf,
        dialCode: '+250'),
    CountryInfo(
        code: 'KN',
        name: 'Saint Kitts and Nevis',
        flagEmoji: '🇰🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1869'),
    CountryInfo(
        code: 'LC',
        name: 'Saint Lucia',
        flagEmoji: '🇱🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1758'),
    CountryInfo(
        code: 'VC',
        name: 'Saint Vincent and the Grenadines',
        flagEmoji: '🇻🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1784'),
    CountryInfo(
        code: 'WS',
        name: 'Samoa',
        flagEmoji: '🇼🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+685'),
    CountryInfo(
        code: 'SM',
        name: 'San Marino',
        flagEmoji: '🇸🇲',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+378'),
    CountryInfo(
        code: 'ST',
        name: 'Sao Tome and Principe',
        flagEmoji: '🇸🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+239'),
    CountryInfo(
        code: 'SA',
        name: 'Saudi Arabia',
        flagEmoji: '🇸🇦',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+966'),
    CountryInfo(
        code: 'SN',
        name: 'Senegal',
        flagEmoji: '🇸🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+221'),
    CountryInfo(
        code: 'RS',
        name: 'Serbia',
        flagEmoji: '🇷🇸',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+381'),
    CountryInfo(
        code: 'SC',
        name: 'Seychelles',
        flagEmoji: '🇸🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+248'),
    CountryInfo(
        code: 'SL',
        name: 'Sierra Leone',
        flagEmoji: '🇸🇱',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+232'),
    CountryInfo(
        code: 'SG',
        name: 'Singapore',
        flagEmoji: '🇸🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+65'),
    CountryInfo(
        code: 'SK',
        name: 'Slovakia',
        flagEmoji: '🇸🇰',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+421'),
    CountryInfo(
        code: 'SI',
        name: 'Slovenia',
        flagEmoji: '🇸🇮',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+386'),
    CountryInfo(
        code: 'SB',
        name: 'Solomon Islands',
        flagEmoji: '🇸🇧',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+677'),
    CountryInfo(
        code: 'SO',
        name: 'Somalia',
        flagEmoji: '🇸🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+252'),
    CountryInfo(
        code: 'ZA',
        name: 'South Africa',
        flagEmoji: '🇿🇦',
        defaultCurrency: FiatCurrency.zar,
        dialCode: '+27'),
    CountryInfo(
        code: 'SS',
        name: 'South Sudan',
        flagEmoji: '🇸🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+211'),
    CountryInfo(
        code: 'ES',
        name: 'Spain',
        flagEmoji: '🇪🇸',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+34'),
    CountryInfo(
        code: 'LK',
        name: 'Sri Lanka',
        flagEmoji: '🇱🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+94'),
    CountryInfo(
        code: 'SD',
        name: 'Sudan',
        flagEmoji: '🇸🇩',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+249'),
    CountryInfo(
        code: 'SR',
        name: 'Suriname',
        flagEmoji: '🇸🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+597'),
    CountryInfo(
        code: 'SE',
        name: 'Sweden',
        flagEmoji: '🇸🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+46'),
    CountryInfo(
        code: 'CH',
        name: 'Switzerland',
        flagEmoji: '🇨🇭',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+41'),
    CountryInfo(
        code: 'SY',
        name: 'Syria',
        flagEmoji: '🇸🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+963'),
    CountryInfo(
        code: 'TW',
        name: 'Taiwan',
        flagEmoji: '🇹🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+886'),
    CountryInfo(
        code: 'TJ',
        name: 'Tajikistan',
        flagEmoji: '🇹🇯',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+992'),
    CountryInfo(
        code: 'TZ',
        name: 'Tanzania',
        flagEmoji: '🇹🇿',
        defaultCurrency: FiatCurrency.tzs,
        dialCode: '+255'),
    CountryInfo(
        code: 'TH',
        name: 'Thailand',
        flagEmoji: '🇹🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+66'),
    CountryInfo(
        code: 'TL',
        name: 'Timor-Leste',
        flagEmoji: '🇹🇱',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+670'),
    CountryInfo(
        code: 'TG',
        name: 'Togo',
        flagEmoji: '🇹🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+228'),
    CountryInfo(
        code: 'TO',
        name: 'Tonga',
        flagEmoji: '🇹🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+676'),
    CountryInfo(
        code: 'TT',
        name: 'Trinidad and Tobago',
        flagEmoji: '🇹🇹',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1868'),
    CountryInfo(
        code: 'TN',
        name: 'Tunisia',
        flagEmoji: '🇹🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+216'),
    CountryInfo(
        code: 'TR',
        name: 'Turkey',
        flagEmoji: '🇹🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+90'),
    CountryInfo(
        code: 'TM',
        name: 'Turkmenistan',
        flagEmoji: '🇹🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+993'),
    CountryInfo(
        code: 'TV',
        name: 'Tuvalu',
        flagEmoji: '🇹🇻',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+688'),
    CountryInfo(
        code: 'UG',
        name: 'Uganda',
        flagEmoji: '🇺🇬',
        defaultCurrency: FiatCurrency.ugx,
        dialCode: '+256'),
    CountryInfo(
        code: 'UA',
        name: 'Ukraine',
        flagEmoji: '🇺🇦',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+380'),
    CountryInfo(
        code: 'AE',
        name: 'United Arab Emirates',
        flagEmoji: '🇦🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+971'),
    CountryInfo(
        code: 'GB',
        name: 'United Kingdom',
        flagEmoji: '🇬🇧',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+44'),
    CountryInfo(
        code: 'US',
        name: 'United States',
        flagEmoji: '🇺🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1'),
    CountryInfo(
        code: 'UY',
        name: 'Uruguay',
        flagEmoji: '🇺🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+598'),
    CountryInfo(
        code: 'UZ',
        name: 'Uzbekistan',
        flagEmoji: '🇺🇿',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+998'),
    CountryInfo(
        code: 'VU',
        name: 'Vanuatu',
        flagEmoji: '🇻🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+678'),
    CountryInfo(
        code: 'VA',
        name: 'Vatican City',
        flagEmoji: '🇻🇦',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+379'),
    CountryInfo(
        code: 'VE',
        name: 'Venezuela',
        flagEmoji: '🇻🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+58'),
    CountryInfo(
        code: 'VN',
        name: 'Vietnam',
        flagEmoji: '🇻🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+84'),
    CountryInfo(
        code: 'YE',
        name: 'Yemen',
        flagEmoji: '🇾🇪',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+967'),
    CountryInfo(
        code: 'ZM',
        name: 'Zambia',
        flagEmoji: '🇿🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+260'),
    CountryInfo(
        code: 'ZW',
        name: 'Zimbabwe',
        flagEmoji: '🇿🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+263'),
    // Global territories and autonomous regions (reaching complete ISO 3166-1 alpha-2 coverage)
    CountryInfo(
        code: 'AI',
        name: 'Anguilla',
        flagEmoji: '🇦🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1264'),
    CountryInfo(
        code: 'AQ',
        name: 'Antarctica',
        flagEmoji: '🇦🇶',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+672'),
    CountryInfo(
        code: 'AW',
        name: 'Aruba',
        flagEmoji: '🇦🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+297'),
    CountryInfo(
        code: 'AX',
        name: 'Åland Islands',
        flagEmoji: '🇦🇽',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+358'),
    CountryInfo(
        code: 'BM',
        name: 'Bermuda',
        flagEmoji: '🇧🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1441'),
    CountryInfo(
        code: 'BL',
        name: 'Saint Barthélemy',
        flagEmoji: '🇧🇱',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+590'),
    CountryInfo(
        code: 'BQ',
        name: 'Bonaire, Sint Eustatius and Saba',
        flagEmoji: '🇧🇶',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+599'),
    CountryInfo(
        code: 'BV',
        name: 'Bouvet Island',
        flagEmoji: '🇧🇻',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+47'),
    CountryInfo(
        code: 'CC',
        name: 'Cocos (Keeling) Islands',
        flagEmoji: '🇨🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+61'),
    CountryInfo(
        code: 'CK',
        name: 'Cook Islands',
        flagEmoji: '🇨🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+682'),
    CountryInfo(
        code: 'CW',
        name: 'Curaçao',
        flagEmoji: '🇨🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+599'),
    CountryInfo(
        code: 'CX',
        name: 'Christmas Island',
        flagEmoji: '🇨🇽',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+61'),
    CountryInfo(
        code: 'KY',
        name: 'Cayman Islands',
        flagEmoji: '🇰🇾',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1345'),
    CountryInfo(
        code: 'EH',
        name: 'Western Sahara',
        flagEmoji: '🇪🇭',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+212'),
    CountryInfo(
        code: 'FK',
        name: 'Falkland Islands',
        flagEmoji: '🇫🇰',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+500'),
    CountryInfo(
        code: 'FO',
        name: 'Faroe Islands',
        flagEmoji: '🇫🇴',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+298'),
    CountryInfo(
        code: 'GF',
        name: 'French Guiana',
        flagEmoji: '🇬🇫',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+594'),
    CountryInfo(
        code: 'GG',
        name: 'Guernsey',
        flagEmoji: '🇬🇬',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+44'),
    CountryInfo(
        code: 'GI',
        name: 'Gibraltar',
        flagEmoji: '🇬🇮',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+350'),
    CountryInfo(
        code: 'GL',
        name: 'Greenland',
        flagEmoji: '🇬🇱',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+299'),
    CountryInfo(
        code: 'GP',
        name: 'Guadeloupe',
        flagEmoji: '🇬🇵',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+590'),
    CountryInfo(
        code: 'GU',
        name: 'Guam',
        flagEmoji: '🇬🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1671'),
    CountryInfo(
        code: 'HK',
        name: 'Hong Kong',
        flagEmoji: '🇭🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+852'),
    CountryInfo(
        code: 'HM',
        name: 'Heard Island and McDonald Islands',
        flagEmoji: '🇭🇲',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+672'),
    CountryInfo(
        code: 'IM',
        name: 'Isle of Man',
        flagEmoji: '🇮🇲',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+44'),
    CountryInfo(
        code: 'IO',
        name: 'British Indian Ocean Territory',
        flagEmoji: '🇮🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+246'),
    CountryInfo(
        code: 'JE',
        name: 'Jersey',
        flagEmoji: '🇯🇪',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+44'),
    CountryInfo(
        code: 'MF',
        name: 'Saint Martin',
        flagEmoji: '🇲🇫',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+590'),
    CountryInfo(
        code: 'MO',
        name: 'Macao',
        flagEmoji: '🇲🇴',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+853'),
    CountryInfo(
        code: 'MP',
        name: 'Northern Mariana Islands',
        flagEmoji: '🇲🇵',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1670'),
    CountryInfo(
        code: 'MQ',
        name: 'Martinique',
        flagEmoji: '🇲🇶',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+596'),
    CountryInfo(
        code: 'MS',
        name: 'Montserrat',
        flagEmoji: '🇲🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1664'),
    CountryInfo(
        code: 'NC',
        name: 'New Caledonia',
        flagEmoji: '🇳🇨',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+687'),
    CountryInfo(
        code: 'NF',
        name: 'Norfolk Island',
        flagEmoji: '🇳🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+672'),
    CountryInfo(
        code: 'NU',
        name: 'Niue',
        flagEmoji: '🇳🇺',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+683'),
    CountryInfo(
        code: 'PF',
        name: 'French Polynesia',
        flagEmoji: '🇵🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+689'),
    CountryInfo(
        code: 'PM',
        name: 'Saint Pierre and Miquelon',
        flagEmoji: '🇵🇲',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+508'),
    CountryInfo(
        code: 'PN',
        name: 'Pitcairn',
        flagEmoji: '🇵🇳',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+64'),
    CountryInfo(
        code: 'PR',
        name: 'Puerto Rico',
        flagEmoji: '🇵🇷',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1787'),
    CountryInfo(
        code: 'PS',
        name: 'Palestine',
        flagEmoji: '🇵🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+970'),
    CountryInfo(
        code: 'RE',
        name: 'Réunion',
        flagEmoji: '🇷🇪',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+262'),
    CountryInfo(
        code: 'SH',
        name: 'Saint Helena',
        flagEmoji: '🇸🇭',
        defaultCurrency: FiatCurrency.gbp,
        dialCode: '+290'),
    CountryInfo(
        code: 'SJ',
        name: 'Svalbard and Jan Mayen',
        flagEmoji: '🇸🇯',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+47'),
    CountryInfo(
        code: 'SX',
        name: 'Sint Maarten',
        flagEmoji: '🇸🇽',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1721'),
    CountryInfo(
        code: 'TC',
        name: 'Turks and Caicos Islands',
        flagEmoji: '🇹🇨',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1649'),
    CountryInfo(
        code: 'TF',
        name: 'French Southern Territories',
        flagEmoji: '🇹🇫',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+262'),
    CountryInfo(
        code: 'TK',
        name: 'Tokelau',
        flagEmoji: '🇹🇰',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+690'),
    CountryInfo(
        code: 'TW',
        name: 'Taiwan',
        flagEmoji: '🇹🇼',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+886'),
    CountryInfo(
        code: 'VG',
        name: 'Virgin Islands (British)',
        flagEmoji: '🇻🇬',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1284'),
    CountryInfo(
        code: 'VI',
        name: 'Virgin Islands (U.S.)',
        flagEmoji: '🇻🇮',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1340'),
    CountryInfo(
        code: 'WF',
        name: 'Wallis and Futuna',
        flagEmoji: '🇼🇫',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+681'),
    CountryInfo(
        code: 'YT',
        name: 'Mayotte',
        flagEmoji: '🇾🇹',
        defaultCurrency: FiatCurrency.eur,
        dialCode: '+262'),
  ];

  static CountryInfo findByCode(String code) {
    final upper = code.trim().toUpperCase();
    return allCountries.firstWhere(
      (c) => c.code == upper,
      orElse: () => const CountryInfo(
        code: 'US',
        name: 'United States',
        flagEmoji: '🇺🇸',
        defaultCurrency: FiatCurrency.usd,
        dialCode: '+1',
      ),
    );
  }

  /// Search countries by name or ISO 2-letter code.
  static List<CountryInfo> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return allCountries;

    return allCountries.where((c) {
      final matchesName = c.name.toLowerCase().contains(clean);
      final matchesCode = c.code.toLowerCase().startsWith(clean);
      return matchesName || matchesCode;
    }).toList(growable: false);
  }
}

/// Normalized market capability matrix.
class MarketCapabilities {
  // Global baseline wallet capabilities
  final bool bitcoin;
  final bool cashu;
  final bool protectedPayments;
  final bool stablecoin; // explicitly feature-flagged / coming soon

  // Local market service capabilities
  final bool airtime;
  final bool data;
  final bool electricity;
  final bool water;
  final bool tv;
  final bool internet;
  final bool bankPayout;
  final bool mobileMoney;
  final bool virtualCards;
  final bool esim;

  const MarketCapabilities({
    this.bitcoin = true,
    this.cashu = true,
    this.protectedPayments = true,
    this.stablecoin = false,
    this.airtime = false,
    this.data = false,
    this.electricity = false,
    this.water = false,
    this.tv = false,
    this.internet = false,
    this.bankPayout = false,
    this.mobileMoney = false,
    this.virtualCards = false,
    this.esim = false,
  });

  /// Global baseline for markets without local services.
  static const MarketCapabilities globalDefault = MarketCapabilities(
    bitcoin: true,
    cashu: true,
    protectedPayments: true,
    stablecoin: false,
    airtime: false,
    data: false,
    electricity: false,
    water: false,
    tv: false,
    internet: false,
    bankPayout: false,
    mobileMoney: false,
    virtualCards: false,
    esim: false,
  );

  /// Backward-compatible getters
  bool get payouts => bankPayout;
  bool get cards => virtualCards;

  /// Whether the market provides any local billers or service providers.
  bool get hasLocalServices =>
      airtime ||
      data ||
      electricity ||
      water ||
      tv ||
      internet ||
      bankPayout ||
      mobileMoney ||
      virtualCards ||
      esim;

  /// Whether the market offers everyday bill utilities.
  bool get hasEverydayBills =>
      airtime || data || electricity || water || tv || internet;

  /// Deterministic frontend capability fixtures for supported markets.
  static MarketCapabilities forMarket(String countryCode) {
    final clean = countryCode.trim().toUpperCase();
    switch (clean) {
      case 'NG':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: true,
          bankPayout: true,
          mobileMoney: false,
          virtualCards: true,
          esim: true,
        );
      case 'KE':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: true,
          bankPayout: true,
          mobileMoney: true,
          virtualCards: true,
          esim: true,
        );
      case 'GH':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: false,
          bankPayout: true,
          mobileMoney: true,
          virtualCards: true,
          esim: true,
        );
      case 'RW':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: false,
          bankPayout: true,
          mobileMoney: true,
          virtualCards: true,
          esim: true,
        );
      case 'UG':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: false,
          bankPayout: true,
          mobileMoney: true,
          virtualCards: true,
          esim: true,
        );
      case 'TZ':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: true,
          tv: true,
          internet: false,
          bankPayout: true,
          mobileMoney: true,
          virtualCards: true,
          esim: true,
        );
      case 'ZA':
        return const MarketCapabilities(
          bitcoin: true,
          cashu: true,
          protectedPayments: true,
          stablecoin: false,
          airtime: true,
          data: true,
          electricity: true,
          water: false,
          tv: true,
          internet: true,
          bankPayout: true,
          mobileMoney: false,
          virtualCards: true,
          esim: true,
        );
      default:
        return globalDefault;
    }
  }

  factory MarketCapabilities.fromJson(Map<String, dynamic> json) {
    return MarketCapabilities(
      bitcoin: json['bitcoin'] as bool? ?? true,
      cashu: json['cashu'] as bool? ?? true,
      protectedPayments: json['protected_payments'] as bool? ?? true,
      stablecoin: json['stablecoin'] as bool? ?? false,
      airtime: json['airtime'] as bool? ?? false,
      data: json['data'] as bool? ?? false,
      electricity: json['electricity'] as bool? ?? false,
      water: json['water'] as bool? ?? false,
      tv: json['tv'] as bool? ?? false,
      internet: json['internet'] as bool? ?? false,
      bankPayout:
          json['bank_payout'] as bool? ?? json['payouts'] as bool? ?? false,
      mobileMoney: json['mobile_money'] as bool? ?? false,
      virtualCards:
          json['virtual_cards'] as bool? ?? json['cards'] as bool? ?? false,
      esim: json['esim'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'bitcoin': bitcoin,
        'cashu': cashu,
        'protected_payments': protectedPayments,
        'stablecoin': stablecoin,
        'airtime': airtime,
        'data': data,
        'electricity': electricity,
        'water': water,
        'tv': tv,
        'internet': internet,
        'bank_payout': bankPayout,
        'mobile_money': mobileMoney,
        'virtual_cards': virtualCards,
        'esim': esim,
      };
}

/// Normalized country state separating legal residence, active market, roam state, and display currency.
class UserCountryContext {
  /// The user's genuine country of residence (e.g. "US", "NG"). Never mutated by Roam.
  final String residenceCountry;

  /// The active market context (e.g. "US", "KE"). Equals residenceCountry when Roam is off.
  final String activeMarket;

  /// The active currency shown in UI (e.g. FiatCurrency.usd, FiatCurrency.kes).
  final FiatCurrency displayCurrency;

  /// Whether Roam mode is actively turned on by the user.
  final bool roamEnabled;

  /// Active capabilities of the current active market.
  final MarketCapabilities capabilities;

  const UserCountryContext({
    String? residenceCountry,
    String? activeMarket,
    required this.displayCurrency,
    this.roamEnabled = false,
    this.capabilities = MarketCapabilities.globalDefault,
    String? identityCountry,
    String? spendCountry,
  })  : residenceCountry = residenceCountry ?? identityCountry ?? 'NG',
        activeMarket = activeMarket ??
            spendCountry ??
            residenceCountry ??
            identityCountry ??
            'NG';

  Map<String, dynamic> toJson() => {
        'residence_country': residenceCountry,
        'active_market': activeMarket,
        'display_currency': displayCurrency.code,
        'roam_enabled': roamEnabled,
        'capabilities': capabilities.toJson(),
      };

  factory UserCountryContext.fromJson(Map<String, dynamic> json) {
    final res = json['residence_country'] as String? ??
        json['identity_country'] as String? ??
        'NG';
    final act = json['active_market'] as String? ??
        json['spend_country'] as String? ??
        res;
    final currStr = json['display_currency'] as String? ?? 'NGN';
    final curr = FiatCurrency.values.firstWhere(
      (c) => c.code.toUpperCase() == currStr.toUpperCase(),
      orElse: () => FiatCurrency.usd,
    );
    final roam = json['roam_enabled'] as bool? ?? false;
    final caps = json['capabilities'] != null
        ? MarketCapabilities.fromJson(
            json['capabilities'] as Map<String, dynamic>)
        : MarketCapabilities.forMarket(act);

    return UserCountryContext(
      residenceCountry: res,
      activeMarket: act,
      displayCurrency: curr,
      roamEnabled: roam,
      capabilities: caps,
    );
  }

  /// Backward-compatible getters
  String get identityCountry => residenceCountry;
  String get spendCountry => activeMarket;

  CountryInfo get residenceCountryInfo =>
      CountryInfo.findByCode(residenceCountry);
  CountryInfo get activeMarketInfo => CountryInfo.findByCode(activeMarket);
  CountryInfo get spendCountryInfo => activeMarketInfo;
  CountryInfo get identityCountryInfo => residenceCountryInfo;

  /// Whether Roam mode is currently active (roam enabled and active market differs from residence).
  bool get isRoamActive => roamEnabled && activeMarket != residenceCountry;

  UserCountryContext copyWith({
    String? residenceCountry,
    String? activeMarket,
    FiatCurrency? displayCurrency,
    bool? roamEnabled,
    MarketCapabilities? capabilities,
    // Legacy support
    String? identityCountry,
    String? spendCountry,
  }) {
    final effectiveResidence =
        residenceCountry ?? identityCountry ?? this.residenceCountry;
    final effectiveMarket = activeMarket ?? spendCountry ?? this.activeMarket;

    return UserCountryContext(
      residenceCountry: effectiveResidence,
      activeMarket: effectiveMarket,
      displayCurrency: displayCurrency ?? this.displayCurrency,
      roamEnabled: roamEnabled ?? this.roamEnabled,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}
