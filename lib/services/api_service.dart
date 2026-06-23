import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/auth_response_model.dart';
import 'api_config.dart';
import 'session_manager.dart';
import 'storage_service.dart';

// dart:io is unavailable on web; import conditionally so SocketException
// is available on native platforms but the file still compiles on web.
import 'socket_exception_stub.dart'
    if (dart.library.io) 'dart:io' show SocketException;

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
          // Don't just throw — redirect to sign-in immediately so the user
          // isn't left on a stale screen until they manually refresh.
          await SessionManager.forceLogout(
            message: 'Session expired. Please login again.',
          );
          throw Exception('Session expired. Please login again.');
        }
      }
    }

    return headers;
  }

  /// Handle API errors with generic user-facing messages
  /// Logs detailed errors internally for debugging
  ///
  /// [isAuthenticatedRequest] should be false for endpoints that don't send
  /// a token (login, register, public product listing) — a 401 there means
  /// "wrong credentials", not "session expired", so it must not trigger a
  /// forced redirect to sign-in.
  static String _handleError(
    http.Response response, {
    bool isAuthenticatedRequest = true,
  }) {
    if (isAuthenticatedRequest && response.statusCode == 401) {
      // Backend rejected the token (revoked/invalid) even though it looked
      // valid locally — redirect immediately instead of leaving the user
      // stuck on a stale screen.
      unawaited(SessionManager.forceLogout(
        message: 'Session expired. Please login again.',
      ));
    }
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

  // Authentication: Login — retries once with a fresh client on transient failure.
  static Future<AuthResponseModel> login(String email, String password) async {
    return _loginAttempt(email, password, isRetry: false);
  }

  static Future<AuthResponseModel> _loginAttempt(
    String email,
    String password, {
    required bool isRetry,
  }) async {
    bool isTransientError = false;
    try {
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.login}');
      // Always use a fresh client for login so a stale/broken singleton never
      // blocks the user. The client is lightweight and not reused here.
      final httpClient = http.Client();
      late http.Response response;
      try {
        response = await httpClient
            .post(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
              headers: const {'Content-Type': 'application/json'},
              body: json.encode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('Login request timed out');
        });
      } finally {
        httpClient.close();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final authResponse = AuthResponseModel.fromJson(data);

        if (authResponse.accessToken.isEmpty) {
          throw Exception('No token received from server. Please try again.');
        }
        if (!_isTokenValid(authResponse.accessToken)) {
          throw Exception('Received an invalid session token. Please try again.');
        }

        // Persist credentials; wrap separately so a storage hiccup doesn't
        // report a fake "login failed" when the server already accepted the creds.
        try {
          await StorageService.saveToken(authResponse.accessToken);
          await StorageService.saveUserId(authResponse.user.id);
          await StorageService.saveUserEmail(authResponse.user.email);
          await StorageService.saveUserRole(authResponse.user.role);
          try {
            final decoded = JwtDecoder.decode(authResponse.accessToken);
            final exp = decoded['exp'] as int?;
            if (exp != null) await StorageService.saveTokenExpiry(exp * 1000);
          } catch (_) {}
        } catch (storageError) {
          debugPrint('Storage error after login: $storageError');
          // Storage failed but login itself succeeded; retry storage once.
          if (!isRetry) {
            return _loginAttempt(email, password, isRetry: true);
          }
          // On second storage failure, still let the user in — the session
          // will last until the app restarts and re-prompts for login.
          debugPrint('Persistent storage failure; session will not survive restart.');
        }

        return authResponse;
      } else {
        // Server explicitly rejected the request — do not retry.
        throw Exception(_handleError(response, isAuthenticatedRequest: false));
      }
    } on SocketException catch (e) {
      isTransientError = true;
      if (!isRetry) {
        debugPrint('Network error on login attempt 1, retrying: $e');
        _httpClient = null; // reset singleton so retry gets a fresh pool
        return _loginAttempt(email, password, isRetry: true);
      }
      throw Exception(_handleNetworkError(e));
    } on TimeoutException catch (e) {
      isTransientError = true;
      if (!isRetry) {
        debugPrint('Timeout on login attempt 1, retrying: $e');
        _httpClient = null;
        return _loginAttempt(email, password, isRetry: true);
      }
      throw Exception('Connection timed out. Please check your internet and try again.');
    } catch (e) {
      final msg = e.toString();
      debugPrint('Login error (retry=$isRetry): $msg');
      // Only retry unknown errors once, not server-side auth rejections.
      if (!isRetry && !isTransientError && !_isAuthRejection(msg)) {
        _httpClient = null;
        return _loginAttempt(email, password, isRetry: true);
      }
      // Preserve the error message if it's already descriptive enough.
      if (msg.contains('Exception: ') &&
          !msg.contains('Login failed') &&
          !msg.contains('null')) {
        rethrow;
      }
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Returns true when the error clearly came from server-side credential
  /// rejection (not a transient network issue), so we don't retry it.
  static bool _isAuthRejection(String message) {
    final lower = message.toLowerCase();
    return lower.contains('invalid credentials') ||
        lower.contains('unauthorized') ||
        lower.contains('wrong password') ||
        lower.contains('user not found') ||
        lower.contains('401');
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
        throw Exception(_handleError(response, isAuthenticatedRequest: false));
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
        throw Exception(_handleError(response, isAuthenticatedRequest: false));
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
        throw Exception(_handleError(response, isAuthenticatedRequest: false));
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
    String? walletPhoneNumber,
  }) async {
    try {
      final orderItems = normalizeOrderLineForBackend(items);
      _validateUrl('${ApiConfig.baseUrl}${ApiConfig.orders}');
      final httpClient = _getHttpClient();
      final orderBody = {
        'items': orderItems,
        'totalPrice': totalPrice,
        'shippingCost': shippingCost,
        'grandTotal': grandTotal,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      };
      if (walletPhoneNumber != null) {
        orderBody['walletPhoneNumber'] = walletPhoneNumber;
      }
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
        headers: await _getHeaders(),
        body: json.encode(orderBody),
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

  // Get all orders (admin only)
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}/all'),
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
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('Get all orders error: ${e.toString()}');
      throw Exception('Failed to load orders. Please try again.');
    }
  }

  // Get a single order by ID (used by the order details screen to fetch
  // the latest status when tracking an order)
  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}/$orderId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('Get order error: ${e.toString()}');
      throw Exception('Failed to load order. Please try again.');
    }
  }

  // Update order status (admin only)
  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final httpClient = _getHttpClient();
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}/$orderId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(_handleError(response));
      }
    } on SocketException catch (e) {
      throw Exception(_handleNetworkError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('Update order status error: ${e.toString()}');
      throw Exception('Failed to update order status. Please try again.');
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
