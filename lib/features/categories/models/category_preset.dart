import 'package:flutter/material.dart';

class CategoryPreset {
  const CategoryPreset({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}
