import 'dart:convert';
import 'dart:typed_data';

import '../models/product.dart';
import '../constants/categories.dart' show kBackupSchemaVersion;

/// Yedek JSON dosyasının meta bilgileri (içe aktarmadan önce önizleme).
class BackupPreview {
  const BackupPreview({
    required this.version,
    required this.productCount,
    this.exportedAt,
    this.appName,
  });

  final int version;
  final int productCount;
  final DateTime? exportedAt;
  final String? appName;
}

/// Yedekleme/geri yükleme sırasında kullanıcıya gösterilecek hatalar.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phase 5: JSON serileştirme ve Base64 görsel kodlama/çözme.
///
/// Tüm yedekleme formatı bu sınıfta tanımlıdır; [DatabaseService] buraya delegasyon yapar.
class BackupService {
  BackupService._();

  static const String kAppName = 'Seramik Katalogu';
  static const String kMimeType = 'application/json';

  // ──────────────────────────────────────────────────────────────────────────
  // Base64 — Görsel bayt dönüşümü
  // ──────────────────────────────────────────────────────────────────────────

  /// [Uint8List] → Base64 string. Boş veya null ise null döner.
  static String? encodeImageBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return base64Encode(bytes);
  }

  /// Base64 string → [Uint8List]. Geçersiz veride [BackupException] fırlatır.
  static Uint8List? decodeImageBytes(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) return null;

    try {
      final decoded = base64Decode(value);
      if (decoded.isEmpty) return null;
      return Uint8List.fromList(decoded);
    } on FormatException {
      throw const BackupException(
        'Yedek dosyasındaki bir ürün görseli bozuk (geçersiz Base64).',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Dışa aktarma
  // ──────────────────────────────────────────────────────────────────────────

  /// Ürün listesini instructions.md formatında JSON string'e çevirir.
  static String buildExportJson(
    List<Product> products, {
    List<String> customCategories = const [],
  }) {
    final jsonList = products.map(_productToJson).toList();

    final payload = <String, dynamic>{
      'app': kAppName,
      'version': kBackupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'productCount': products.length,
      'products': jsonList,
      if (customCategories.isNotEmpty)
        'customCategories': customCategories,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Yedek dosyasındaki özel kategori listesi (yoksa boş).
  static List<String> parseCustomCategories(String jsonString) {
    try {
      final map = _parseRootMap(jsonString);
      final list = map['customCategories'];
      if (list is! List) return [];
      return list
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } on BackupException {
      return [];
    }
  }

  static Map<String, dynamic> _productToJson(Product p) {
    return <String, dynamic>{
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'purchasePrice': p.purchasePrice,
      'sellingPrice': p.sellingPrice,
      'imageBytes': encodeImageBytes(p.imageBytes),
      'createdAt': p.createdAt.toIso8601String(),
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Önizleme (içe aktarmadan önce)
  // ──────────────────────────────────────────────────────────────────────────

  /// Dosyayı okumadan önce kaç ürün yükleneceğini gösterir.
  static BackupPreview previewImport(String jsonString) {
    final map = _parseRootMap(jsonString);
    _validateSchema(map);

    final productList = map['products'];
    if (productList is! List) {
      throw const BackupException(
        'Yedek dosyasında "products" listesi bulunamadı.',
      );
    }

    final exportedAtRaw = map['exportedAt'] as String?;
    DateTime? exportedAt;
    if (exportedAtRaw != null) {
      try {
        exportedAt = DateTime.parse(exportedAtRaw);
      } catch (_) {
        exportedAt = null;
      }
    }

    return BackupPreview(
      version: (map['version'] as num?)?.toInt() ?? 1,
      productCount: productList.length,
      exportedAt: exportedAt,
      appName: map['app'] as String?,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // İçe aktarma — parse (Hive'a yazmadan önce tüm liste doğrulanır)
  // ──────────────────────────────────────────────────────────────────────────

  /// JSON'dan ürün listesi üretir. Hatalı kayıtlar atlanır; hiç geçerli ürün
  /// yoksa [BackupException] fırlatır. Böylece [clearAll] öncesi veri güvende kalır.
  static List<Product> parseProducts(String jsonString) {
    final map = _parseRootMap(jsonString);
    _validateSchema(map);

    final productList = map['products'];
    if (productList is! List) {
      throw const BackupException(
        'Yedek dosyasında "products" listesi bulunamadı.',
      );
    }

    if (productList.isEmpty) {
      throw const BackupException('Yedek dosyasında hiç ürün yok.');
    }

    final products = <Product>[];
    var skipped = 0;

    for (var i = 0; i < productList.length; i++) {
      final item = productList[i];
      try {
        products.add(_productFromJson(item, index: i));
      } on BackupException {
        skipped++;
      }
    }

    if (products.isEmpty) {
      throw BackupException(
        skipped > 0
            ? 'Yedek dosyasındaki $skipped ürünün tamamı geçersiz; geri yükleme iptal edildi.'
            : 'Yedek dosyasında geçerli ürün bulunamadı.',
      );
    }

    return products;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Yardımcılar
  // ──────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parseRootMap(String jsonString) {
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      throw const BackupException('Dosya boş.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      throw const BackupException(
        'Dosya geçerli bir JSON değil. Doğru yedek dosyasını seçtiğinizden emin olun.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('Geçersiz yedekleme dosyası formatı.');
    }

    return decoded;
  }

  static void _validateSchema(Map<String, dynamic> map) {
    final version = (map['version'] as num?)?.toInt();
    if (version != null && version > kBackupSchemaVersion) {
      throw BackupException(
        'Bu yedek dosyası daha yeni bir sürümle oluşturulmuş (v$version). '
        'Uygulamayı güncelleyin.',
      );
    }
  }

  static Product _productFromJson(dynamic item, {required int index}) {
    if (item is! Map<String, dynamic>) {
      throw BackupException('Ürün kaydı #$index geçersiz.');
    }

    final name = (item['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw const BackupException('Ürün adı boş olamaz.');
    }

    final purchase = (item['purchasePrice'] as num?)?.toDouble();
    final selling = (item['sellingPrice'] as num?)?.toDouble();
    if (purchase == null || selling == null) {
      throw BackupException('Ürün "$name" fiyat bilgisi eksik.');
    }

    final createdAtRaw = item['createdAt'] as String?;
    DateTime createdAt;
    try {
      createdAt = createdAtRaw != null
          ? DateTime.parse(createdAtRaw)
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    final category = (item['category'] as String?)?.trim() ?? 'Diğer';

    return Product(
      id: (item['id'] as String?)?.trim().isNotEmpty == true
          ? item['id'] as String
          : _fallbackId(),
      name: name,
      category: category.isEmpty ? 'Diğer' : category,
      purchasePrice: purchase,
      sellingPrice: selling,
      imageBytes: decodeImageBytes(item['imageBytes']),
      createdAt: createdAt,
    );
  }

  static String _fallbackId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
