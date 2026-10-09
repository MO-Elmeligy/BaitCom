import 'api_transport_types.dart';

ApiTransport createApiTransport() => _UnsupportedApiTransport();

class _UnsupportedApiTransport implements ApiTransport {
  @override
  Future<ApiTransportResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  }) =>
      Future.error(UnsupportedError('No HTTP transport for this platform'));

  @override
  void close() {}
}
