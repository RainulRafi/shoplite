import '../../../core/validation/bd_phone.dart';

class ProfileValidators {
  ProfileValidators._();

  static String? firstName(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'Enter your first name';
    if (v.length > 40) return 'Keep the name under 40 characters';
    return null;
  }

  static String? lastName(String? raw) {
    if ((raw ?? '').trim().length > 40) {
      return 'Keep the name under 40 characters';
    }
    return null;
  }

  static String? phone(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    return normalizeBdPhone(v) == null ? bdPhoneHint : null;
  }
}
