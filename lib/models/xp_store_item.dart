import 'package:flutter/material.dart';

/// XP mağazasında satın alınabilecek bir öğe (kozmetik, boost, vb.).
class XpStoreItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final IconData icon;

  const XpStoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
  });
}
