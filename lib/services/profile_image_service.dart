import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config_base.dart';

/// Serviço responsável pela comunicação com a API de imagens de perfil
class ProfileImageService {
  
  /// Obtém a URL da imagem de perfil do servidor
  static Future<String?> getProfileImageUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      // Obtém a URL base da API
      final baseUrl = await ApiConfig.getCurrentUrl();
      final endpoint = '$baseUrl/profile_pic';

      // Obtém token de autenticação
      final idToken = await user.getIdToken();
      
      // Faz requisição GET para verificar se existe imagem
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        // Imagem existe, retorna a URL
        return endpoint; // A própria URL do endpoint serve a imagem
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar imagem de perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar imagem de perfil: $e');
    }
  }

  /// Envia imagem para o endpoint usando multipart/form-data
  static Future<ProfileImageUploadResult> uploadProfileImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ProfileImageUploadResult(
          success: false,
          error: 'Usuário não autenticado',
        );
      }

      // Obtém a URL base da API
      final baseUrl = await ApiConfig.getCurrentUrl();
      final endpoint = '$baseUrl/profile_pic';

      // Prepara os dados da imagem
      final fileExtension = _getFileExtension(imageFile);
      final fileName = 'profile_${user.uid}.$fileExtension';

      // Obtém token de autenticação
      final idToken = await user.getIdToken();

      // Cria requisição multipart
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      
      // Adiciona headers
      request.headers.addAll({
        'Authorization': 'Bearer $idToken',
      });

      // Adiciona arquivo à requisição
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        final imageUrl = '$baseUrl/uploads/$fileName';
        return ProfileImageUploadResult(
          success: true,
          imageUrl: imageUrl,
          fileName: fileName,
        );
      } else {
        final errorMessage = responseData['message'] ?? 'Erro ao fazer upload da imagem';
        return ProfileImageUploadResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ProfileImageUploadResult(
        success: false,
        error: 'Erro de conexão: $e',
      );
    }
  }

  /// Remove a imagem de perfil do servidor
  static Future<ProfileImageDeleteResult> deleteProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ProfileImageDeleteResult(
          success: false,
          error: 'Usuário não autenticado',
        );
      }

      // Obtém a URL base da API
      final baseUrl = await ApiConfig.getCurrentUrl();
      final endpoint = '$baseUrl/profile_pic';

      // Obtém token de autenticação
      final idToken = await user.getIdToken();
      
      // Faz requisição DELETE
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return ProfileImageDeleteResult(success: true);
      } else if (response.statusCode == 404) {
        return ProfileImageDeleteResult(
          success: false,
          error: 'Imagem não encontrada',
        );
      } else {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Erro ao deletar imagem';
        return ProfileImageDeleteResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ProfileImageDeleteResult(
        success: false,
        error: 'Erro de conexão: $e',
      );
    }
  }

  /// Obtém extensão do arquivo
  static String _getFileExtension(File file) {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }
}

/// Resultado do upload da imagem
class ProfileImageUploadResult {
  final bool success;
  final String? imageUrl;
  final String? fileName;
  final String? error;

  ProfileImageUploadResult({
    required this.success,
    this.imageUrl,
    this.fileName,
    this.error,
  });

  @override
  String toString() {
    return 'ProfileImageUploadResult{success: $success, imageUrl: $imageUrl, fileName: $fileName, error: $error}';
  }
}

/// Resultado da remoção da imagem
class ProfileImageDeleteResult {
  final bool success;
  final String? error;

  ProfileImageDeleteResult({
    required this.success,
    this.error,
  });

  @override
  String toString() {
    return 'ProfileImageDeleteResult{success: $success, error: $error}';
  }
}
