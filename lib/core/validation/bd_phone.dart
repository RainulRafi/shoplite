const String bdPhoneHint = 'Enter a mobile number like 01712345678';

String? normalizeBdPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (digits.startsWith('+880')) {
    digits = '0${digits.substring(4)}';
  } else if (digits.startsWith('880')) {
    digits = '0${digits.substring(3)}';
  }
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits) ? digits : null;
}
