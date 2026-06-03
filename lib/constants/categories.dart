/// Ürün giriş ekranında büyük buton/chip olarak gösterilecek
/// önceden tanımlı kategori listesi.
const List<String> kProductCategories = [
  'Tabaklar',
  'Vazolar',
  'Duvar Süsleri',
  'Saksılar',
  'Diğer',
];

/// Hive kutusunun adı — tek yerde tanımlı, her yerden import edilebilir.
const String kProductBoxName = 'products';

/// Ayarlar ve özel kategoriler için Hive kutusu.
const String kSettingsBoxName = 'settings';

/// Özel kategori listesinin Hive anahtarı.
const String kCustomCategoriesKey = 'custom_categories';

/// Yedekleme JSON dosyasının şema versiyonu.
/// İleride yapı değişirse migrasyon için kullanılır.
const int kBackupSchemaVersion = 1;
