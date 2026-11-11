import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../theme/bazzar_colors.dart';

class CameraCapturePage extends StatelessWidget {
  const CameraCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: BazzarColors.night,
        foregroundColor: Colors.white,
        title: const Text('Une photo qui donne envie'),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
      ),
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final directory = await getTemporaryDirectory();

            final file = File(
              '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

            return SingleCaptureRequest(file.path, sensors.first);
          },
        ),
        onMediaCaptureEvent: (event) {
          if (event.status == MediaCaptureStatus.success && event.isPicture) {
            final path = event.filePath;
            if (path != null && path.isNotEmpty && context.mounted) {
              Navigator.of(context).pop(path);
            }
          }
        },
        onMediaTap: (mediaCapture) {
          final path = mediaCapture.filePath;

          if (path != null && path.isNotEmpty) {
            Navigator.of(context).pop(path);
          }
        },
      ),
    );
  }

  static Future<String?> start(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();

    if (!cameraStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La permission caméra est nécessaire.')),
        );
      }

      return null;
    }

    if (!context.mounted) {
      return null;
    }

    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
  }
}

extension on MediaCapture {
  String? get filePath {
    return captureRequest.when(
      single: (single) => single.file?.path,
      multiple: (multiple) => multiple.fileBySensor.values.first?.path,
    );
  }
}
