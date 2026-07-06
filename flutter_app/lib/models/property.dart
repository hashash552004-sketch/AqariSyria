import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final String type;
  final String operationType;
  final double price;
  final double area;
  final int rooms;
  final int bathrooms;
  final int floor;
  final String governorate;
  final String region;
  final String neighborhood;
  final String detailedAddress;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final bool hasElevator;
  final bool hasParking;
  final bool hasAC;
  final bool hasHeating;
  final bool hasGarden;
  final bool hasPool;
  final bool hasBalcony;
  final bool hasInternet;
  final bool hasGas;
  final bool isFurnished;
  final bool isActive;
  final bool isFeatured;
  final bool isUrgent;
  final bool isSold;
  final String status;
  final String deedType;
  final int viewsCount;
  final DateTime? createdAt;

  Property({
    this.id = '',
    this.title = '',
    this.description = '',
    this.type = '',
    this.operationType = '',
    this.price = 0,
    this.area = 0,
    this.rooms = 0,
    this.bathrooms = 0,
    this.floor = 0,
    this.governorate = '',
    this.region = '',
    this.neighborhood = '',
    this.detailedAddress = '',
    this.images = const [],
    this.ownerId = '',
    this.ownerName = '',
    this.ownerPhone = '',
    this.hasElevator = false,
    this.hasParking = false,
    this.hasAC = false,
    this.hasHeating = false,
    this.hasGarden = false,
    this.hasPool = false,
    this.hasBalcony = false,
    this.hasInternet = false,
    this.hasGas = false,
    this.isFurnished = false,
    this.isActive = true,
    this.isFeatured = false,
    this.isUrgent = false,
    this.isSold = false,
    this.status = 'approved',
    this.deedType = '',
    this.viewsCount = 0,
    this.createdAt,
  });

  factory Property.fromFirestore(Map<String, dynamic> data, String id) {
    return Property(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      operationType: data['operationType']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      area: (data['area'] as num?)?.toDouble() ?? 0,
      rooms: (data['rooms'] as num?)?.toInt() ?? 0,
      bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
      floor: (data['floor'] as num?)?.toInt() ?? 0,
      governorate: data['governorate']?.toString() ?? '',
      region: data['region']?.toString() ?? '',
      neighborhood: data['neighborhood']?.toString() ?? '',
      detailedAddress: data['detailedAddress']?.toString() ?? '',
      images:
          (data['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      ownerPhone: data['ownerPhone']?.toString() ?? '',
      hasElevator: data['hasElevator'] ?? false,
      hasParking: data['hasParking'] ?? false,
      hasAC: data['hasAC'] ?? false,
      hasHeating: data['hasHeating'] ?? false,
      hasGarden: data['hasGarden'] ?? false,
      hasPool: data['hasPool'] ?? false,
      hasBalcony: data['hasBalcony'] ?? false,
      hasInternet: data['hasInternet'] ?? false,
      hasGas: data['hasGas'] ?? false,
      isFurnished: data['isFurnished'] ?? false,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      isSold: data['isSold'] ?? false,
      status: data['status']?.toString() ?? 'pending',
      deedType: data['deedType']?.toString() ?? '',
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'operationType': operationType,
      'price': price,
      'area': area,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'floor': floor,
      'governorate': governorate,
      'region': region,
      'neighborhood': neighborhood,
      'detailedAddress': detailedAddress,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'hasElevator': hasElevator,
      'hasParking': hasParking,
      'hasAC': hasAC,
      'hasHeating': hasHeating,
      'hasGarden': hasGarden,
      'hasPool': hasPool,
      'hasBalcony': hasBalcony,
      'hasInternet': hasInternet,
      'hasGas': hasGas,
      'isFurnished': isFurnished,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isUrgent': isUrgent,
      'isSold': isSold,
      'status': status,
      'deedType': deedType,
      'viewsCount': viewsCount,
    };
  }
}
