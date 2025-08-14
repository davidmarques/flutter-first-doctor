import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_picker_service.dart';

/// Widget para modal de seleção de origem da imagem
class ImageSourceDialog extends StatelessWidget {
  final ImagePickerConfig config;

  const ImageSourceDialog({
    super.key,
    this.config = const ImagePickerConfig(),
  });

  /// Mostra o dialog de seleção
  static Future<File?> show(BuildContext context, {
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ImageSourceDialog(config: config);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildSourceOptions(context),
            const SizedBox(height: 16),
            _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  /// Constrói o handle visual do modal
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Constrói o título do modal
  Widget _buildTitle() {
    return const Text(
      'Selecionar Imagem de Perfil',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Constrói as opções de origem
  Widget _buildSourceOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSourceOption(
            context: context,
            icon: Icons.photo_library,
            label: 'Galeria',
            onTap: () => _selectFromGallery(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSourceOption(
            context: context,
            icon: Icons.camera_alt,
            label: 'Câmera',
            onTap: () => _selectFromCamera(context),
          ),
        ),
      ],
    );
  }

  /// Constrói uma opção de origem da imagem
  Widget _buildSourceOption({
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

  /// Constrói botão de cancelar
  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancelar'),
    );
  }

  /// Seleciona da galeria
  Future<void> _selectFromGallery(BuildContext context) async {
    final file = await ImagePickerService.selectImage(
      source: ImageSource.gallery,
      config: config,
    );
    if (context.mounted) {
      Navigator.pop(context, file);
    }
  }

  /// Seleciona da câmera
  Future<void> _selectFromCamera(BuildContext context) async {
    final file = await ImagePickerService.selectImage(
      source: ImageSource.camera,
      config: config,
    );
    if (context.mounted) {
      Navigator.pop(context, file);
    }
  }
}
