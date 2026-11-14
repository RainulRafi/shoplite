String prettyCategory(String raw) {
  if (raw.isEmpty) return '';
  final spaced = raw.replaceAll('-', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}
