import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/auth_response_model.dart';
import 'api_config.dart';
import 'storage_service.dart';

class ApiService {
  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API errors
  static String _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      return errorData['message'] ?? 'An error occurred';
    } catch (e) {
      return 'An error occurred: ${response.statusCode}';
    }
  }

  // Authentication: Login
  static Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final authResponse = AuthResponseModel.fromJson(data);
        
        // Save token and user info
        await StorageService.saveToken(authResponse.accessToken);
        await StorageService.saveUserId(authResponse.user.id);
        await StorageService.saveUserEmail(authResponse.user.email);
        
        return authResponse;
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration returns user, but we need to login to get token
        // So we'll login after registration
        return await login(email, password);
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Get user profile
  static Future<UserModel> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
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

      final response = await http.get(
        uri,
        headers: await _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productsList = data['products'] as List;
        return productsList
            .map((product) => ProductModel.fromJson(product))
            .toList();
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }

  // Get single product
  static Future<ProductModel> getProduct(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}/$productId'),
        headers: await _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data);
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch product: ${e.toString()}');
    }
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
        headers: await _getHeaders(),
        body: json.encode({
          'items': items,
          'totalPrice': totalPrice,
          'shippingCost': shippingCost,
          'grandTotal': grandTotal,
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      throw Exception('Failed to fetch orders: ${e.toString()}');
    }
  }
}

