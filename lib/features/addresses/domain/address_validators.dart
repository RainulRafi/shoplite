import '../../../core/validation/bd_phone.dart';
import 'address.dart';
import 'bd_divisions.dart';

class AddressValidators {
  AddressValidators._();

  static const int maxAddresses = 10;

  static String? name(String? raw) {
    final v = (raw ?? '').trim();
    if (v.length < 2) return 'Enter the recipient name';
    if (v.length > 60) return 'Keep the name under 60 characters';
    return null;
  }

  static String? phone(String? raw) =>
      normalizeBdPhone(raw ?? '') == null ? bdPhoneHint : null;

  static String? division(String? raw) =>
      raw != null && bdDivisions.contains(raw) ? null : 'Choose a division';

  static String? district(String? raw) {
    final v = (raw ?? '').trim();
    if (v.length < 2) return 'Enter the district';
    if (v.length > 40) return 'Keep the district under 40 characters';
    return null;
  }

  static String? area(String? raw) {
    final v = (raw ?? '').trim();
    if (v.length < 2) return 'Enter the area or thana';
    if (v.length > 60) return 'Keep the area under 60 characters';
    return null;
  }

  static String? line1(String? raw) {
    final v = (raw ?? '').trim();
    if (v.length < 5) return 'Enter the house, road or village';
    if (v.length > 120) return 'Keep this under 120 characters';
    return null;
  }

  static String? postalCode(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    return RegExp(r'^\d{4}$').hasMatch(v) ? null : 'Postal codes have 4 digits';
  }

  static String? note(String? raw) {
    if ((raw ?? '').trim().length > 120) {
      return 'Keep the note under 120 characters';
    }
    return null;
  }

  static Map<String, String> validateAll(Address a) {
    final errors = <String, String>{};
    void check(String field, String? error) {
      if (error != null) errors[field] = error;
    }

    check('name', name(a.fullName));
    check('phone', phone(a.phone));
    check('division', division(a.division));
    check('district', district(a.district));
    check('area', area(a.area));
    check('line1', line1(a.line1));
    check('postalCode', postalCode(a.postalCode));
    check('note', note(a.note));
    return errors;
  }
}
