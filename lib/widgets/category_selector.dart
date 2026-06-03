import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Kategori chip seçimi + "Yeni Kategori Ekle" butonu.
class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.onCategoriesChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onCategoriesChanged;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  final _db = DatabaseService.instance;

  List<String> get _categories => _db.getAllCategories();

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text(
              'Yeni Kategori',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Örn: Kupalar',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal',
                    style:
                        TextStyle(fontSize: 18, color: AppColors.secondary)),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () async {
                  final trimmed = controller.text.trim();
                  if (trimmed.isEmpty) {
                    setDialogState(
                        () => errorText = 'Kategori adı boş olamaz!');
                    return;
                  }
                  final ok = await _db.addCustomCategory(trimmed);
                  if (!ok) {
                    setDialogState(() => errorText = 'Bu kategori zaten var.');
                    return;
                  }
                  widget.onCategorySelected(trimmed);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Ekle', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    if (added == true && mounted) {
      widget.onCategoriesChanged?.call();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._categories.map((cat) {
          final selected = widget.selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => widget.onCategorySelected(cat),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.costHidden,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF424242),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
          label: const Text(
            'Yeni Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          backgroundColor: const Color(0xFFE8F5E9),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onPressed: _showAddCategoryDialog,
        ),
      ],
    );
  }
}
