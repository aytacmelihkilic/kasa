# Project Instructions: Annemin Seramik Kataloğu (Mom's Ceramic Catalog)

## 1. Project Overview & Target Audience
* **Target User:** A 50+ years old mother who manages a small ceramic store. She struggles to memorize prices and needs an incredibly simple, intuitive, and high-contrast digital price book.
* **Core Philosophy:** Minimalist UI, giant buttons, huge font sizes, large tap targets, zero visual clutter, and zero friction.
* **Tech Stack:** Flutter (Dart) for Android Tablet.
* **Database Strategy:** Local-first architecture using **Hive** or **Isar Database**. Images are stored directly in the database as binary bytes (`Uint8List`) to eliminate file-path management issues.
* **Backup Strategy:** Offline backup (Method A). Data is exported as a unified JSON file containing all metadata and Base64-encoded images, which can be shared or imported on another device.

---

## 2. UI/UX & Design Guidelines (Senior-Friendly)
* **Font Sizes:** Heading titles must be at least `24sp` to `28sp`. Body/price text must be at least `18sp` to `22sp`.
* **Colors:** High contrast. Emerald Green for final selling prices (`Colors.green.shade700`), Slate Grey or Muted Gold for secondary elements. White or very soft cream background.
* **Buttons:** Minimum height of `64dp`. Wrap all interactive buttons with generous padding (`EdgeInsets.all(12)`) to prevent accidental double-taps or misclicks.
* **Feedback:** Every successful action (saving a product, importing a backup) must show a large, full-screen overlay or massive Snackbar with a giant green checkmark and clear text (e.g., "Ürün Başarıyla Kaydedildi!").

---

## 3. Data Architecture (Hive Schema / Isar Collection)

### Product Model (`Product`)
* `id`: String (UUID)
* `name`: String
* `category`: String
* `purchasePrice`: Double (Maliyet - Hidden by default)
* `sellingPrice`: Double (Satış Fiyatı - Large & Prominent)
* `imageBytes`: Uint8List (The raw compressed image data)
* `createdAt`: DateTime

### Pre-defined Categories
To make entry easy, categories should be predefined buttons:
* `Tabaklar` (Plates)
* `Vazolar` (Vases)
* `Duvar Süsleri` (Wall Decors)
* `Saksılar` (Pots)
* `Diğer` (Others)

---

## 4. Screen Specifications & Flows

### Screen 1: Dashboard (Ana Sayfa)
* Split the screen into exactly **TWO massive, equal-sized buttons** placed vertically or horizontally (optimized for tablet landscape/portrait):
  1. **"ÜRÜN ARA / FİYAT BAK"** (Icon: Giant Search/Magnifying Glass)
  2. **"YENİ ÜRÜN EKLE"** (Icon: Giant Plus Sign)
* In the top-right corner, place a small, low-profile gear icon (`Icons.settings`) for the developer/son to access Backup/Restore options.

### Screen 2: Product List & Search (Ürün Arama Ekranı)
* **Search Bar:** Large text field with a prominent microphone icon for voice-to-text search (`speech_to_text` package integration).
* **Category Tabs:** Large horizontal row of scrollable pills/chips. Tapping a category immediately filters the grid.
* **Product Display:** A 2-column grid layout. Each card features:
  * A large aspect-ratio image of the ceramic product.
  * The product name in bold (`20sp`).
  * The **Satış Fiyatı** displayed in giant bold green text (e.g., "**150 TL**").
  * The **Alış Fiyatı** (Cost) hidden behind a privacy layer. Provide an eye icon (`Icons.visibility_off`). When **long-pressed or tapped**, it reveals the cost price; when released or tapped again, it hides it immediately so customers don't see it.

### Screen 3: Add Product (Ürün Ekleme Ekranı)
* A step-by-step simple wizard flow or a single clean form with massive inputs:
  1. **Photo Section:** A massive placeholder box saying "FOTOĞRAF ÇEK". Tapping it opens the native camera using `image_picker`. Once shot, it compresses the image and displays a large preview.
  2. **Product Name:** A text input field with large font.
  3. **Category Selection:** A horizontal wrap of giant filter chips. The user taps one to select. No dropdowns!
  4. **Prices:** Two separate numeric-only text fields (activates `TextInputType.number`). 
     * Field A: "Alış Fiyatı (Maliyet)"
     * Field B: "Satış Fiyatı"
  5. **Save Button:** A full-width giant green button at the bottom: **"ÜRÜNÜ KAYDET"**.

### Screen 4: Settings & Backup (Yedekleme ve Ayarlar)
* A password or simple confirmation-protected screen (so Mom doesn't accidentally trigger it).
* Contains two main actions:
  1. **"Tüm Verileri Yedekle (Dışa Aktar)":** Converts all Hive entries (including `imageBytes` mapped to Base64 strings) into a single structural JSON layout. Saves it to the device storage or triggers the native Share sheet so it can be sent via WhatsApp/Email.
  2. **"Yedekten Geri Yükle (İçe Aktar)":** Opens a file picker, reads the custom JSON file, decodes the Base64 strings back to `Uint8List`, and overwrites/repopulates the Hive box.

---

## 5. Step-by-Step Implementation Strategy for Cursor

Please build the application systematically following these phases:

### Phase 1: Setup & Dependencies
* Initialize a standard Flutter project optimized for Android tablets.
* Configure `pubspec.yaml` with:
  * `hive` and `hive_flutter` (or `isar` / `isar_flutter_libs`)
  * `image_picker` (for camera access)
  * `flutter_image_compress` (to keep image byte sizes light before saving)
  * `speech_to_text` (for voice product lookup)
  * `share_plus` and `file_picker` (for JSON export/import backup flows)

### Phase 2: Data Models & TypeAdapters
* Create the `Product` data class.
* Generate Hive TypeAdapters or Isar schemas.
* Build a `DatabaseService` wrapper handling basic CRUD operations: `getProducts()`, `addProduct()`, `deleteProduct()`, `exportToBackupJson()`, and `importFromBackupJson()`.

### Phase 3: Senior-Friendly UI Theme Setup
* Define a global `ThemeData` with forced high-density touch targets, custom massive font themes, and high-contrast color styles.

### Phase 4: View Layouts Implementation
* Implement `DashboardScreen`, `ProductListScreen`, `AddProductScreen`, and `SettingsScreen` exactly as described in the specifications.
* Pay special attention to the Long-Press behavior on the Purchase Price to toggle visibility.

### Phase 5: Backup & JSON Parsing Mechanics
* Write robust JSON serialization logic. Ensure `Uint8List` image bytes are encoded safely using `base64Encode()` during export, and correctly reconstructed using `base64Decode()` during import.

---

## 6. Development Directives for Cursor AI
* **Code Execution:** Ensure all code is highly modular, clean, and self-documented.
* **State Management:** Keep it lightweight. Use `ValueNotifier` or a simple stateful widget wrapper unless explicitly instructed otherwise.
* **Validation:** Prevent saving empty products or invalid numbers. Show explicit, massive red warning text elements directly on screen instead of tiny standard validator strings.
