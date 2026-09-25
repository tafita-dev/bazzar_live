import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_shopping/core/utils/image_upload_service.dart';
import 'package:live_shopping/core/widgets/camera_capture_page.dart';

class ImageCaptureResult {
  final String localPath;
  final String url;

  ImageCaptureResult({
    required this.localPath,
    required this.url,
  });
}

class ImageCaptureService {
  final ImageUploadService _uploadService = ImageUploadService();

  Future<ImageCaptureResult?> pickAndUpload({
    required BuildContext context,
    required ImageSource source,
  }) async {
    String? filePath;

    if (source == ImageSource.camera) {
      // Utiliser notre solution robuste camerawesome
      filePath = await CameraCapturePage.start(context);
    } else {
      // Continuer d'utiliser ImagePicker pour la galerie (généralement sans problème)
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compresser pour optimiser
        maxWidth: 1024,
        maxHeight: 1024,
      );
      filePath = file?.path;
    }

    if (filePath == null) {
      debugPrint('Aucune image capturée ou sélectionnée');
      return null;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ERREUR: Le fichier n\'existe pas: $filePath');
        return null;
      }

      // Convertir le path en XFile pour l'upload
      final url = await _uploadService.uploadAlreadyPickedImage(XFile(filePath));
      
      if (url == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'envoyer la photo.')),
          );
        }
        return null;
      }
      
      return ImageCaptureResult(localPath: filePath, url: url);
    } catch (e) {
      debugPrint('ERREUR lors de l\'upload: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'upload: $e')),
        );
      }
      return null;
    }
  }
}
