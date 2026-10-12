import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'api_transport.dart';
import '../models/partnership_project.dart';
import '../models/property_listing.dart';

/// Multi-platform HTTP client using the browser transport on web and
/// dart:io only on native platforms via conditional imports.
typedef IdTokenProvider = Future<String?> Function();

class RealEstateApi {
  RealEstateApi({IdTokenProvider? idTokenProvider, ApiTransport? transport})
    : _client = transport ?? createApiTransport(),
      _idTokenProvider = idTokenProvider;

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      final uri = Uri.tryParse(_configuredBaseUrl);
      if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
        throw StateError('API_BASE_URL must be an absolute URL.');
      }
      if (kReleaseMode && uri.scheme != 'https') {
        throw StateError('Release builds require an HTTPS API_BASE_URL.');
      }
      return _configuredBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError(
        'Set API_BASE_URL to the deployed HTTPS API before building a release.',
      );
    }

    return (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS)
        ? 'http://localhost:3000'
        : 'http://10.0.2.2:3000';
  }

  final ApiTransport _client;
  final IdTokenProvider? _idTokenProvider;
  static const _timeout = Duration(seconds: 5);

  Future<String> createDevelopmentSession() async {
    final result =
        await _request('GET', '/api/dev/session') as Map<String, dynamic>;
    return (result['data'] as Map<String, dynamic>)['userId'] as String;
  }

  Future<List<PropertyListing>> getProperties({String? query}) async {
    final data = await _getList(
      '/api/properties',
      query: {if (query != null && query.trim().isNotEmpty) 'q': query.trim()},
    );
    return data.map(PropertyListing.fromJson).toList();
  }

  Future<List<PartnershipProject>> getProjects({String? query}) async {
    final data = await _getList(
      '/api/partnership-projects',
      query: {if (query != null && query.trim().isNotEmpty) 'q': query.trim()},
    );
    return data.map(PartnershipProject.fromJson).toList();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final result = await _request('GET', '/api/me') as Map<String, dynamic>;
    return result['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMediaUploadSignature(
    String resourceType,
  ) async {
    if (resourceType != 'image' && resourceType != 'video') {
      throw ArgumentError.value(resourceType, 'resourceType');
    }
    final result =
        await _request(
              'POST',
              '/api/media/signature',
              body: {'resourceType': resourceType},
            )
            as Map<String, dynamic>;
    return result['data'] as Map<String, dynamic>;
  }

  Future<List<PropertyListing>> getMyProperties([
    String? developmentUserId,
  ]) async {
    final data = await _getList(
      developmentUserId == null
          ? '/api/me/properties'
          : '/api/dev/my-properties',
      query: developmentUserId == null
          ? const {}
          : {'userId': developmentUserId},
    );
    return data.map(PropertyListing.fromJson).toList();
  }

  Future<List<PartnershipProject>> getMyProjects([
    String? developmentUserId,
  ]) async {
    final data = await _getList(
      developmentUserId == null
          ? '/api/me/partnership-projects'
          : '/api/dev/my-partnership-projects',
      query: developmentUserId == null
          ? const {}
          : {'userId': developmentUserId},
    );
    return data.map(PartnershipProject.fromJson).toList();
  }

  Future<PropertyListing> createProperty({
    String? ownerId,
    required PropertyListing listing,
  }) async {
    final body = <String, Object?>{...listing.toJson()};
    if (ownerId case final value?) {
      body['ownerId'] = value;
    }
    final result =
        await _request('POST', '/api/properties', body: body)
            as Map<String, dynamic>;
    return PropertyListing.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<PartnershipProject> createProject({
    String? managerId,
    required PartnershipProject project,
  }) async {
    final body = <String, Object?>{
      'title': project.title,
      'description': project.description,
      'city': project.city,
      'district': project.district,
      'targetMembers': project.targetMembers,
      'expectedDurationMonths': project.expectedDurationMonths,
      'totalUnits': project.totalUnits,
      'landPriceEgp': project.landPriceEgp,
      'estimatedBuildCostEgp': project.estimatedBuildCostEgp,
      'minimumContributionEgp': project.minimumContributionEgp,
      'contactPhone': project.contactPhone,
    };
    if (managerId case final value?) {
      body['managerId'] = value;
    }
    final result =
        await _request('POST', '/api/partnership-projects', body: body)
            as Map<String, dynamic>;
    return PartnershipProject.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> requestToJoinProject({
    required String projectId,
    required double requestedContributionEgp,
    String? unitId,
  }) async {
    final body = <String, Object?>{
      'requestedContributionEgp': requestedContributionEgp,
    };
    if (unitId case final value?) {
      body['unitId'] = value;
    }
    final response =
        await _request(
              'POST',
              '/api/partnership-projects/$projectId/join',
              body: body,
            )
            as Map<String, dynamic>;
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final result =
        await _request('GET', path, query: query) as Map<String, dynamic>;
    return (result['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final idToken = (await _idTokenProvider?.call())?.trim();
    final response = await _client
        .send(
          uri,
          method: method,
          headers: {
            'Accept': 'application/json',
            if (body != null) 'Content-Type': 'application/json',
            if (idToken != null && idToken.isNotEmpty)
              'Authorization': 'Bearer $idToken',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ??
                'Request failed (${response.statusCode})'
          : 'Request failed (${response.statusCode})';
      throw Exception(message);
    }
    return decoded;
  }

  void close() => _client.close();
}
