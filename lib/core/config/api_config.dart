/// Configuration for API endpoints
class ApiConfig {
  /// Base URL for REST API endpoints
  static const String restBaseUrl = 'https://api.hive-app.io/v1';
  
  /// Base URL for WebSocket endpoints
  static const String webSocketBaseUrl = 'wss://realtime.hive-app.io/v1';
  
  /// Timeout duration for API requests in milliseconds
  static const int apiTimeoutMs = 30000;
  
  /// Max number of retries for failed requests
  static const int maxRetries = 3;
  
  /// WebSocket reconnect interval in milliseconds
  static const int wsReconnectIntervalMs = 5000;
  
  /// WebSocket ping interval in milliseconds
  static const int wsPingIntervalMs = 30000;
  
  /// Headers for API requests
  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-App-Version': '1.0.0',
      'X-Platform': 'flutter',
    };
  }
} 