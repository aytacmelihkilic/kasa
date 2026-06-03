import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'product_list_screen.dart';
import 'add_product_screen.dart';
import 'settings_screen.dart';

/// instructions.md Screen 1: Dashboard (Ana Sayfa)
/// İki eşit büyüklükte buton + sağ üstte küçük ayarlar ikonu.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  constraints.maxWidth > constraints.maxHeight;
              return isLandscape
                  ? _buildLandscapeLayout(context)
                  : _buildPortraitLayout(context);
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                iconSize: 32,
                color: AppColors.secondary,
                tooltip: 'Ayarlar',
                onPressed: () => _openSettings(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Yatay Yerleşim (Tablet Landscape) ──────────────────────────────────────

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SearchButton(onTap: () => _openSearch(context))),
        const VerticalDivider(width: 2, thickness: 2, color: AppColors.divider),
        Expanded(child: _AddButton(onTap: () => _openAdd(context))),
      ],
    );
  }

  // ── Dikey Yerleşim (Tablet Portrait) ───────────────────────────────────────

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _SearchButton(onTap: () => _openSearch(context))),
        const Divider(height: 2, thickness: 2, color: AppColors.divider),
        Expanded(child: _AddButton(onTap: () => _openAdd(context))),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ProductListScreen()));
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arama Butonu
// ─────────────────────────────────────────────────────────────────────────────

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardTile(
      color: const Color(0xFFF1F8E9),
      icon: Icons.search_rounded,
      iconColor: const Color(0xFF33691E),
      label: 'ÜRÜN ARA\nFİYAT BAK',
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ekle Butonu
// ─────────────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardTile(
      color: AppColors.primary,
      icon: Icons.add_circle_outline_rounded,
      iconColor: Colors.white,
      label: 'YENİ ÜRÜN EKLE',
      labelColor: Colors.white,
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ortak Tile Bileşeni
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = labelColor ?? const Color(0xFF33691E);

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 96, color: iconColor),
              const SizedBox(height: 24),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.dashboardButton.copyWith(
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
