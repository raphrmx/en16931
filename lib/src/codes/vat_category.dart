/// BT-95, BT-102, BT-118 and BT-151. The VAT treatment of an amount, from
/// UNCL 5305.
///
/// Unlike the other lists the standard points at, this one is closed: the
/// business rules name these codes one by one and attach a different set of
/// conditions to each.
///
/// {@category codes}
enum VatCategory {
  /// S. Standard rate. The rate is above zero and VAT is charged.
  standardRate('S'),

  /// Z. Zero rated goods. The rate is zero, and the supply is still taxable.
  zeroRated('Z'),

  /// E. Exempt from VAT. A reason has to be given.
  exempt('E'),

  /// AE. VAT reverse charge. The buyer accounts for the VAT.
  reverseCharge('AE'),

  /// K. Intra-community supply, exempt with the buyer accounting for the VAT.
  intraCommunitySupply('K'),

  /// G. Export outside the European Union, free of VAT.
  exportOutsideEu('G'),

  /// O. Outside the scope of VAT. The seller is not registered for VAT.
  outsideScope('O'),

  /// L. Canary Islands general indirect tax.
  canaryIslands('L'),

  /// M. Tax of Ceuta and Melilla.
  ceutaAndMelilla('M'),

  /// B. VAT transferred to the buyer. Italy uses it for the split payment of
  /// public bodies.
  transferred('B');

  const VatCategory(this.code);

  /// The code as UNCL 5305 writes it.
  final String code;

  /// The category [code] names, or null when the list does not hold it.
  static VatCategory? tryParse(String code) {
    for (final category in values) {
      if (category.code == code) return category;
    }
    return null;
  }

  @override
  String toString() => code;
}
