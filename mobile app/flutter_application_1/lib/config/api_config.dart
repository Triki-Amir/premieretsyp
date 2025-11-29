/// API Configuration for Energy Trading App
/// 
/// This file contains the configuration for connecting to the blockchain backend.
/// Update these values based on your environment:
/// 
/// - For web/desktop development: Use 'localhost'
/// - For Android emulator: Use '10.0.2.2' (emulator's special alias for host machine)
/// - For iOS simulator: Use 'localhost'
/// - For physical device: Use your computer's local IP address (e.g., '192.168.1.100')

class ApiConfig {
  // ==================== BACKEND SERVER CONFIGURATION ====================
  
  /// Base host for the blockchain backend API
  /// Change this based on your testing environment
  static const String _host = 'localhost'; // Change to '10.0.2.2' for Android emulator
  
  /// Port for the blockchain backend (Node.js app)
  static const int _port = 3000;
  
  /// Full base URL for API calls
  static String get baseUrl => 'http://$_host:$_port';
  
  /// API prefix
  static String get apiPath => '/api';
  
  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPath';
  
  // ==================== ENVIRONMENT-SPECIFIC CONFIGURATIONS ====================
  
  /// Configuration for local development on web/desktop
  static String get localWebUrl => 'http://localhost:$_port';
  
  /// Configuration for Android emulator
  static String get androidEmulatorUrl => 'http://10.0.2.2:$_port';
  
  /// Configuration for iOS simulator
  static String get iosSimulatorUrl => 'http://localhost:$_port';
  
  /// Configuration for physical device (update with your IP)
  /// Find your IP: Windows (ipconfig), Mac/Linux (ifconfig)
  static String get physicalDeviceUrl => 'http://192.168.1.100:$_port'; // Update this!
  
  // ==================== API ENDPOINTS ====================
  
  /// Authentication endpoints
  static String get loginEndpoint => '$baseUrl/login';
  static String get signupEndpoint => '$baseUrl/signup';
  static String get testEndpoint => '$baseUrl/test';
  
  /// Factory endpoints
  static String get factoriesEndpoint => '$apiBaseUrl/factories';
  static String factoryEndpoint(String factoryId) => '$apiBaseUrl/factory/$factoryId';
  static String factoryEnergyEndpoint(String factoryId) => '$apiBaseUrl/factory/$factoryId/energy';
  static String factoryBalanceEndpoint(String factoryId) => '$apiBaseUrl/factory/$factoryId/balance';
  static String factoryStatusEndpoint(String factoryId) => '$apiBaseUrl/factory/$factoryId/energy-status';
  static String factoryHistoryEndpoint(String factoryId) => '$apiBaseUrl/factory/$factoryId/history';
  
  /// Trade endpoints
  static String get tradesEndpoint => '$apiBaseUrl/trades';
  static String get createTradeEndpoint => '$apiBaseUrl/trade/create';
  static String get executeTradeEndpoint => '$apiBaseUrl/trade/execute';
  static String tradeDetailsEndpoint(String tradeId) => '$apiBaseUrl/trade/$tradeId';
  
  /// Offer endpoints
  static String get offersEndpoint => '$apiBaseUrl/offers';
  static String offerEndpoint(String offerId) => '$apiBaseUrl/offers/$offerId';
  
  /// Energy endpoints
  static String get mintEnergyEndpoint => '$apiBaseUrl/energy/mint';
  static String get transferEnergyEndpoint => '$apiBaseUrl/energy/transfer';
  
  /// Health check endpoint
  static String get healthEndpoint => '$apiBaseUrl/health';
  
  // ==================== TIMEOUTS ====================
  
  static const Duration standardTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);
  
  // ==================== HELPER METHODS ====================
  
  /// Set custom host (useful for testing on physical devices)
  static String? _customHost;
  
  static void setCustomHost(String host) {
    _customHost = host;
  }
  
  static String get currentHost => _customHost ?? _host;
  
  /// Get the appropriate URL based on the platform
  static String getUrlForPlatform({
    bool isWeb = false,
    bool isAndroidEmulator = false,
    bool isIosSimulator = false,
    bool isPhysicalDevice = false,
  }) {
    if (isWeb) return localWebUrl;
    if (isAndroidEmulator) return androidEmulatorUrl;
    if (isIosSimulator) return iosSimulatorUrl;
    if (isPhysicalDevice) return physicalDeviceUrl;
    return localWebUrl; // Default
  }
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    print('=== Energy Trading App - API Configuration ===');
    print('Base URL: $baseUrl');
    print('API Base URL: $apiBaseUrl');
    print('Host: $_host');
    print('Port: $_port');
    print('=============================================');
  }
}
