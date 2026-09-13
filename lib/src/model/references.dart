import 'dart:typed_data';

import 'package:en16931/src/model/address.dart';
import 'package:en16931/src/types/calendar_date.dart';
import 'package:en16931/src/types/identifier.dart';

/// A stretch of days, from [start] to [end]. BG-14 and BG-26.
///
/// The period says when the supply happened, which is what decides the VAT
/// period it falls in. At least one of the two ends has to be given.
final class DatePeriod {
  /// The period running from [start] to [end], either of which may be left
  /// out when only one end is known.
  const DatePeriod({this.start, this.end});

  /// BT-73 or BT-134. The first day of the period.
  final CalendarDate? start;

  /// BT-74 or BT-135. The last day of the period, which is inside it.
  final CalendarDate? end;
}

/// BG-3. An earlier invoice this one corrects or reverses.
final class PrecedingInvoiceReference {
  /// The invoice numbered [reference], issued on [issueDate].
  const PrecedingInvoiceReference(this.reference, {this.issueDate});

  /// BT-25. The number of the earlier invoice.
  final String reference;

  /// BT-26. The day the earlier invoice was issued. Give it whenever the
  /// number alone does not single the invoice out.
  final CalendarDate? issueDate;
}

/// BG-24. A document that supports the invoice, named or carried along.
final class SupportingDocument {
  /// The document identified by [reference], either linked through
  /// [externalUri] or carried as [attachment].
  const SupportingDocument(
    this.reference, {
    this.description,
    this.externalUri,
    this.attachment,
  });

  /// BT-122. The identifier of the supporting document.
  final String reference;

  /// BT-123. What the document is, in words.
  final String? description;

  /// BT-124. Where the document can be fetched.
  final Uri? externalUri;

  /// BT-125. The document itself, carried inside the invoice.
  final Attachment? attachment;
}

/// BT-125. A file carried inside the invoice.
///
/// Both syntaxes base64 the bytes, so the model holds them as bytes and
/// leaves the encoding to the syntax.
final class Attachment {
  /// The file [bytes], of type [mimeCode] and named [filename].
  const Attachment({
    required this.bytes,
    required this.mimeCode,
    required this.filename,
  });

  /// The contents of the file.
  final Uint8List bytes;

  /// BT-125-1. The media type of the file. The standard allows a short list,
  /// PDF, PNG, JPEG, CSV and the two OpenDocument spreadsheet types.
  final String mimeCode;

  /// BT-125-2. The name the file is given.
  final String filename;
}

/// BG-13. Where and when the goods or services were delivered.
final class Delivery {
  /// A delivery, of which every part is optional on its own.
  const Delivery({this.name, this.locationIdentifier, this.date, this.address});

  /// BT-70. The name of the party the goods are delivered to.
  final String? name;

  /// BT-71. An identifier of the place of delivery, optionally under a
  /// scheme.
  final Identifier? locationIdentifier;

  /// BT-72. The day the goods or services were actually delivered.
  final CalendarDate? date;

  /// BG-15. The address delivered to.
  final Address? address;
}
