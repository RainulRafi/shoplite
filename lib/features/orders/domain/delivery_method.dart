enum DeliveryMethod {
  standard('Standard', 3, 5),
  express('Express', 1, 2);

  const DeliveryMethod(this.title, this.minDays, this.maxDays);

  final String title;
  final int minDays;
  final int maxDays;

  String get etaText =>
      minDays == maxDays ? '$minDays day' : '$minDays to $maxDays days';

  DateTime earliest(DateTime from) =>
      DateTime(from.year, from.month, from.day + minDays);
  DateTime latest(DateTime from) =>
      DateTime(from.year, from.month, from.day + maxDays);

  static DeliveryMethod fromName(String? name) => DeliveryMethod.values
      .firstWhere((m) => m.name == name, orElse: () => DeliveryMethod.standard);
}
