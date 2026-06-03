import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bir işlem başarıyla tamamlandığında tam ekran yeşil overlay gösterir.
/// instructions.md: "Every successful action must show a large, full-screen overlay
/// or massive Snackbar with a giant green checkmark and clear text."
///
/// Kullanım:
/// ```dart
/// SuccessOverlay.show(context, message: 'Ürün Başarıyla Kaydedildi!');
/// ```
class SuccessOverlay {
  SuccessOverlay._();

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismissed,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SuccessOverlayWidget(
        message: message,
        duration: duration,
        onDismissed: () {
          entry.remove();
          onDismissed?.call();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _SuccessOverlayWidget extends StatefulWidget {
  const _SuccessOverlayWidget({
    required this.message,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_SuccessOverlayWidget> createState() => _SuccessOverlayWidgetState();
}

class _SuccessOverlayWidgetState extends State<_SuccessOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: AppColors.successOverlay,
        child: InkWell(
          onTap: () {
            _controller.reverse().then((_) => widget.onDismissed());
          },
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Devam etmek için dokun',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
