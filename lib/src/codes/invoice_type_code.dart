import 'package:en16931/src/codes/code_value.dart';

/// BT-3. What kind of document this is, from UNTDID 1001.
///
/// The code decides how the receiver books the document, and a profile
/// narrows the list further. A credit note is a type, not a negative invoice.
///
/// {@category codes}
final class InvoiceTypeCode extends CodeValue {
  /// Holds [value] as it appears in UNTDID 1001.
  const InvoiceTypeCode(super.value);

  /// 380. The ordinary invoice.
  static const InvoiceTypeCode commercialInvoice = InvoiceTypeCode('380');

  /// 381. Reverses an earlier invoice, in whole or in part.
  static const InvoiceTypeCode creditNote = InvoiceTypeCode('381');

  /// 383. Adds to an earlier invoice.
  static const InvoiceTypeCode debitNote = InvoiceTypeCode('383');

  /// 384. Replaces an earlier invoice, which it names.
  static const InvoiceTypeCode correctedInvoice = InvoiceTypeCode('384');

  /// 386. Asks for payment before the goods or services are delivered.
  static const InvoiceTypeCode prepaymentInvoice = InvoiceTypeCode('386');

  /// 389. Written by the buyer, on behalf of the seller.
  static const InvoiceTypeCode selfBilledInvoice = InvoiceTypeCode('389');

  /// 393. Invoice assigned to a factor.
  static const InvoiceTypeCode factoredInvoice = InvoiceTypeCode('393');
}
