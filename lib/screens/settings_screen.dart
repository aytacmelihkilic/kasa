import 'package:flutter/material.dart';

import '../services/backup_file_helper.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/success_overlay.dart';
import '../widgets/system_insets.dart';

/// instructions.md Screen 4: Yedekleme ve Ayarlar
/// - Basit PIN koruması (annesi yanlışlıkla tetiklemesin diye)
/// - Yedekleme: tüm veriyi JSON olarak dışa aktar + paylaş
/// - Geri yükleme: JSON dosyasını içe aktar
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _pin = '1234'; // Basit sabit PIN; production'da güvenli hale getirin
  final _db = DatabaseService.instance;

  bool _isUnlocked = false;
  bool _isWorking = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Yedekleme'),
        leading: const BackButton(),
      ),
      body: _isUnlocked ? _buildSettings() : _buildPinLock(),
    );
  }

  // ── PIN Ekranı ────────────────────────────────────────────────────────────

  Widget _buildPinLock() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 72, color: AppColors.secondary),
              const SizedBox(height: 24),
              const Text(
                'Ayarlara Erişim',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen şifreyi girin.',
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
              const SizedBox(height: 32),
              _PinInput(
                onSubmit: (pin) {
                  if (pin == _pin) {
                    setState(() => _isUnlocked = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hatalı şifre!',
                            style: TextStyle(fontSize: 18)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ayarlar İçeriği ────────────────────────────────────────────────────────

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: SystemInsets.scrollPadding(context, extra: 24).copyWith(
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Durum mesajı
          if (_statusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Dışa Aktarma ────────────────────────────────────────────
          _SectionCard(
            icon: Icons.cloud_upload_outlined,
            iconColor: const Color(0xFF1565C0),
            title: 'Tüm Verileri Yedekle',
            subtitle: 'Ürünler ve görseller JSON dosyası olarak dışa aktarılır.\n'
                'WhatsApp, e-posta veya buluta paylaşabilirsiniz.',
            buttonLabel: 'YEDEKLE (DIŞA AKTAR)',
            buttonColor: const Color(0xFF1565C0),
            isLoading: _isWorking,
            onTap: _export,
          ),

          const SizedBox(height: 20),

          // ── İçe Aktarma ─────────────────────────────────────────────
          _SectionCard(
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Yedekten Geri Yükle',
            subtitle: 'Daha önce yedeklediğiniz JSON dosyasını seçin.\n'
                'Mevcut tüm veriler silinip dosyadakiler yüklenir!',
            buttonLabel: 'GERİ YÜKLE (İÇE AKTAR)',
            buttonColor: const Color(0xFF6A1B9A),
            isLoading: _isWorking,
            onTap: _import,
          ),

          const SizedBox(height: 32),

          // ── Ürün Sayısı ─────────────────────────────────────────────
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final count = _db.getProducts().length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.costHidden,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 28, color: AppColors.secondary),
          const SizedBox(width: 12),
          Text(
            'Kayıtlı ürün sayısı: $count',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  // ── Dışa Aktarma ─────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() {
      _isWorking = true;
      _statusMessage = '';
    });
    try {
      final count = _db.getProducts().length;
      if (count == 0) {
        setState(() => _statusMessage = 'Yedeklenecek ürün yok. Önce ürün ekleyin.');
        return;
      }

      final json = _db.exportToBackupJson();
      await BackupFileHelper.shareBackupJson(json);

      if (mounted) {
        SuccessOverlay.show(
          context,
          message: 'Yedekleme Tamamlandı!\n$count ürün dışa aktarıldı.',
        );
      }
    } on BackupException catch (e) {
      if (mounted) setState(() => _statusMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Yedekleme hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  // ── İçe Aktarma ──────────────────────────────────────────────────────────

  Future<void> _import() async {
    setState(() => _statusMessage = '');

    String? json;
    try {
      json = await BackupFileHelper.pickAndReadJson();
    } on BackupException catch (e) {
      setState(() => _statusMessage = e.message);
      return;
    } catch (e) {
      setState(() => _statusMessage = 'Dosya seçilemedi: $e');
      return;
    }

    if (json == null) return;

    BackupPreview preview;
    try {
      preview = _db.previewBackupImport(json);
    } on BackupException catch (e) {
      setState(() => _statusMessage = e.message);
      return;
    }

    if (!mounted) return;
    final confirmed = await _showImportWarning(preview);
    if (!confirmed) return;

    setState(() {
      _isWorking = true;
      _statusMessage = '';
    });

    try {
      final count = await _db.importFromBackupJson(json);

      if (mounted) {
        SuccessOverlay.show(
          context,
          message: 'Geri Yükleme Tamamlandı!\n$count ürün yüklendi.',
        );
        setState(() {});
      }
    } on BackupException catch (e) {
      if (mounted) setState(() => _statusMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Geri yükleme hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<bool> _showImportWarning(BackupPreview preview) async {
    final dateText = preview.exportedAt != null
        ? '${preview.exportedAt!.day}.${preview.exportedAt!.month}.${preview.exportedAt!.year}'
        : 'bilinmiyor';

    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Dikkat!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
            content: Text(
              'Bu yedek dosyasında ${preview.productCount} ürün var.\n'
              'Yedek tarihi: $dateText\n\n'
              'Geri yükleme mevcut tüm ürünleri silip yerine bunları yükler.\n\n'
              'Devam etmek istediğinizden emin misiniz?',
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal',
                    style:
                        TextStyle(fontSize: 18, color: AppColors.secondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Evet, Geri Yükle',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN Giriş Bileşeni
// ─────────────────────────────────────────────────────────────────────────────

class _PinInput extends StatefulWidget {
  const _PinInput({required this.onSubmit});
  final void Function(String) onSubmit;

  @override
  State<_PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<_PinInput> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _obscure,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, letterSpacing: 8),
      maxLength: 6,
      decoration: InputDecoration(
        hintText: '• • • •',
        counterText: '',
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              size: 26),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onSubmitted: widget.onSubmit,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eylem Kartı
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.secondary,
                    height: 1.5)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: isLoading ? null : onTap,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        buttonLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
