import 'package:flutter/material.dart';

import 'property_media.dart';

/// Mirrors [properties] in backend/schema.sql (published listings for the feed).
class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.priceEgp,
    required this.areaM2,
    required this.bedrooms,
    required this.propertyType,
    this.listIcon = Icons.apartment_rounded,
    this.description = '',
    this.status = 'published',
    this.media = const [],
  });

  final String id;
  final String title;
  final String city;
  final String district;
  final double priceEgp;
  final double areaM2;
  final int bedrooms;
  final String propertyType;
  final String description;
  final String status;
  final IconData listIcon;
  final List<PropertyMedia> media;

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    final type = json['propertyType'] as String? ?? 'apartment';
    final bedrooms = json['bedrooms'];
    final area = json['areaM2'];
    final price = json['priceEgp'];
    final media = json['media'];
    return PropertyListing(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'published',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      priceEgp:
          price is num ? price.toDouble() : double.parse(price.toString()),
      areaM2: area is num ? area.toDouble() : double.parse(area.toString()),
      bedrooms:
          bedrooms is num ? bedrooms.toInt() : int.parse(bedrooms.toString()),
      propertyType: type,
      listIcon:
          type == 'land' ? Icons.landscape_rounded : Icons.apartment_rounded,
      media: media is List
          ? media
              .whereType<Map>()
              .map((item) => PropertyMedia.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'city': city,
        'district': district,
        'propertyType': propertyType,
        'priceEgp': priceEgp,
        'areaM2': areaM2,
        'bedrooms': bedrooms,
        'status': status,
        'media': media.map((item) => item.toJson()).toList(growable: false),
      };

  String get locationLabel => '$city · $district';

  String priceLabel({bool isArabic = true}) {
    final whole = priceEgp.round();
    final s = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(isArabic ? '٬' : ',');
      }
      buf.write(_localizeDigit(s[i], isArabic));
    }
    return buf.toString();
  }

  String infoLabel({bool isArabic = true}) {
    final area = areaM2 == areaM2.roundToDouble()
        ? areaM2.round().toString()
        : areaM2.toStringAsFixed(0);
    if (isArabic) {
      return '${_localizeDigits(area, true)} م²  ·  ${_localizeDigits(bedrooms.toString(), true)} غرف';
    }
    return '$area m² · $bedrooms bedrooms';
  }

  static String _localizeDigit(String digit, bool isArabic) =>
      (isArabic
          ? const {
              '0': '٠',
              '1': '١',
              '2': '٢',
              '3': '٣',
              '4': '٤',
              '5': '٥',
              '6': '٦',
              '7': '٧',
              '8': '٨',
              '9': '٩',
            }
          : const {
              '٠': '0',
              '١': '1',
              '٢': '2',
              '٣': '3',
              '٤': '4',
              '٥': '5',
              '٦': '6',
              '٧': '7',
              '٨': '8',
              '٩': '9',
            })[digit] ??
      digit;

  static String _localizeDigits(String value, bool isArabic) =>
      value.split('').map((digit) => _localizeDigit(digit, isArabic)).join();
}
