import 'dart:js_interop';

import 'api_transport_types.dart';

@JS('fetch')
external JSPromise<_FetchResponse> _fetch(
  String resource, [
  _FetchOptions? options,
]);

@JS()
@anonymous
extension type _FetchOptions._(JSObject _) implements JSObject {
  external factory _FetchOptions({
    String? method,
    _FetchHeaders? headers,
    String? body,
  });
}

@JS()
@anonymous
extension type _FetchHeaders._(JSObject _) implements JSObject {
  external factory _FetchHeaders({
    @JS('Accept') String? accept,
    @JS('Content-Type') String? contentType,
  });
}

extension type _FetchResponse._(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
}

ApiTransport createApiTransport() => _BrowserApiTransport();

class _BrowserApiTransport implements ApiTransport {
  @override
  Future<ApiTransportResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  }) async {
    final options = _FetchOptions(
      method: method,
      headers: _FetchHeaders(
        accept: headers['Accept'],
        contentType: headers['Content-Type'],
      ),
      body: body,
    );
    final response = await _fetch(uri.toString(), options)
        .toDart
        .timeout(const Duration(seconds: 5));
    final responseBody =
        await response.text().toDart.timeout(const Duration(seconds: 5));
    return ApiTransportResponse(
      statusCode: response.status,
      body: responseBody.toDart,
    );
  }

  @override
  void close() {}
}
