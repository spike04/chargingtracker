import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double jumbo = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets screenLg = EdgeInsets.symmetric(horizontal: xxxl);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardLg = EdgeInsets.all(xxl);
  static const EdgeInsets list = EdgeInsets.fromLTRB(xl, sm, xl, 110);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(xxl, md, xxl, xxl);

  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);
  static const SizedBox gapXxxl = SizedBox(height: xxxl, width: xxxl);

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusJumbo = BorderRadius.all(Radius.circular(28));
}
