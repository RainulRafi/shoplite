enum PaymentMethod {
  cashOnDelivery('Cash on delivery'),
  onlineDemo('Online payment (demo)');

  const PaymentMethod(this.title);
  final String title;

  static PaymentMethod fromName(String? name) =>
      PaymentMethod.values.firstWhere(
        (m) => m.name == name,
        orElse: () => PaymentMethod.cashOnDelivery,
      );
}

enum PaymentStatus {
  payOnDelivery('Pay on delivery'),
  paidDemo('Paid (demo)');

  const PaymentStatus(this.title);
  final String title;

  static PaymentStatus fromName(String? name) =>
      PaymentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PaymentStatus.payOnDelivery,
      );
}
