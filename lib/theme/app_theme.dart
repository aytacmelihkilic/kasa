import 'package:flutter/material.dart';

/// Uygulamanın tüm renk, boyut ve bileşen stilleri bu dosyada tanımlanır.
/// Yaşlı dostu (senior-friendly) UI için yüksek kontrast, büyük font
/// ve geniş dokunma hedefleri esas alınmıştır.

// ─────────────────────────────────────────────────────────────────────────────
// Renk Sabitleri
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  /// Satış fiyatı için belirgin yeşil — müşteriye hemen gösterilecek.
  static const Color sellingPrice = Color(0xFF2E7D32); // green.shade800

  /// Onay/kaydetme aksiyonları için ana yeşil.
  static const Color primary = Color(0xFF388E3C); // green.shade700

  /// Açık arka plan — göz yormayan sıcak krem.
  static const Color background = Color(0xFFFAFAF7);

  /// Kart ve yüzey rengi.
  static const Color surface = Color(0xFFFFFFFF);

  /// İkincil eleman rengi — kurşuni altın tonu.
  static const Color secondary = Color(0xFF78909C); // blueGrey.shade400

  /// Alış fiyatı / maliyet gizleme katmanı.
  static const Color costHidden = Color(0xFFECEFF1); // blueGrey.shade50

  /// Hata / zorunlu alan uyarısı.
  static const Color error = Color(0xFFC62828); // red.shade800

  /// Başarı bildirimi arka planı.
  static const Color successOverlay = Color(0xDD1B5E20); // koyu yeşil yarı saydam

  /// Büyük kırmızı uyarı metni (boş alan validasyonu).
  static const Color validationError = Color(0xFFB71C1C);

  /// Bölücü çizgi.
  static const Color divider = Color(0xFFCFD8DC);
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      cardTheme: _cardTheme,
      chipTheme: _chipTheme,
      appBarTheme: _appBarTheme,
      snackBarTheme: _snackBarTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.5,
      ),
      // Tüm bileşenlerde büyük dokunma hedefi zorunlu kılınır.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.comfortable,
    );
  }

  // ── ColorScheme ────────────────────────────────────────────────────────────

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFC8E6C9),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFECEFF1),
    onSecondaryContainer: Color(0xFF37474F),
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: Color(0xFF212121),
    onSurfaceVariant: Color(0xFF546E7A),
    outline: Color(0xFF90A4AE),
  );

  // ── TextTheme ──────────────────────────────────────────────────────────────

  /// instructions.md: başlıklar 24–28sp, gövde/fiyat 18–22sp.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      // Ekran başlıkları (AppBar, büyük kartlar)
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF212121),
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF212121),
      ),
      // Sayfa/section başlıkları — min 24sp
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF212121),
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      // Ürün adı, etiket — min 20sp
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF212121),
        letterSpacing: 0.1,
      ),
      // Genel gövde metni — min 18sp
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF212121),
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF424242),
        height: 1.5,
      ),
      // Etiket, chip metni
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ── ElevatedButton ─────────────────────────────────────────────────────────

  /// Minimum yükseklik 64dp; instructions.md'de belirtilen kural.
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── OutlinedButton ─────────────────────────────────────────────────────────

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── InputDecoration ────────────────────────────────────────────────────────

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.secondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFFB0BEC5),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────

  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(6),
    );
  }

  // ── Chip (kategori seçimi) ─────────────────────────────────────────────────

  static ChipThemeData get _chipTheme {
    return ChipThemeData(
      backgroundColor: AppColors.costHidden,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.divider),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  static AppBarTheme get _appBarTheme {
    return const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 28),
    );
  }

  // ── SnackBar ───────────────────────────────────────────────────────────────

  /// Büyük, belirgin snackbar — instructions.md'de istenen güçlü geri bildirim.
  static SnackBarThemeData get _snackBarTheme {
    return SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
