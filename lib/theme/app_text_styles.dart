import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Sık kullanılan text style'ları tek yerden yönetmek için merkezi sabitler.
/// Widget'larda `Theme.of(context).textTheme` yerine bu sabitler tercih edilir.
class AppTextStyles {
  AppTextStyles._();

  /// Ürün satış fiyatı — büyük, kalın, yeşil.
  /// Örnek: "150 TL"
  static const TextStyle sellingPrice = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.sellingPrice,
    letterSpacing: 0.5,
  );

  /// Alış fiyatı (görünür hali) — orta boy, gri.
  static const TextStyle purchasePrice = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
  );

  /// Ürün adı — kart üzerinde kalın.
  static const TextStyle productName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF212121),
  );

  /// Kategori etiketi.
  static const TextStyle category = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
    letterSpacing: 0.3,
  );

  /// Dashboard büyük buton metni.
  static const TextStyle dashboardButton = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  /// Doğrulama hatası — büyük, kırmızı, doğrudan widget üzerinde gösterilir.
  /// instructions.md: "Show explicit, massive red warning text elements directly on screen"
  static const TextStyle validationError = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.validationError,
  );

  /// Başarı bildirimi büyük overlay metni.
  static const TextStyle successMessage = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Arama kutusu hint metni.
  static const TextStyle searchHint = TextStyle(
    fontSize: 18,
    color: Color(0xFFB0BEC5),
    fontWeight: FontWeight.w400,
  );

  /// Form alanı etiketi.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
  );

  /// Gizli alış fiyatı placeholder — "Görmek için basılı tut".
  static const TextStyle hiddenPriceHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
    letterSpacing: 0.2,
  );
}
