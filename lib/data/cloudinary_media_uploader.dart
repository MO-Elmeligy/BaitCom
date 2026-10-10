import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/property_media.dart';

typedef MediaUploadSignatureProvider = Future<Map<String, dynamic>> Function(
  String resourceType,
);

class CloudinaryMediaUploader {
  CloudinaryMediaUploader({
    required MediaUploadSignatureProvider signatureProvider,
    http.Client? client,
  })  : _signatureProvider = signatureProvider,
        _client = client ?? http.Client();

  static const maxUploadBytes = 25 * 1024 * 1024;
  static const _timeout = Duration(minutes: 2);

  final MediaUploadSignatureProvider _signatureProvider;
  final http.Client _client;

  Future<PropertyMedia> upload(XFile file) async {
    final resourceType = _resourceType(file);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxUploadBytes) {
      throw Exception('Media files must be between 1 byte and 25 MB.');
    }

    final signature = await _signatureProvider(resourceType);
    final cloudName = signature['cloudName'] as String;
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll({
        'api_key': signature['apiKey'] as String,
        'timestamp': signature['timestamp'].toString(),
        'folder': signature['folder'] as String,
        'public_id': signature['publicId'] as String,
        'signature': signature['signature'] as String,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final streamedResponse = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Cloudinary upload failed (${response.statusCode}).';
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] != null) {
          message = error['message'].toString();
        }
      }
      throw Exception(message);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['secure_url'] is! String ||
        decoded['resource_type'] != resourceType) {
      throw const FormatException('Cloudinary returned an invalid media result.');
    }

    return PropertyMedia(
      url: decoded['secure_url'] as String,
      type: resourceType,
    );
  }

  String _resourceType(XFile file) {
    final mimeType = file.mimeType?.toLowerCase();
    if (mimeType?.startsWith('image/') ?? false) return 'image';
    if (mimeType?.startsWith('video/') ?? false) return 'video';

    final extension = file.name.split('.').last.toLowerCase();
    if (const {'mp4', 'mov', 'm4v', 'webm'}.contains(extension)) {
      return 'video';
    }
    if (const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)) {
      return 'image';
    }
    throw const FormatException('Choose a supported image or video file.');
  }

  void close() => _client.close();
}
