class Product {
  final int id;
  final String title;
  final String description;
  final String category;

  final double price;
  final double discountPercentage;

  final double rating;
  final int stock;

  final String? brand;

  final String availabilityStatus;
  final String? shippingInformation;
  final String? warrantyInformation;
  final String? returnPolicy;

  final String thumbnail;
  final List<String> images;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description = '',
    this.category = '',
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.brand,
    this.availabilityStatus = '',
    this.shippingInformation,
    this.warrantyInformation,
    this.returnPolicy,
    this.thumbnail = '',
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,

      price: (json['price'] as num).toDouble(),

      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String?,
      availabilityStatus: json['availabilityStatus'] as String? ?? '',
      shippingInformation: json['shippingInformation'] as String?,
      warrantyInformation: json['warrantyInformation'] as String?,
      returnPolicy: json['returnPolicy'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',

      images:
          (json['images'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[],
    );
  }

  bool get hasDiscount => discountPercentage >= 1;

  double get discountedPrice => price * (1 - discountPercentage / 100);

  bool get inStock => stock > 0;
}
