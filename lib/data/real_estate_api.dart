import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'api_transport.dart';
import '../models/partnership_project.dart';
import '../models/property_listing.dart';

/// Multi-platform HTTP client using the browser transport on web and
/// dart:io only on native platforms via conditional imports.
class RealEstateApi {
  RealEstateApi() : _client = createApiTransport();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl => _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS
          ? 'http://localhost:3000'
          : 'http://10.0.2.2:3000');

  final ApiTransport _client;
  static const _timeout = Duration(seconds: 5);

  Future<String> createDevelopmentSession() async {
    final result =
        await _request('GET', '/api/dev/session') as Map<String, dynamic>;
    return (result['data'] as Map<String, dynamic>)['userId'] as String;
  }

  Future<List<PropertyListing>> getProperties({String? query}) async {
    final data = await _getList('/api/properties', query: {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
    return data.map(PropertyListing.fromJson).toList();
  }

  Future<List<PartnershipProject>> getProjects({String? query}) async {
    final data = await _getList('/api/partnership-projects', query: {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
    return data.map(PartnershipProject.fromJson).toList();
  }

  Future<List<PropertyListing>> getMyProperties(String userId) async {
    final data =
        await _getList('/api/dev/my-properties', query: {'userId': userId});
    return data.map(PropertyListing.fromJson).toList();
  }

  Future<List<PartnershipProject>> getMyProjects(String userId) async {
    final data = await _getList('/api/dev/my-partnership-projects',
        query: {'userId': userId});
    return data.map(PartnershipProject.fromJson).toList();
  }

  Future<PropertyListing> createProperty({
    required String ownerId,
    required PropertyListing listing,
  }) async {
    final result = await _request('POST', '/api/properties', body: {
      ...listing.toJson(),
      'ownerId': ownerId,
    }) as Map<String, dynamic>;
    return PropertyListing.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<PartnershipProject> createProject({
    required String managerId,
    required PartnershipProject project,
  }) async {
    final result = await _request('POST', '/api/partnership-projects', body: {
      'managerId': managerId,
      'title': project.title,
      'description': project.description,
      'city': project.city,
      'district': project.district,
      'targetMembers': project.targetMembers,
      'expectedDurationMonths': project.expectedDurationMonths,
      'totalUnits': project.totalUnits,
      'landPriceEgp': project.landPriceEgp,
      'estimatedBuildCostEgp': project.estimatedBuildCostEgp,
    }) as Map<String, dynamic>;
    return PartnershipProject.fromJson(result['data'] as Map<String, dynamic>);
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
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client
        .send(
          uri,
          method: method,
          headers: {
            'Accept': 'application/json',
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
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
