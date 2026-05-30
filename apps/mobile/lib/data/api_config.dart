class ApiConfig {
  const ApiConfig({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3000/api/v1',
    ),
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 20),
    this.getRetryCount = 1,
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int getRetryCount;
}
