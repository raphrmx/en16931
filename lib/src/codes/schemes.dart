/// The registers an identifier can be issued under.
///
/// An identifier on its own is a string of digits. What makes it findable is
/// the register it came from, which is what [Identifier.scheme] carries: 0208
/// is the Belgian enterprise register, 0088 is GS1, 0060 is Dun and
/// Bradstreet.
///
/// These are not an enum on purpose. The codes are drawn from several lists
/// depending on which term carries them, a party identifier from ISO 6523 and
/// an electronic address from the EAS list, and both are revised without the
/// standard being revised. The EAS list is also narrowed by a profile: Peppol
/// carries fewer of them than the standard allows. A closed set would have
/// frozen one list and made the other unreachable.
///
/// The names below are the registers that come up. Any other code from the
/// same list is written as it is, and `iso6523Icd` and `cefEasSchemes` say
/// which codes each list holds.
abstract final class Scheme {
  /// 0002. The French SIRENE register.
  static const String sirene = '0002';

  /// 0007. The Swedish organisation number.
  static const String swedishOrganisation = '0007';

  /// 0009. The French SIRET, which identifies an establishment.
  static const String siret = '0009';

  /// 0037. The Finnish business identity code.
  static const String finnishBusiness = '0037';

  /// 0060. A Dun and Bradstreet number.
  static const String duns = '0060';

  /// 0088. A GS1 global location number.
  static const String gln = '0088';

  /// 0096. A Danish production unit number.
  static const String danishProductionUnit = '0096';

  /// 0106. The Dutch chamber of commerce register.
  static const String dutchChamberOfCommerce = '0106';

  /// 0151. An Australian Business Number.
  static const String australianBusinessNumber = '0151';

  /// 0160. A GS1 global trade item number, which is what a barcode carries.
  static const String gtin = '0160';

  /// 0183. The Swiss unique identification number.
  static const String swissUid = '0183';

  /// 0184. The Danish CVR number.
  static const String danishCvr = '0184';

  /// 0188. The Japanese corporate number.
  static const String japanCorporateNumber = '0188';

  /// 0190. The Dutch organisation identification number.
  static const String dutchOin = '0190';

  /// 0191. The Estonian register of companies.
  static const String estonianRegister = '0191';

  /// 0192. The Norwegian organisation number.
  static const String norwegianOrganisation = '0192';

  /// 0195. The Singapore unique entity number.
  static const String singaporeUen = '0195';

  /// 0196. The Icelandic kennitala.
  static const String icelandicKennitala = '0196';

  /// 0198. The Danish SE number.
  static const String danishSeNumber = '0198';

  /// 0199. A legal entity identifier, which is issued worldwide.
  static const String legalEntityIdentifier = '0199';

  /// 0200. The Lithuanian register of legal entities.
  static const String lithuanianRegister = '0200';

  /// 0201. The Italian IPA code of a public body.
  static const String italianIpa = '0201';

  /// 0204. The German Leitweg-ID, which routes an invoice to a public body.
  static const String germanLeitwegId = '0204';

  /// 0208. The Belgian enterprise register.
  static const String belgianEnterprise = '0208';

  /// 0209. A GS1 identification key.
  static const String gs1IdentificationKey = '0209';

  /// 0210. The Italian fiscal code.
  static const String italianFiscalCode = '0210';

  /// 0211. The Italian VAT number.
  static const String italianVatNumber = '0211';

  /// 0212. The Finnish organisation identifier.
  static const String finnishOrganisation = '0212';
}
