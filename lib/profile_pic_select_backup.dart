import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'p      );

      if (response.statusCode == 200) {
        // Imagem existe, retorna a URL
        final imageUrl = endpoint; // A própria URL do endpoint serve a imagem
        return imageUrl;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Erro ao buscar imagem de perfil: ${response.statusCode}');
        return null;
      }uth/firebase_auth.dart';
import 'config_base.dart';

/// Classe para gerenciar seleção e upload de imagem de perfil
class ProfilePicSelect {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona uma imagem da galeria ou câmera
  static Future<File?> selectImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1000,
    int maxHeight = 1000,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Verifica se a imagem tem tamanho adequado (pelo menos 500px em algum lado)
        try {
          // Para uma validação mais robusta, você pode usar o package image para verificar dimensões
          // Por enquanto, apenas retornamos o arquivo já que o image_picker já redimensionou
          return file;
        } catch (e) {
          return file; // Retorna mesmo com erro de validação
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Mostra dialog para escolher entre galeria ou câmera
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final result = await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecionar Imagem de Perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceOption(
                        context: context,
                        icon: Icons.photo_library,
                        label: 'Galeria',
                        onTap: () async {
                          final file = await selectImage(source: ImageSource.gallery);
                          Navigator.pop(context, file);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSourceOption(
                        context: context,
                        icon: Icons.camera_alt,
                        label: 'Câmera',
                        onTap: () async {
                          final file = await selectImage(source: ImageSource.camera);
                          Navigator.pop(context, file);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    return result;
  }

  /// Constrói opção de origem da imagem
  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém extensão do arquivo
  static String _getFileExtension(File file) {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  /// Obtém a URL da imagem de perfil do servidor
  static Future<String?> getProfileImageUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Usuário não autenticado para buscar imagem de perfil');
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

      debugPrint('� Headers enviados GET: Authorization: Bearer ${idToken?.substring(0, 50)}...');
      debugPrint('�📡 Status Code GET profile_pic: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Imagem existe, retorna a URL
        final imageUrl = endpoint; // A própria URL do endpoint serve a imagem
        debugPrint('✅ Imagem de perfil encontrada: $imageUrl');
        return imageUrl;
      } else if (response.statusCode == 404) {
        debugPrint('📷 Nenhuma imagem de perfil encontrada (404)');
        return null;
      } else {
        debugPrint('⚠️ Erro ao buscar imagem de perfil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Erro ao buscar imagem de perfil: $e');
      return null;
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

  /// Mostra loading dialog durante upload
  static Future<ProfileImageUploadResult?> uploadWithLoading({
    required BuildContext context,
    required File imageFile,
  }) async {
    // Mostra dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Enviando imagem...'),
            ],
          ),
        );
      },
    );

    try {
      // Faz upload
      final result = await uploadProfileImage(imageFile);
      
      // Remove dialog de loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Mostra resultado
      if (context.mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem enviada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erro desconhecido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      return result;
    } catch (e) {
      // Remove dialog de loading em caso de erro
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Processo completo: seleção + upload
  static Future<ProfileImageUploadResult?> selectAndUploadImage(BuildContext context) async {
    // Seleciona imagem
    final imageFile = await showImageSourceDialog(context);
    if (imageFile == null) {
      return null;
    }

    // Faz upload com loading
    return await uploadWithLoading(
      context: context,
      imageFile: imageFile,
    );
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
