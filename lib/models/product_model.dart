import '../services/api_config.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int category;
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
    final rawImages = json['images'];
    final normalizedImages = <String>[];
    if (rawImages is List) {
      normalizedImages.addAll(
        rawImages.map((e) => _normalizeImagePath(e?.toString() ?? '')),
      );
    } else if (json['image'] != null) {
      normalizedImages.add(_normalizeImagePath(json['image'].toString()));
    }

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: (json['name'] ?? json['itemName'] ?? '').toString(),
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      category: _parseCategoryCode(json['category']),
      images: normalizedImages,
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

  /// URL suitable for Image.network (uses backend proxy for external images).
  String get displayImageUrl => toDisplayImageUrl(imageUrl);

  bool get hasNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  static const Map<int, String> categoryLabels = {
    0: 'All Items',
    1: 'Perfumes',
    2: 'Watches',
    3: 'Wallets',
    4: 'Shirts',
  };

  String get categoryLabel => categoryLabels[category] ?? 'All Items';

  // Helper method to format price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  static String toDisplayImageUrl(String rawPath) {
    final normalized = _normalizeImagePath(rawPath);
    if (normalized.isEmpty || normalized.startsWith('assets/')) {
      return normalized;
    }
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      return normalized;
    }

    return '${ApiConfig.baseUrl}/products/images/proxy?url=${Uri.encodeComponent(normalized)}';
  }

  static String _normalizeImagePath(String rawPath) {
    final path = _sanitizeImageUrl(rawPath.trim());
    if (path.isEmpty) return '';

    // Some records store Google Images wrapper links (imgres). Extract direct URL.
    final extractedGoogleImage = _extractGoogleImgResUrl(path);
    if (extractedGoogleImage != null && extractedGoogleImage.isNotEmpty) {
      return _sanitizeImageUrl(extractedGoogleImage);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('assets/')) {
      return path;
    }

    final apiUri = Uri.parse(ApiConfig.baseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    if (path.startsWith('/')) {
      return '$origin$path';
    }
    return '$origin/$path';
  }

  static String _sanitizeImageUrl(String url) {
    var sanitized = url
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
    if (sanitized.startsWith('http://')) {
      sanitized = 'https://${sanitized.substring('http://'.length)}';
    }
    return sanitized;
  }

  static String? _extractGoogleImgResUrl(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('google.') || !uri.path.contains('/imgres')) {
      return null;
    }

    final directUrl = uri.queryParameters['imgurl'] ?? uri.queryParameters['url'];
    if (directUrl == null || directUrl.trim().isEmpty) return null;
    return Uri.decodeFull(directUrl.trim());
  }

  static int _parseCategoryCode(dynamic rawCategory) {
    if (rawCategory == null) return 0;

    if (rawCategory is int) return rawCategory;
    if (rawCategory is num) return rawCategory.toInt();

    final value = rawCategory.toString().trim().toLowerCase();
    if (value.isEmpty) return 0;

    final asNumber = int.tryParse(value);
    if (asNumber != null) return asNumber;

    if (value.contains('perfume') || value.contains('fragrance') || value.contains('cologne')) {
      return 1;
    }
    if (value.contains('watch')) return 2;
    if (value.contains('wallet')) return 3;
    if (value.contains('shirt')) return 4;
    return 0;
  }
}

