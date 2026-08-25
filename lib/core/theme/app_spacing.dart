import 'package:flutter/material.dart';

class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);
}
