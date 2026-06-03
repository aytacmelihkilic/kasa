import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

/// Ürün listesi ızgarasında gösterilen kart.
///
/// - Büyük ürün görseli (varsa) veya placeholder ikon
/// - Ürün adı kalın 20sp
/// - Satış fiyatı büyük yeşil
/// - Alış fiyatı (maliyet) gizli; basılı tutunca gösterilir, bırakınca gizlenir
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _showCost = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Ürün Görseli ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _buildImage(),
            ),

            // ── Ürün Bilgileri ────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ürün adı
                    Text(
                      widget.product.name,
                      style: AppTextStyles.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Satış fiyatı — büyük yeşil
                    Text(
                      '${_formatPrice(widget.product.sellingPrice)} ₺',
                      style: AppTextStyles.sellingPrice,
                    ),

                    const SizedBox(height: 6),

                    // Alış fiyatı — gizli katman
                    _buildCostRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Görsel ──────────────────────────────────────────────────────────────────

  Widget _buildImage() {
    if (widget.product.imageBytes != null &&
        widget.product.imageBytes!.isNotEmpty) {
      return Image.memory(
        widget.product.imageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.costHidden,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  // ── Gizli Alış Fiyatı ────────────────────────────────────────────────────

  Widget _buildCostRow() {
    return GestureDetector(
      // Basılı tutunca fiyat görünür, bırakınca tekrar gizlenir
      onLongPressStart: (_) => setState(() => _showCost = true),
      onLongPressEnd: (_) => setState(() => _showCost = false),
      onLongPressCancel: () => setState(() => _showCost = false),
      // Tek tıkla da toggle yapılabilir (müşteri yokken hızlı kontrol)
      onTap: () => setState(() => _showCost = !_showCost),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _showCost
            ? _costVisible()
            : _costHidden(),
      ),
    );
  }

  Widget _costVisible() {
    return Row(
      key: const ValueKey('visible'),
      children: [
        const Icon(Icons.visibility_outlined,
            size: 16, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          'Maliyet: ${_formatPrice(widget.product.purchasePrice)} ₺',
          style: AppTextStyles.purchasePrice,
        ),
      ],
    );
  }

  Widget _costHidden() {
    return Row(
      key: const ValueKey('hidden'),
      children: [
        const Icon(Icons.visibility_off_outlined,
            size: 16, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          'Maliyeti gör',
          style: AppTextStyles.hiddenPriceHint,
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }
}
