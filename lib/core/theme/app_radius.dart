import 'package:flutter/material.dart';

class AppRadius {
  static const double xs = 6.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 999.0;
  static const double pill = 999.0;

  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullRadius =
      BorderRadius.all(Radius.circular(full));
  static const BorderRadius pillRadius =
      BorderRadius.all(Radius.circular(pill));
}
