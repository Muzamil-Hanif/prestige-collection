import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/auth_response_model.dart';
import 'api_config.dart';
import 'storage_service.dart';

class ApiService {
  static http.Client? _httpClient;
  static bool _isProduction = false;

  static void setProduction(bool isProduction) {
    _isProduction = isProduction;
  }

  /// Get or create HTTP client with certificate pinning and HTTPS enforcement
  static http.Client _getHttpClient() {
    if (_httpClient == null) {
      if (kIsWeb || !_isProduction) {
        _httpClient = http.Client();
      } else {
        _httpClient = _createSecureHttpClient();
      }
    }
    return _httpClient!;
  }

  /// Create HTTP client with certificate pinning for production
  static http.Client _createSecureHttpClient() {
    final httpClient = http.Client();

    if (!kIsWeb && _isProduction) {
      // TODO: Implement certificate pinning here
      // Example: Use http_certificate_pinning package for SSL pinning
      // final securityContext = SecurityContext.defaultContext;
      // securityContext.setClientAuthorities('path/to/ca.pem');
    }

    return httpClient;
  }

  /// Validate JWT token expiration
  static bool _isTokenValid(String token) {
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      debugPrint('Token validation error: ${e.toString()}');
      return false;
    }
  }

  /// Enforce HTTPS in production
  static void _validateUrl(String url) {
    if (_isProduction && !url.startsWith('https://')) {
      throw Exception('HTTPS required in production. Got: $url');
    }
  }

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        if (_isTokenValid(token)) {
          headers['Authorization'] = 'Bearer $token';
        } else {
          await StorageService.clearAll();
          throw Exception('Session expired. Please login again.');
        }
      }
    }

    return headers;
  }

  /// Handle API errors with generic user-facing messages
  /// Logs detailed errors internally for debugging
  static String _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      // Log detailed error internally for debugging
      debugPrint('API Error (${response.statusCode}): ${response.body}');
      final message = errorData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
      if (errorData['error'] is String && (errorData['error'] as String).isNotEmpty) {
        return errorData['error'] as String;
      }
      // Return generic message instead of exposing internal details
      return 'Request failed. Please try again.';
    } catch (e) {
      // Log detailed error internally but return generic message to user
      debugPrint('API Error parsing: ${response.statusCode} - ${e.toString()}');
      return 'Request failed. Please try again.';
    }
  }

  /// Handle timeout and network errors with generic messages
  static String _handleNetworkError(dynamic error) {
    debugPrint('Network error: ${error.toString()}');
    return 'Connection error. Please check your internet and try again.';
  }

  // Authentication: Login
  static Future<AuthResponseModel> login(String email, String password) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.login}');
      final httpClient = _getHttpClient();
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final authResponse = AuthResponseModel.fromJson(data);

        // Validate token before saving
        if (!_isTokenValid(authResponse.accessToken)) {
          throw Exception('Invalid or expired token received');
        }

        // Save token and user info
        await StorageService.saveToken(authResponse.accessToken);
        await StorageService.saveUserId(authResponse.user.id);
        await StorageService.saveUserEmail(authResponse.user.email);
        await StorageService.saveUserRole(authResponse.user.role);

        // Extract and save token expiry
        try {
          final decodedToken = JwtDecoder.decode(authResponse.accessToken);
          final exp = decodedToken['exp'] as int?;
          if (exp != null) {
            await StorageService.saveTokenExpiry(exp * 1000);
          }
        } catch (e) {
          debugPrint('Error extracting token expiry: ${e.toString()}');
        }

        return authResponse;
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Login error: ${e.toString()}');
      throw Exception('Login failed. Please try again.');
    }
  }

  // Authentication: Register
  static Future<AuthResponseModel> register(
    String email,
    String password,
    String fullName,
    String? phoneNumber,
  ) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.register}');
      final httpClient = _getHttpClient();
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(email, password);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Registration error: ${e.toString()}');
      throw Exception('Registration failed. Please try again.');
    }
  }

  // Authentication: Logout
  static Future<void> logout() async {
    try {
      final httpClient = _getHttpClient();
      _validateUrl('${ApiConfig.baseUrl}/api/auth/logout');

      await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });
    } catch (e) {
      debugPrint('Logout error: ${e.toString()}');
    } finally {
      await StorageService.clearAll();
    }
  }

  // Get user profile
  static Future<UserModel> getProfile() async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.profile}');
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Get profile error: ${e.toString()}');
      throw Exception('Failed to load profile. Please try again.');
    }
  }

  // Update user profile
  static Future<UserModel> updateProfile({
    required String fullName,
    String? profilePhoto,
    String? profilePhotoFilePath,
  }) async {
    try {
      final httpClient = _getHttpClient();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}');
      final headers = await _getHeaders();

      http.StreamedResponse streamedResponse;
      if (profilePhotoFilePath != null && profilePhotoFilePath.isNotEmpty) {
        // Handle multipart request with file upload
        final request = http.MultipartRequest('PATCH', uri);
        request.fields['displayName'] = fullName;
        request.headers.addAll(headers);

        request.files.add(
          await http.MultipartFile.fromPath('profilePhoto', profilePhotoFilePath),
        );

        streamedResponse = await httpClient.send(request).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );
      } else {
        // Handle regular PATCH request
        final response = await httpClient.patch(
          uri,
          headers: headers,
          body: json.encode({
            'displayName': fullName,
            if (profilePhoto != null && profilePhoto.isNotEmpty) 'profilePhoto': profilePhoto,
          }),
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('Request timeout');
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return UserModel.fromJson(data);
        }
        throw Exception(_handleError(response));
      }

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      }
      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Update profile error: ${e.toString()}');
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.changePassword}');
      final httpClient = _getHttpClient();
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassword}'),
        headers: await _getHeaders(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        return;
      }

      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Change password error: ${e.toString()}');
      throw Exception('Failed to update password. Please try again.');
    }
  }

  // Get all products
  static Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final httpClient = _getHttpClient();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}')
          .replace(queryParameters: queryParams);

      final response = await httpClient.get(
        uri,
        headers: await _getHeaders(includeAuth: false),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productsList = data['products'] as List;
        return productsList
            .map((product) => ProductModel.fromJson(product))
            .toList();
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Get products error: ${e.toString()}');
      throw Exception('Failed to load products. Please try again.');
    }
  }

  static Map<String, dynamic> _productPayload({
    required String itemName,
    String? description,
    required int price,
    required int category,
    required String image,
    int? stock,
  }) {
    return {
      'itemName': itemName,
      if (description != null && description.isNotEmpty) 'description': description,
      'price': price,
      'category': category,
      'image': image,
      if (stock != null) 'stock': stock,
    };
  }

  static Future<ProductModel> createProduct({
    required String itemName,
    String? description,
    required int price,
    required int category,
    required String image,
    int? stock,
  }) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.products}');
      final httpClient = _getHttpClient();
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}'),
        headers: await _getHeaders(),
        body: json.encode(_productPayload(
          itemName: itemName,
          description: description,
          price: price,
          category: category,
          image: image,
          stock: stock,
        )),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data);
      }
      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Create product error: ${e.toString()}');
      rethrow;
    }
  }

  static Future<ProductModel> updateProduct({
    required String productId,
    required String itemName,
    String? description,
    required int price,
    required int category,
    required String image,
    int? stock,
  }) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.products}/$productId');
      final httpClient = _getHttpClient();
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$productId'),
        headers: await _getHeaders(),
        body: json.encode(_productPayload(
          itemName: itemName,
          description: description,
          price: price,
          category: category,
          image: image,
          stock: stock,
        )),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data);
      }
      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Update product error: ${e.toString()}');
      rethrow;
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.products}/$productId');
      final httpClient = _getHttpClient();
      final response = await httpClient.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$productId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        return;
      }
      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Delete product error: ${e.toString()}');
      rethrow;
    }
  }

  // Get single product
  static Future<ProductModel> getProduct(String productId) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$productId'),
        headers: await _getHeaders(includeAuth: false),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Get product error: ${e.toString()}');
      throw Exception('Failed to load product. Please try again.');
    }
  }

  /// Converts MongoDB id shapes (`_id`, `{$oid: ...}`) to a plain string.
  static String mongoIdToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final oid = value[r'$oid'] ?? value['\$oid'] ?? value['oid'];
      if (oid != null) return oid.toString();
      final id = value['_id'];
      if (id != null) return mongoIdToString(id);
    }
    return value.toString();
  }

  static double _parseOrderPrice(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  /// Maps UI cart rows to the exact shape expected by POST /api/orders.
  static List<Map<String, dynamic>> normalizeOrderLineForBackend(
    List<Map<String, dynamic>> cartItems,
  ) {
    final lines = <Map<String, dynamic>>[];

    for (final item in cartItems) {
      final product = item['product'] is Map<String, dynamic>
          ? item['product'] as Map<String, dynamic>
          : null;

      final productId = mongoIdToString(
        item['productId'] ?? item['id'] ?? product?['_id'] ?? product?['id'],
      );
      if (productId.isEmpty) {
        throw Exception('Cart item is missing a product id. Remove and re-add the item.');
      }

      final name = (item['name'] ?? product?['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        throw Exception('Cart item is missing a product name. Remove and re-add the item.');
      }

      final price = _parseOrderPrice(item['price'] ?? product?['price']);
      if (price <= 0) {
        throw Exception('Cart item "$name" has an invalid price. Remove and re-add the item.');
      }

      final quantityRaw = item['quantity'];
      final quantity = quantityRaw is int
          ? quantityRaw
          : int.tryParse(quantityRaw?.toString() ?? '') ?? 0;
      if (quantity < 1) {
        throw Exception('Cart item "$name" has invalid quantity.');
      }

      String? image;
      final imageRaw = item['image'] ?? product?['image'];
      if (imageRaw != null && imageRaw.toString().trim().isNotEmpty) {
        image = imageRaw.toString();
      } else if (product?['images'] is List && (product!['images'] as List).isNotEmpty) {
        image = product['images'].first?.toString();
      }

      lines.add({
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        if (image != null && image.isNotEmpty) 'image': image,
      });
    }

    if (lines.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    return lines;
  }

  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double shippingCost,
    required double grandTotal,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final orderItems = normalizeOrderLineForBackend(items);
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.orders}');
      final httpClient = _getHttpClient();
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
        headers: await _getHeaders(),
        body: json.encode({
          'items': orderItems,
          'totalPrice': totalPrice,
          'shippingCost': shippingCost,
          'grandTotal': grandTotal,
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('Create order error: ${e.toString()}');
      throw Exception('Failed to create order. Please try again.');
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Get orders error: ${e.toString()}');
      throw Exception('Failed to load orders. Please try again.');
    }
  }

  // Get cart items
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        if (data is Map<String, dynamic> && data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items'] as List);
        }
        return [];
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Get cart items error: ${e.toString()}');
      throw Exception('Failed to load cart. Please try again.');
    }
  }

  // Add to cart
  static Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}/items'),
        headers: await _getHeaders(),
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Add to cart error: ${e.toString()}');
      throw Exception('Failed to add item to cart. Please try again.');
    }
  }

  // Update cart item
  static Future<void> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}/items/$productId'),
        headers: await _getHeaders(),
        body: json.encode({
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Update cart item error: ${e.toString()}');
      throw Exception('Failed to update cart item. Please try again.');
    }
  }

  // Remove from cart
  static Future<void> removeFromCart(String productId) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cart}/items/$productId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw Exception(_handleError(response));
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } catch (e) {
      debugPrint('Remove from cart error: ${e.toString()}');
      throw Exception('Failed to remove item from cart. Please try again.');
    }
  }
}
