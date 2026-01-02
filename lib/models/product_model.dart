class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final String category;
  final List<String> images;
  final int stock;
  final bool isAvailable;
  final Map<String, dynamic>? specifications;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.images,
    required this.stock,
    required this.isAvailable,
    this.specifications,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      category: json['category'] ?? '',
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      stock: json['stock'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      specifications: json['specifications'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'images': images,
      'stock': stock,
      'isAvailable': isAvailable,
      'specifications': specifications,
    };
  }

  // Helper method to get first image or default
  String get imageUrl {
    if (images.isNotEmpty) {
      return images.first;
    }
    return '';
  }

  // Helper method to format price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }
}

