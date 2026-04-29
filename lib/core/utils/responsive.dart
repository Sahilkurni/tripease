import 'package:flutter/material.dart';

class R {
  R._();
  static double h(BuildContext c, double pct) =>
      MediaQuery.of(c).size.height * pct;
  static double w(BuildContext c, double pct) =>
      MediaQuery.of(c).size.width * pct;
  static bool isMobile(BuildContext c) =>
      MediaQuery.of(c).size.width < 600;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext c) =>
      MediaQuery.of(c).size.width >= 1024;
  static double illustH(BuildContext c) {
    final sw = MediaQuery.of(c).size.width;
    if (sw >= 1024) return MediaQuery.of(c).size.height * 0.55;
    if (sw >= 600)  return MediaQuery.of(c).size.height * 0.45;
    return MediaQuery.of(c).size.height * 0.40;
  }
  static double fontSize(BuildContext c, double mobile,
      {double? tablet, double? desktop}) {
    if (isTablet(c)) return tablet ?? mobile * 1.2;
    return mobile;
  }
}
