import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUploadService {
  final cloudinary = CloudinaryPublic('dfywekuna', 'tafita', cache: false);

  Future<String?> uploadAlreadyPickedImage(XFile image) async {
    try {
      debugPrint('Tentative d\'upload pour: ${image.path}');
      
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Use XFile.readAsBytes to compress efficiently
      final bytes = await image.readAsBytes();
      
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      // Write compressed bytes to file
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(result);

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(compressedFile.path, resourceType: CloudinaryResourceType.Image),
      );
      
      debugPrint('Upload réussi: ${response.secureUrl}');
      // Clean up compressed file
      await compressedFile.delete();
      
      return response.secureUrl;
    } on DioException catch (e) {
      debugPrint('ERREUR DIO: ${e.message}');
      return null;
    } on CloudinaryException catch (e) {
      debugPrint('ERREUR CLOUDINARY: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('ERREUR GÉNÉRALE: $e');
      return null;
    }
  }

  Future<String?> pickAndUploadImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image == null) return null;

    return await uploadAlreadyPickedImage(image);
  }
}
