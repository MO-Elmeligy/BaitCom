import 'api_transport_types.dart';
import 'api_transport_stub.dart'
    if (dart.library.io) 'api_transport_io.dart'
    if (dart.library.html) 'api_transport_web.dart' as implementation;

export 'api_transport_types.dart';

ApiTransport createApiTransport() => implementation.createApiTransport();
