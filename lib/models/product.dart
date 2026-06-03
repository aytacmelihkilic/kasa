import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'product.g.dart';

/// Hive typeId'leri uygulama genelinde benzersiz olmalıdır.
/// Bu model için typeId = 0 kullanılıyor.
@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  /// Maliyet / Alış Fiyatı — müşteriden gizli tutulur.
  @HiveField(3)
  double purchasePrice;

  /// Satış Fiyatı — büyük ve belirgin gösterilir.
  @HiveField(4)
  double sellingPrice;

  /// Ürün görseli sıkıştırılmış ham bayt olarak saklanır.
  /// Dosya yolu bağımlılığını ortadan kaldırır; yedekleme JSON'una
  /// Base64 string olarak dönüştürülür.
  @HiveField(5)
  Uint8List? imageBytes;

  @HiveField(6)
  DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    this.imageBytes,
    required this.createdAt,
  });

  /// Güncelleme için kopyalama yardımcısı.
  Product copyWith({
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    Uint8List? imageBytes,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      imageBytes: imageBytes ?? this.imageBytes,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, category: $category, '
      'sellingPrice: $sellingPrice)';
}
