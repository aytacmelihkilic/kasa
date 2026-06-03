import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_selector.dart';
import '../widgets/success_overlay.dart';
import '../widgets/system_insets.dart';

/// instructions.md Screen 3: Ürün Ekleme Ekranı
/// - Büyük fotoğraf alanı → kamera ile çekim
/// - Ürün adı metin alanı
/// - Kategori chip seçimi (dropdown yok!)
/// - Alış ve satış fiyatı alanları
/// - Tam genişlikte yeşil "ÜRÜNÜ KAYDET" butonu
/// - Hata durumunda büyük kırmızı uyarı metni (snackbar değil, direkt ekranda)
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.product});

  /// Dolu ise düzenleme modu.
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _db = DatabaseService.instance;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  Uint8List? _imageBytes;
  String _selectedCategory = '';
  bool _isSaving = false;

  // Doğrulama hata mesajları — büyük kırmızı metin olarak ekranda gösterilir
  String? _nameError;
  String? _categoryError;
  String? _purchaseError;
  String? _sellingError;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameController.text = p.name;
      _purchasePriceController.text = _formatPriceInput(p.purchasePrice);
      _sellingPriceController.text = _formatPriceInput(p.sellingPrice);
      _selectedCategory = p.category;
      _imageBytes = p.imageBytes;
    }
  }

  String _formatPriceInput(double price) {
    if (price == price.truncateToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // ── Kamera ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    // Web'de galeri/dosya seçimi; mobilde kamera
    final picked = await _picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (kIsWeb) {
      // Web'de doğrudan baytları oku (sıkıştırma native gerektirir)
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
      return;
    }

    // Mobil: sıkıştır
    final compressed = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (compressed != null && mounted) {
      setState(() => _imageBytes = compressed);
    }
  }

  // ── Kaydetme ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);
    try {
      final purchase = double.parse(
          _purchasePriceController.text.replaceAll(',', '.'));
      final selling =
          double.parse(_sellingPriceController.text.replaceAll(',', '.'));

      if (widget.isEditing) {
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          purchasePrice: purchase,
          sellingPrice: selling,
          imageBytes: _imageBytes,
        );
        await _db.updateProduct(updated);
      } else {
        await _db.addProduct(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          purchasePrice: purchase,
          sellingPrice: selling,
          imageBytes: _imageBytes,
        );
      }

      if (mounted) {
        SuccessOverlay.show(
          context,
          message: widget.isEditing
              ? 'Ürün Güncellendi!'
              : 'Ürün Başarıyla Kaydedildi!',
          onDismissed: () => Navigator.pop(context, true),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _categoryError = null;
      _purchaseError = null;
      _sellingError = null;
    });

    if (_nameController.text.trim().isEmpty) {
      _nameError = 'Ürün adı boş bırakılamaz!';
      valid = false;
    }
    if (_selectedCategory.isEmpty) {
      _categoryError = 'Lütfen bir kategori seçin!';
      valid = false;
    }
    final purchaseText =
        _purchasePriceController.text.trim().replaceAll(',', '.');
    if (purchaseText.isEmpty || double.tryParse(purchaseText) == null) {
      _purchaseError = 'Geçerli bir alış fiyatı girin!';
      valid = false;
    }
    final sellingText =
        _sellingPriceController.text.trim().replaceAll(',', '.');
    if (sellingText.isEmpty || double.tryParse(sellingText) == null) {
      _sellingError = 'Geçerli bir satış fiyatı girin!';
      valid = false;
    }

    if (!valid) setState(() {});
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: SystemInsets.scrollPadding(context, extra: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Fotoğraf ─────────────────────────────────────────────
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // ── Ürün Adı ─────────────────────────────────────────────
              _buildLabel('Ürün Adı'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Örn: Çiçekli Tabak',
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              _buildError(_nameError),
              const SizedBox(height: 20),

              // ── Kategori ─────────────────────────────────────────────
              _buildLabel('Kategori'),
              const SizedBox(height: 10),
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() {
                  _selectedCategory = cat;
                  _categoryError = null;
                }),
                onCategoriesChanged: () => setState(() {}),
              ),
              _buildError(_categoryError),
              const SizedBox(height: 20),

              // ── Fiyatlar ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Alış Fiyatı (Maliyet)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _purchasePriceController,
                          style: const TextStyle(fontSize: 18),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: '₺',
                          ),
                          onChanged: (_) {
                            if (_purchaseError != null) {
                              setState(() => _purchaseError = null);
                            }
                          },
                        ),
                        _buildError(_purchaseError),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Satış Fiyatı'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _sellingPriceController,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.sellingPrice,
                            fontWeight: FontWeight.w700,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: '₺',
                          ),
                          onChanged: (_) {
                            if (_sellingError != null) {
                              setState(() => _sellingError = null);
                            }
                          },
                        ),
                        _buildError(_sellingError),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Kaydet Butonu ─────────────────────────────────────────
              SizedBox(
                height: 68,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Icon(Icons.save_rounded, size: 28),
                  label: Text(
                    _isSaving
                        ? 'Kaydediliyor…'
                        : (widget.isEditing ? 'DEĞİŞİKLİKLERİ KAYDET' : 'ÜRÜNÜ KAYDET'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fotoğraf Bölümü ────────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.costHidden,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageBytes != null
                ? AppColors.primary
                : AppColors.divider,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Değiştir',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      size: 64, color: AppColors.secondary),
                  const SizedBox(height: 12),
                  Text(
                    widget.isEditing ? 'FOTOĞRAF DEĞİŞTİR' : 'FOTOĞRAF ÇEK',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb ? 'Dokunarak dosya seç' : 'Dokunarak kamerayı aç',
                    style: AppTextStyles.hiddenPriceHint,
                  ),
                ],
              ),
      ),
    );
  }

  // ── Yardımcı Widget'lar ────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.fieldLabel);
  }

  /// instructions.md: "massive red warning text elements directly on screen"
  Widget _buildError(String? error) {
    if (error == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.validationError),
          const SizedBox(width: 6),
          Flexible(
            child: Text(error, style: AppTextStyles.validationError),
          ),
        ],
      ),
    );
  }
}
