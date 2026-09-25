/// A person or a department to write to. BG-6 and BG-9.
///
/// {@category invoice}
final class Contact {
  /// A contact, of which at least one field is usually given.
  const Contact({this.name, this.telephone, this.email});

  /// BT-41 or BT-56. The name of the person or of the department.
  final String? name;

  /// BT-42 or BT-57. The telephone number.
  final String? telephone;

  /// BT-43 or BT-58. The email address.
  final String? email;
}
