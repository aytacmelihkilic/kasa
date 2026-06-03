import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/product_action_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/system_insets.dart';
import 'add_product_screen.dart';

/// instructions.md Screen 2: Ürün Arama Ekranı
/// - Büyük arama kutusu + sesli arama
/// - Kategori filtreleme chip'leri
/// - 2 sütun ürün ızgarası
/// - Her kart: görsel, ad, satış fiyatı, gizli alış fiyatı
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _db = DatabaseService.instance;
  final _searchController = TextEditingController();
  final _speech = SpeechToText();

  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Veri ────────────────────────────────────────────────────────────────────

  List<Product> get _filteredProducts {
    List<Product> list = _selectedCategory.isEmpty
        ? _db.getProducts()
        : _db.getProductsByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      list = list
          .where((p) => p.name.toLowerCase().contains(lower))
          .toList();
    }
    return list;
  }

  // ── Sesli Arama ─────────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showSnack('Mikrofon kullanılamıyor.');
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchQuery = result.recognizedWords;
          _searchController.text = result.recognizedWords;
        });
      },
      listenOptions: SpeechListenOptions(
        localeId: 'tr_TR',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Ara / Fiyat Bak'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // ── Arama Kutusu ─────────────────────────────────────────────
          _buildSearchBar(),

          // ── Kategori Filtreleri ──────────────────────────────────────
          _buildCategoryRow(),

          const Divider(height: 1),

          // ── Ürün Izgarası ────────────────────────────────────────────
          Expanded(child: _buildGrid()),
        ],
      ),

      floatingActionButton: Padding(
        padding: SystemInsets.fabPadding(context),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );
            setState(() {});
          },
          icon: const Icon(Icons.add, size: 28),
          label: const Text('Yeni Ürün', style: TextStyle(fontSize: 16)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // ── Arama Kutusu ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Ürün adı ile ara…',
          hintStyle: AppTextStyles.searchHint,
          prefixIcon: const Icon(Icons.search_rounded, size: 28),
          suffixIcon: GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isListening ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 28,
                color: _isListening ? Colors.white : AppColors.secondary,
              ),
            ),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ── Kategori Chips ────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    final categories = ['', ..._db.getAllCategories()];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final label = cat.isEmpty ? 'Tümü' : cat;
          final selected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF424242),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }

  // ── Ürün Izgarası ─────────────────────────────────────────────────────────

  Widget _buildGrid() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(
          product: products[i],
          onLongPress: () => _onProductLongPress(products[i]),
        ),
      ),
    );
  }

  // ── Boş Durum ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: AppColors.secondary.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory.isNotEmpty
                ? 'Eşleşen ürün bulunamadı.'
                : 'Henüz ürün eklenmedi.',
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Basılı tut: Düzenle / Sil ─────────────────────────────────────────────

  Future<void> _onProductLongPress(Product product) async {
    final action = await ProductActionSheet.show(context, product: product);
    if (!mounted || action == null) return;

    switch (action) {
      case ProductSheetAction.edit:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddProductScreen(product: product),
          ),
        );
        setState(() {});
      case ProductSheetAction.delete:
        await _showDeleteDialog(product);
    }
  }

  // ── Silme Onayı ───────────────────────────────────────────────────────────

  Future<void> _showDeleteDialog(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ürünü Sil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        content: Text(
          '"${product.name}" ürününü silmek istediğinize emin misiniz?',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(fontSize: 18, color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(
                    fontSize: 18,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _db.deleteProduct(product.id);
      setState(() {});
      _showSnack('Ürün silindi.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
