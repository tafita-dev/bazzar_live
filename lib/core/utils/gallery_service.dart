import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';

class GalleryService {
  static Future<bool> saveImageToGallery(String imagePath) async {
    try {
      await Gal.putImage(imagePath);
      debugPrint('Image saved to gallery: $imagePath');
      return true;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      return false;
    }
  }
}
