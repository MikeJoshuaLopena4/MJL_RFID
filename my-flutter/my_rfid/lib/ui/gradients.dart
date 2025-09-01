import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient blueCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0ea5e9), // sky-500
      Color(0xFF22d3ee), // cyan-400
      Color(0xFF60a5fa), // indigo/blue tint
    ],
  );
}
