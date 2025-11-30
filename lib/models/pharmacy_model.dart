import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String name;
  final String location;
  final String phone;
  final String whatsapp;
  final String imageUrl;
  final List<String> imageGallery;
  final double? latitude;
  final double? longitude;
  final List<String> services;
  final bool isVerified;
  final DateTime? createdAt;

  Pharmacy({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.whatsapp,
    required this.imageUrl,
    this.imageGallery = const [],
    this.latitude,
    this.longitude,
    this.services = const [],
    this.isVerified = false,
    this.createdAt,
  });

  factory Pharmacy.fromMap(Map<String, dynamic> map, String id) {
    // 1. Handle Coordinates (Firestore GeoPoint vs JSON Map)
    double? lat;
    double? lng;
    
    if (map['coordinates'] is GeoPoint) {
      // Data coming from Firestore
      GeoPoint geo = map['coordinates'];
      lat = geo.latitude;
      lng = geo.longitude;
    } else if (map['coordinates'] is Map) {
      // Data coming from raw JSON file
      lat = (map['coordinates']['latitude'] ?? 0.0).toDouble();
      lng = (map['coordinates']['longitude'] ?? 0.0).toDouble();
    }

    // 2. Handle Date
    DateTime? created;
    if (map['createdAt'] != null) {
      final c = map['createdAt'];
      if (c is Timestamp) {
        created = c.toDate();
      } else if (c is String) created = DateTime.tryParse(c);
    }

    return Pharmacy(
      id: id,
      name: map['name'] ?? '',
      // Map 'locationText' from JSON to 'location' in App
      location: map['locationText'] ?? map['location'] ?? '', 
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageGallery: map['imageGallery'] != null 
          ? List<String>.from(map['imageGallery']) 
          : [],
      latitude: lat,
      longitude: lng,
      services: map['services'] != null 
          ? List<String>.from(map['services']) 
          : [],
      isVerified: map['isVerified'] ?? false,
      createdAt: created,
    );
  }

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Pharmacy.fromMap(data, doc.id);
  }
}