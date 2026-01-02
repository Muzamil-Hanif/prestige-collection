class ApiConfig {
  // Change this to your backend URL
  // For iOS Simulator/Android Emulator: use 'http://localhost:3000'
  // For real device: use your computer's IP address, e.g., 'http://192.168.1.100:3000'
  static const String baseUrl = 'http://localhost:3000/api';
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/users/register';
  static const String profile = '/users/profile';
  static const String products = '/products';
  static const String orders = '/orders';
}

