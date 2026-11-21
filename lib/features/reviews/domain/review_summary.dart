class ReviewSummary {
  final int count;
  final double average;
  final Map<int, int> byStars;

  const ReviewSummary({
    required this.count,
    required this.average,
    required this.byStars,
  });

  factory ReviewSummary.fromRatings(Iterable<int> ratings) {
    final counts = {for (var s = 1; s <= 5; s++) s: 0};
    var total = 0;
    var sum = 0;
    for (final r in ratings) {
      if (r < 1 || r > 5) continue;
      counts[r] = counts[r]! + 1;
      total++;
      sum += r;
    }
    return ReviewSummary(
      count: total,
      average: total == 0 ? 0 : sum / total,
      byStars: counts,
    );
  }

  String get averageText => count == 0 ? '-' : average.toStringAsFixed(1);
}
