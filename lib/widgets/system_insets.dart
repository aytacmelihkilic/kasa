import 'package:flutter/material.dart';

/// Cihazın çentik, durum çubuğu ve alt navigasyon alanı boşlukları.
class SystemInsets {
  SystemInsets._();

  /// Alt navigasyon / jest çubuğu yüksekliği.
  static double bottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  static double top(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).top;

  /// Kaydırılabilir sayfalar için alt boşluk (navigasyon + ek pay).
  static EdgeInsets scrollPadding(BuildContext context, {double extra = 24}) {
    return EdgeInsets.fromLTRB(20, 16, 20, extra + bottom(context));
  }

  /// FAB için alt boşluk.
  static EdgeInsets fabPadding(BuildContext context) {
    return EdgeInsets.only(bottom: bottom(context));
  }
}
