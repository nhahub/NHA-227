import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  /// Path to a local asset (e.g. assets/icons/heart.png) or remote iconUrl
  final String iconPath;
  final Color backgroundColor;
  final Color iconColor;
  final int orderIndex;
  final bool active;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.backgroundColor,
    required this.iconColor,
    this.orderIndex = 0,
    this.active = true,
    this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    DateTime? created;
    if (map['createdAt'] != null) {
      final c = map['createdAt'];
      if (c is Timestamp) {
        created = c.toDate();
      } else if (c is String) created = DateTime.tryParse(c);
    }

    Color bg = _colorFromHex(map['backgroundColorHex'] as String? ?? '#FFFFFFFF');
    Color ic = _colorFromHex(map['iconColorHex'] as String? ?? '#FF000000');

    return Category(
      id: id,
      name: map['name'] ?? '',
      iconPath: map['iconPath'] ?? map['iconUrl'] ?? '',
      backgroundColor: bg,
      iconColor: ic,
      orderIndex: (map['orderIndex'] is int) ? map['orderIndex'] as int : 0,
      active: map['active'] is bool ? map['active'] as bool : true,
      createdAt: created,
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconPath': iconPath,
      'backgroundColorHex': _colorToHex(backgroundColor),
      'iconColorHex': _colorToHex(iconColor),
      'orderIndex': orderIndex,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    int value = int.parse(clean, radix: 16);
    if (clean.length == 6) value = 0xFF000000 | value; // add alpha
    return Color(value);
  }

  static String _colorToHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0')}';
}