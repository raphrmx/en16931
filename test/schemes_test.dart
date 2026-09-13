import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

/// Every register this package names, and the code it stands for.
///
/// The map is written out rather than read from the class, because a constant
/// class cannot be enumerated and a name that drifts from its code is exactly
/// what this test is for.
const Map<String, String> _named = {
  'sirene': Scheme.sirene,
  'swedishOrganisation': Scheme.swedishOrganisation,
  'siret': Scheme.siret,
  'finnishBusiness': Scheme.finnishBusiness,
  'duns': Scheme.duns,
  'gln': Scheme.gln,
  'danishProductionUnit': Scheme.danishProductionUnit,
  'dutchChamberOfCommerce': Scheme.dutchChamberOfCommerce,
  'australianBusinessNumber': Scheme.australianBusinessNumber,
  'swissUid': Scheme.swissUid,
  'danishCvr': Scheme.danishCvr,
  'japanCorporateNumber': Scheme.japanCorporateNumber,
  'dutchOin': Scheme.dutchOin,
  'estonianRegister': Scheme.estonianRegister,
  'norwegianOrganisation': Scheme.norwegianOrganisation,
  'singaporeUen': Scheme.singaporeUen,
  'icelandicKennitala': Scheme.icelandicKennitala,
  'danishSeNumber': Scheme.danishSeNumber,
  'legalEntityIdentifier': Scheme.legalEntityIdentifier,
  'lithuanianRegister': Scheme.lithuanianRegister,
  'italianIpa': Scheme.italianIpa,
  'germanLeitwegId': Scheme.germanLeitwegId,
  'belgianEnterprise': Scheme.belgianEnterprise,
  'gtin': Scheme.gtin,
  'gs1IdentificationKey': Scheme.gs1IdentificationKey,
  'italianFiscalCode': Scheme.italianFiscalCode,
  'italianVatNumber': Scheme.italianVatNumber,
  'finnishOrganisation': Scheme.finnishOrganisation,
};

void main() {
  group('Scheme', () {
    test('names a code the published lists actually hold', () {
      // A named register that no list holds would read as a helpful constant
      // and produce an invoice a receiver refuses.
      final known = {...iso6523Icd, ...cefEasSchemes};
      for (final entry in _named.entries) {
        expect(
          known,
          contains(entry.value),
          reason: '${entry.key} is ${entry.value}, which no list holds',
        );
      }
    });

    test('gives each register one code', () {
      expect(_named.values.toSet(), hasLength(_named.length));
    });

    test('is used where an identifier says which register it came from', () {
      const identifier = Identifier(
        '0123456749',
        scheme: Scheme.belgianEnterprise,
      );
      expect(identifier.scheme, '0208');
      expect(identifier.toString(), '0208:0123456749');
    });
  });
}
