import 'package:flutter/material.dart';

import '../models/partnership_project.dart';
import '../models/property_listing.dart';

/// Placeholder feed until the API reads from PostgreSQL (see backend/schema.sql).
class MockFeed {
  MockFeed._();

  static const publishedProperties = [
    PropertyListing(
      id: '00000000-0000-4000-8000-000000000001',
      title: 'شقة عصرية بإطلالة مفتوحة',
      city: 'بنها',
      district: 'منطقة الفلل',
      priceEgp: 1850000,
      areaM2: 145,
      bedrooms: 3,
      propertyType: 'apartment',
      listIcon: Icons.apartment_rounded,
    ),
    PropertyListing(
      id: '00000000-0000-4000-8000-000000000002',
      title: 'أرض سكنية على شارع رئيسي',
      city: 'بنها',
      district: 'كفر الجزار',
      priceEgp: 4200000,
      areaM2: 300,
      bedrooms: 0,
      propertyType: 'land',
      listIcon: Icons.landscape_rounded,
    ),
    PropertyListing(
      id: '00000000-0000-4000-8000-000000000003',
      title: 'شقة جاهزة للسكن',
      city: 'بنها',
      district: 'المنشية',
      priceEgp: 1250000,
      areaM2: 110,
      bedrooms: 2,
      propertyType: 'apartment',
      listIcon: Icons.home_work_rounded,
    ),
  ];

  static const openProjects = [
    PartnershipProject(
      id: '00000000-0000-4000-8000-000000000101',
      title: 'عمارة سكنية — بنها الجديدة',
      description: 'شراء أرض وبناء ١٢ وحدة سكنية',
      city: 'بنها',
      district: 'بنها الجديدة',
      targetMembers: 24,
      expectedDurationMonths: 18,
      fundingProgress: 0.68,
      currentMemberCount: 24,
    ),
    PartnershipProject(
      id: '00000000-0000-4000-8000-000000000102',
      title: 'مشروع وحدات عائلية',
      description: 'مساهمة جماعية في أرض وبناء',
      city: 'بنها',
      district: '—',
      targetMembers: 20,
      expectedDurationMonths: 22,
      fundingProgress: 0.42,
      currentMemberCount: 11,
    ),
  ];

  static const publishedPropertyCountLabel = '١٢٤';
  static const cityCountLabel = '١٢';
  static const activeProjectCountLabel = '٨';
  static const partnerCountLabel = '١٨٦';
}
