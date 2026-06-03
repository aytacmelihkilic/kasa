import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

/// Ürün kartına basılı tutunca açılan büyük eylem menüsü.
class ProductActionSheet {
  ProductActionSheet._();

  static Future<ProductSheetAction?> show(
    BuildContext context, {
    required Product product,
  }) {
    return showModalBottomSheet<ProductSheetAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              _ActionTile(
                icon: Icons.edit_rounded,
                label: 'DÜZENLE',
                color: AppColors.primary,
                onTap: () => Navigator.pop(ctx, ProductSheetAction.edit),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'SİL',
                color: AppColors.error,
                onTap: () => Navigator.pop(ctx, ProductSheetAction.delete),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç',
                    style: TextStyle(fontSize: 18, color: AppColors.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ProductSheetAction { edit, delete }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
