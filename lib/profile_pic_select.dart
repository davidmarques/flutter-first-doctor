import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/profile_image_service.dart';
import 'services/image_picker_service.dart';
import 'services/profile_image_uploader.dart';
import 'widgets/image_source_dialog.dart';

/// Classe principal para gerenciar seleção e upload de imagem de perfil
/// Coordena os diferentes serviços modulares
class ProfilePicSelect {
  
  /// Configuração padrão para imagens
  static const ImagePickerConfig _defaultConfig = ImagePickerConfig(
    maxWidth: 1000,
    maxHeight: 1000,
    imageQuality: 85,
  );

  /// Seleciona uma imagem da galeria ou câmera
  /// 
  /// [source] - Origem da imagem (galeria ou câmera)
  /// [config] - Configurações de qualidade e tamanho
  static Future<File?> selectImage({
    ImageSource source = ImageSource.gallery,
    ImagePickerConfig? config,
  }) async {
    return await ImagePickerService.selectImage(
      source: source,
      config: config ?? _defaultConfig,
    );
  }

  /// Mostra dialog para escolher entre galeria ou câmera
  /// 
  /// [context] - Contexto do widget
  /// [config] - Configurações de qualidade e tamanho
  static Future<File?> showImageSourceDialog(
    BuildContext context, {
    ImagePickerConfig? config,
  }) async {
    return await ImageSourceDialog.show(
      context,
      config: config ?? _defaultConfig,
    );
  }

  /// Obtém a URL da imagem de perfil do servidor
  static Future<String?> getProfileImageUrl() async {
    try {
      return await ProfileImageService.getProfileImageUrl();
    } catch (e) {
      debugPrint('Erro ao buscar imagem de perfil: $e');
      return null;
    }
  }

  /// Remove a imagem de perfil do servidor
  static Future<ProfileImageDeleteResult> deleteProfileImage() async {
    try {
      return await ProfileImageService.deleteProfileImage();
    } catch (e) {
      debugPrint('Erro ao deletar imagem de perfil: $e');
      return ProfileImageDeleteResult(
        success: false,
        error: 'Erro ao deletar imagem: $e',
      );
    }
  }

  /// Remove a imagem de perfil com loading visual
  /// 
  /// [context] - Contexto do widget
  /// [loadingMessage] - Mensagem personalizada de carregamento
  static Future<ProfileImageDeleteResult> deleteProfileImageWithLoading({
    required BuildContext context,
    String loadingMessage = 'Removendo imagem...',
  }) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingMessage),
          ],
        ),
      ),
    );

    try {
      // Remove a imagem
      final result = await deleteProfileImage();
      
      // Fecha o loading
      Navigator.of(context).pop();
      
      return result;
    } catch (e) {
      // Fecha o loading
      Navigator.of(context).pop();
      
      return ProfileImageDeleteResult(
        success: false,
        error: 'Erro ao deletar imagem: $e',
      );
    }
  }

  /// Envia imagem para o endpoint usando multipart/form-data
  /// 
  /// [imageFile] - Arquivo de imagem para upload
  static Future<ProfileImageUploadResult> uploadProfileImage(File imageFile) async {
    return await ProfileImageService.uploadProfileImage(imageFile);
  }

  /// Mostra loading dialog durante upload
  /// 
  /// [context] - Contexto do widget
  /// [imageFile] - Arquivo de imagem para upload
  /// [loadingMessage] - Mensagem personalizada de carregamento
  static Future<ProfileImageUploadResult?> uploadWithLoading({
    required BuildContext context,
    required File imageFile,
    String loadingMessage = 'Enviando imagem...',
  }) async {
    return await ProfileImageUploader.uploadWithLoading(
      context: context,
      imageFile: imageFile,
      loadingMessage: loadingMessage,
    );
  }

  /// Upload silencioso sem interface de usuário
  /// 
  /// [imageFile] - Arquivo de imagem para upload
  static Future<ProfileImageUploadResult> uploadSilent(File imageFile) async {
    return await ProfileImageUploader.uploadSilent(imageFile);
  }

  /// Processo completo: seleção + upload com interface
  /// 
  /// [context] - Contexto do widget
  /// [config] - Configurações de qualidade e tamanho
  /// [loadingMessage] - Mensagem personalizada de carregamento
  static Future<ProfileImageUploadResult?> selectAndUploadImage(
    BuildContext context, {
    ImagePickerConfig? config,
    String loadingMessage = 'Enviando imagem...',
  }) async {
    // Seleciona imagem
    final imageFile = await showImageSourceDialog(context, config: config);
    if (imageFile == null) {
      return null;
    }

    // Faz upload com loading
    return await uploadWithLoading(
      context: context,
      imageFile: imageFile,
      loadingMessage: loadingMessage,
    );
  }

  /// Processo completo silencioso: seleção + upload sem interface
  /// 
  /// [context] - Contexto do widget (apenas para seleção)
  /// [config] - Configurações de qualidade e tamanho
  static Future<ProfileImageUploadResult?> selectAndUploadSilent(
    BuildContext context, {
    ImagePickerConfig? config,
  }) async {
    // Seleciona imagem
    final imageFile = await showImageSourceDialog(context, config: config);
    if (imageFile == null) {
      return null;
    }

    // Faz upload silencioso
    return await uploadSilent(imageFile);
  }
}