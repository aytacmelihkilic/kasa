import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';

/// Platformdan bağımsız yedek dosyası okuma/yazma ve paylaşım.
class BackupFileHelper {
  BackupFileHelper._();

  /// Yedek JSON'u dosya olarak paylaşır (mobil + web).
  static Future<void> shareBackupJson(String json) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final fileName = 'seramik_yedek_$timestamp.json';
    final bytes = utf8.encode(json);

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: BackupService.kMimeType,
          ),
        ],
        subject: 'Seramik Kataloğu Yedeği',
        text: 'Seramik Kataloğu yedek dosyası',
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final xFile = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: BackupService.kMimeType,
      path: path,
    );

    await Share.shareXFiles(
      [xFile],
      subject: 'Seramik Kataloğu Yedeği',
      text: 'Seramik Kataloğu Yedeği - $timestamp',
    );
  }

  /// Kullanıcının seçtiği .json dosyasının içeriğini string olarak okur.
  static Future<String?> pickAndReadJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;

    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return utf8.decode(file.bytes!);
    }

    if (!kIsWeb && file.path != null) {
      // Mobil/desktop: path üzerinden okuma (file_picker bytes vermezse)
      final xFile = XFile(file.path!);
      return await xFile.readAsString();
    }

    throw const BackupException('Dosya okunamadı. Lütfen tekrar deneyin.');
  }
}
