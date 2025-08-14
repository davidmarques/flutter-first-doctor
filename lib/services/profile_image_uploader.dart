import 'dart:io';
import 'package:flutter/material.dart';
import 'profile_image_service.dart';

/// Gerenciador de upload com UI
class ProfileImageUploader {
  
  /// Mostra loading dialog durante upload
  static Future<ProfileImageUploadResult?> uploadWithLoading({
    required BuildContext context,
    required File imageFile,
    String loadingMessage = 'Enviando imagem...',
  }) async {
    // Mostra dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loadingMessage),
            ],
          ),
        );
      },
    );

    try {
      // Faz upload
      final result = await ProfileImageService.uploadProfileImage(imageFile);
      
      // Remove dialog de loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Mostra resultado
      if (context.mounted) {
        _showUploadResult(context, result);
      }

      return result;
    } catch (e) {
      // Remove dialog de loading em caso de erro
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorMessage(context, 'Erro: $e');
      }
      return null;
    }
  }

  /// Upload silencioso sem UI
  static Future<ProfileImageUploadResult> uploadSilent(File imageFile) async {
    return await ProfileImageService.uploadProfileImage(imageFile);
  }

  /// Mostra resultado do upload
  static void _showUploadResult(BuildContext context, ProfileImageUploadResult result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorMessage(context, result.error ?? 'Erro desconhecido');
    }
  }

  /// Mostra mensagem de erro
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
