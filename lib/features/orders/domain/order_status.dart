enum OrderStatus {
  placed('Order placed'),
  confirmed('Confirmed'),
  packed('Packed'),
  shipped('Shipped'),
  outForDelivery('Out for delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.title);
  final String title;
}
