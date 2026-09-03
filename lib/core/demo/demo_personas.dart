import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/features/profile/providers/profile_provider.dart';

enum DemoPersonaType {
  personaA, // Residence: Nigeria, Roam: Off -> Global wallet + Nigerian local services
  personaB, // Residence: United States, Roam: Off -> Global wallet only
  personaC, // Residence: United States, Roam: Kenya -> Global wallet + Kenya local capabilities
}

class DemoPersona {
  final DemoPersonaType type;
  final String label;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String residenceCountry;
  final bool roamEnabled;
  final String activeMarket;
  final FiatCurrency displayCurrency;
  final String summary;

  const DemoPersona({
    required this.type,
    required this.label,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.residenceCountry,
    required this.roamEnabled,
    required this.activeMarket,
    required this.displayCurrency,
    required this.summary,
  });

  String get name => label;
  String get description => summary;
  String get roamDestination => activeMarket;

  static const DemoPersona personaA = DemoPersona(
    type: DemoPersonaType.personaA,
    label: 'Persona A (Nigeria)',
    firstName: 'Amara',
    lastName: 'Obi',
    username: 'amara',
    email: 'amara@hanbova.org',
    residenceCountry: 'NG',
    roamEnabled: false,
    activeMarket: 'NG',
    displayCurrency: FiatCurrency.ngn,
    summary: 'Global wallet + Nigerian local everyday services',
  );

  static const DemoPersona personaB = DemoPersona(
    type: DemoPersonaType.personaB,
    label: 'Persona B (United States)',
    firstName: 'Alex',
    lastName: 'Morgan',
    username: 'alex',
    email: 'alex@hanbova.org',
    residenceCountry: 'US',
    roamEnabled: false,
    activeMarket: 'US',
    displayCurrency: FiatCurrency.usd,
    summary: 'Global wallet only (local bill services hidden)',
  );

  static const DemoPersona personaC = DemoPersona(
    type: DemoPersonaType.personaC,
    label: 'Persona C (US Traveler in Kenya)',
    firstName: 'Alex',
    lastName: 'Morgan',
    username: 'alex',
    email: 'alex@hanbova.org',
    residenceCountry: 'US',
    roamEnabled: true,
    activeMarket: 'KE',
    displayCurrency: FiatCurrency.kes,
    summary: 'Global wallet + Kenya local capabilities under Roam',
  );

  static const List<DemoPersona> all = [personaA, personaB, personaC];

  static Future<void> applyPersona(
      dynamic refOrContainer, DemoPersona persona) async {
    return _applyPersonaImpl(refOrContainer, persona);
  }
}

typedef DemoPersonas = DemoPersona;

Future<void> applyPersona(dynamic refOrContainer, DemoPersona persona) async {
  return _applyPersonaImpl(refOrContainer, persona);
}

Future<void> _applyPersonaImpl(
    dynamic refOrContainer, DemoPersona persona) async {
  final marketNotifier = refOrContainer is WidgetRef
      ? refOrContainer.read(marketProvider.notifier)
      : (refOrContainer as ProviderContainer).read(marketProvider.notifier);

  final profileNotifier = refOrContainer is WidgetRef
      ? refOrContainer.read(profileProvider.notifier)
      : (refOrContainer as ProviderContainer).read(profileProvider.notifier);

  // 1. Set residence country
  await marketNotifier.setResidenceCountry(persona.residenceCountry);

  // 2. Configure Roam or local active market
  if (persona.roamEnabled) {
    await marketNotifier.activateRoam(persona.activeMarket);
  } else {
    await marketNotifier.deactivateRoam();
  }

  // 3. Update profile
  await profileNotifier.updateProfile(
    firstName: persona.firstName,
    lastName: persona.lastName,
    username: persona.username,
    email: persona.email,
    residenceCountry: persona.residenceCountry,
  );
}
