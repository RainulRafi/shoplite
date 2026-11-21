class ReviewValidators {
  ReviewValidators._();

  static const int minComment = 10;
  static const int maxComment = 500;

  static String? rating(int? value) =>
      (value == null || value < 1 || value > 5) ? 'Choose a star rating' : null;

  static String? comment(String? raw) {
    final v = (raw ?? '').trim();
    if (v.length < minComment) return 'Write at least $minComment characters';
    if (v.length > maxComment) return 'Keep it under $maxComment characters';
    return null;
  }
}
