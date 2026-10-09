class ApiTransportResponse {
  const ApiTransportResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class ApiTransport {
  Future<ApiTransportResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  });

  void close();
}
