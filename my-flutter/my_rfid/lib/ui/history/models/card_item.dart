import 'package:flutter/material.dart';

class CardItem {
  final String id;
  final String name;
  final String? subtitle;
  final IconData icon;
  final Color color;

  CardItem({
    required this.id,
    required this.name,
    this.subtitle,
    required this.icon,
    required this.color,
  });
}