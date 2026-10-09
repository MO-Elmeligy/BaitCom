import 'dart:convert';
import 'dart:io';

import 'api_transport_types.dart';

ApiTransport createApiTransport() => _IoApiTransport();

class _IoApiTransport implements ApiTransport {
  final HttpClient _client = HttpClient();

  @override
  Future<ApiTransportResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = await _client.openUrl(method, uri).timeout(
          const Duration(seconds: 5),
        );
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close().timeout(const Duration(seconds: 5));
    final responseBody = await response.transform(utf8.decoder).join();
    return ApiTransportResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }

  @override
  void close() => _client.close(force: true);
}
