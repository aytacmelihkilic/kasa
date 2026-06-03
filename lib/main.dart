import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Android: tam ekran; içerik sistem çubuklarının arkasında kalmaz.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await DatabaseService.initialize();

  runApp(const KasaApp());
}

class KasaApp extends StatelessWidget {
  const KasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seramik Kataloğu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Tüm ekranlarda üst/alt sistem alanlarına saygı (navigasyon tuşları vb.)
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: child,
        );
      },
      home: const DashboardScreen(),
    );
  }
}

