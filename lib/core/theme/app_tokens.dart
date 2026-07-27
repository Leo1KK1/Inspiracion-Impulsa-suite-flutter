import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 18.0;
  static const pill = 999.0;
}

abstract final class AppBreakpoints {
  static const compact = 720.0;
  static const desktop = 1024.0;
  static const wide = 1440.0;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0D111827), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const dialog = <BoxShadow>[
    BoxShadow(color: Color(0x2E111827), blurRadius: 64, offset: Offset(0, 24)),
  ];
}
