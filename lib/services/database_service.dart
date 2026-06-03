import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/categories.dart';
import '../models/product.dart';
import 'backup_service.dart';

/// Uygulamanın tüm veri erişim işlemlerini yöneten servis katmanı.
///
/// Sorumlulukları:
/// - Hive başlatma ve TypeAdapter kaydı
/// - Ürünler için CRUD operasyonları
/// - JSON tabanlı yedekleme dışa/içe aktarma
///   (görseller Base64 olarak kodlanır/çözülür)
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _uuid = Uuid();

  Box<Product> get _box => Hive.box<Product>(kProductBoxName);
  Box get _settingsBox => Hive.box(kSettingsBoxName);

  // ──────────────────────────────────────────────────────────────────────────
  // Başlatma
  // ──────────────────────────────────────────────────────────────────────────

  /// Uygulamanın `main()` fonksiyonunda, `runApp()` çağrısından önce
  /// çağrılmalıdır.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    await Hive.openBox<Product>(kProductBoxName);
    await Hive.openBox(kSettingsBoxName);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Kategoriler
  // ──────────────────────────────────────────────────────────────────────────

  /// Kullanıcının eklediği özel kategoriler.
  List<String> getCustomCategories() {
    final raw = _settingsBox.get(kCustomCategoriesKey);
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    }
    return [];
  }

  Future<void> _saveCustomCategories(List<String> categories) async {
    await _settingsBox.put(kCustomCategoriesKey, categories);
  }

  /// Önceden tanımlı + özel + ürünlerde kullanılan tüm kategoriler.
  List<String> getAllCategories() {
    final seen = <String>{};
    final result = <String>[];

    void add(String name) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) return;
      seen.add(trimmed);
      result.add(trimmed);
    }

    for (final c in kProductCategories) {
      add(c);
    }
    for (final c in getCustomCategories()) {
      add(c);
    }
    for (final p in _box.values) {
      add(p.category);
    }

    return result;
  }

  /// Yeni özel kategori ekler. Zaten varsa false döner.
  Future<bool> addCustomCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final exists = getAllCategories()
        .any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;

    final list = getCustomCategories()..add(trimmed);
    await _saveCustomCategories(list);
    return true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CRUD
  // ──────────────────────────────────────────────────────────────────────────

  /// Kayıtlı tüm ürünleri en yeni önce sıralı şekilde döner.
  List<Product> getProducts() {
    final products = _box.values.toList();
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  /// Kategoriye göre filtrelenmiş ürünleri döner.
  /// [category] boş string veya null ise tüm ürünler döner.
  List<Product> getProductsByCategory(String? category) {
    if (category == null || category.isEmpty) return getProducts();
    return getProducts()
        .where((p) => p.category == category)
        .toList();
  }

  /// İsme göre arama (büyük/küçük harf duyarsız).
  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return getProducts();
    final lower = query.toLowerCase();
    return getProducts()
        .where((p) => p.name.toLowerCase().contains(lower))
        .toList();
  }

  /// Yeni ürün oluşturur ve Hive kutusuna kaydeder.
  /// UUID otomatik atanır.
  Future<void> addProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    Uint8List? imageBytes,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name.trim(),
      category: category,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
    );
    await _box.put(product.id, product);
  }

  /// Mevcut ürünün alanlarını günceller.
  Future<void> updateProduct(Product product) async {
    await _box.put(product.id, product);
  }

  /// Ürünü Hive kutusundan kalıcı olarak siler.
  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
  }

  /// Tüm ürünleri siler. Geri yükleme öncesinde çağrılır.
  Future<void> clearAll() async {
    await _box.clear();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Yedekleme — Dışa Aktarma (Export)
  // ──────────────────────────────────────────────────────────────────────────

  /// Tüm ürünleri, görseller dahil, tek bir JSON string'e dönüştürür.
  /// Görseller [BackupService.encodeImageBytes] ile Base64'e kodlanır.
  String exportToBackupJson() {
    return BackupService.buildExportJson(
      getProducts(),
      customCategories: getCustomCategories(),
    );
  }

  /// İçe aktarmadan önce yedek dosyası hakkında özet bilgi döner.
  BackupPreview previewBackupImport(String jsonString) {
    return BackupService.previewImport(jsonString);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Yedekleme — İçe Aktarma (Import)
  // ──────────────────────────────────────────────────────────────────────────

  /// JSON yedek dosyasını okuyup tüm ürünleri geri yükler.
  ///
  /// Önce tüm kayıtlar parse edilir; başarılı olursa mevcut veri silinir
  /// ve yedek yazılır (kısmi bozuk dosyada veri kaybı olmaz).
  ///
  /// Yüklenen ürün sayısını döner. Hata durumunda [BackupException].
  Future<int> importFromBackupJson(String jsonString) async {
    final customCategories = BackupService.parseCustomCategories(jsonString);
    if (customCategories.isNotEmpty) {
      await _saveCustomCategories(customCategories);
    }

    final products = BackupService.parseProducts(jsonString);

    await clearAll();
    for (final product in products) {
      await _box.put(product.id, product);
    }

    return products.length;
  }
}
