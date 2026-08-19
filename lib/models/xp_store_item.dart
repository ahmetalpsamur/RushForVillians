import 'package:flutter/material.dart';

/// XP mağazasında satın alınabilecek bir öğe (kozmetik, boost, vb.).
class XpStoreItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final IconData icon;

  /// Tekrar tekrar satın alınabilir mi.
  ///
  /// Kozmetikler ve unvanlar bir kez alınır ([UserProfile.ownedItemIds]
  /// içinde durur); dondurma hakkı gibi tüketilen yükseltmeler ise stok
  /// dolana kadar tekrar alınabilir.
  final bool repeatable;

  const XpStoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    this.repeatable = false,
  });
}
