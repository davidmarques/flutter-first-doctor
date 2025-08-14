import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Configurações de imagem
class ImagePickerConfig {
  final int maxWidth;
  final int maxHeight;
  final int imageQuality;

  const ImagePickerConfig({
    this.maxWidth = 1000,
    this.maxHeight = 1000,
    this.imageQuality = 85,
  });
}

/// Serviço responsável pela seleção de imagens
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona uma imagem da galeria ou câmera
  static Future<File?> selectImage({
    ImageSource source = ImageSource.gallery,
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: config.maxWidth.toDouble(),
        maxHeight: config.maxHeight.toDouble(),
        imageQuality: config.imageQuality,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Validação básica da imagem
        if (await _validateImage(file)) {
          return file;
        } else {
          debugPrint('Imagem não passou na validação');
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Valida se a imagem atende aos critérios
  static Future<bool> _validateImage(File imageFile) async {
    try {
      // Verifica se o arquivo existe
      if (!await imageFile.exists()) {
        return false;
      }

      // Verifica o tamanho do arquivo (máximo 5MB)
      final fileSize = await imageFile.length();
      const maxSizeBytes = 5 * 1024 * 1024; // 5MB
      
      if (fileSize > maxSizeBytes) {
        debugPrint('Arquivo muito grande: ${fileSize / (1024 * 1024)} MB');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Erro na validação da imagem: $e');
      return false;
    }
  }
}
