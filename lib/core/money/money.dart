import 'package:flutter/foundation.dart';

@immutable
class Money implements Comparable<Money> {
  final int cents;

  const Money(this.cents);

  static const Money zero = Money(0);

  factory Money.fromDollars(double dollars) => Money((dollars * 100).round());

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator -() => Money(-cents);
  Money operator *(int times) => Money(cents * times);

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  Money percent(num value) => Money((cents * value / 100).round());

  Money discountedBy(num percent) =>
      Money((cents * (100 - percent) / 100).round());

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;

  String format() {
    final abs = cents.abs();
    final grouped = (abs ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final rest = (abs % 100).toString().padLeft(2, '0');
    return '${cents < 0 ? '-' : ''}\$$grouped.$rest';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents)';
}
