import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/data/api_transport_types.dart';
import 'package:real_estate_app/data/real_estate_api.dart';
import 'package:real_estate_app/models/property_listing.dart';
import 'package:real_estate_app/models/property_media.dart';
import 'package:real_estate_app/utils/phone_number.dart';

void main() {
  test('sends Firebase ID tokens as Bearer authorization', () async {
    final transport = _FakeApiTransport();
    final api = RealEstateApi(
      idTokenProvider: () async => 'test-id-token',
      transport: transport,
    );
    addTearDown(api.close);

    final user = await api.getCurrentUser();

    expect(user['id'], 'user-1');
    expect(transport.headers?['Authorization'], 'Bearer test-id-token');
  });

  test('omits authorization when no Firebase ID token is available', () async {
    final transport = _FakeApiTransport();
    final api = RealEstateApi(
      idTokenProvider: () async => null,
      transport: transport,
    );
    addTearDown(api.close);

    await api.getCurrentUser();

    expect(transport.headers, isNot(contains('Authorization')));
  });

  test('round-trips property media in the API model', () {
    const listing = PropertyListing(
      id: 'property-1',
      title: 'Test property',
      city: 'Cairo',
      district: 'Nasr City',
      priceEgp: 1200000,
      areaM2: 120,
      bedrooms: 2,
      propertyType: 'apartment',
      media: [
        PropertyMedia(
          url: 'https://res.cloudinary.com/baitco/video/upload/sample.mp4',
          type: 'video',
        ),
      ],
    );

    final decoded = PropertyListing.fromJson(listing.toJson());

    expect(decoded.media, hasLength(1));
    expect(decoded.media.single.url, listing.media.single.url);
    expect(decoded.media.single.type, 'video');
  });

  test('normalizes Egyptian contact phone numbers for listings', () {
    expect(normalizeContactPhoneNumber('010 1234 5678'), '+201012345678');
    expect(normalizeContactPhoneNumber('+1 (212) 555-0100'), '+12125550100');
    expect(normalizeContactPhoneNumber('123'), isNull);
  });

  test('round-trips listing contact phone numbers', () {
    const listing = PropertyListing(
      id: 'property-2',
      title: 'Contact listing',
      city: 'Cairo',
      district: 'Nasr City',
      priceEgp: 1200000,
      areaM2: 120,
      bedrooms: 2,
      propertyType: 'apartment',
      contactPhone: '+201012345678',
    );

    expect(
      PropertyListing.fromJson(listing.toJson()).contactPhone,
      listing.contactPhone,
    );
  });
}

class _FakeApiTransport implements ApiTransport {
  Map<String, String>? headers;

  @override
  Future<ApiTransportResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  }) async {
    this.headers = headers;
    return const ApiTransportResponse(
      statusCode: 200,
      body: '{"data":{"id":"user-1"}}',
    );
  }

  @override
  void close() {}
}
