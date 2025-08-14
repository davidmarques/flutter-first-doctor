import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'profile_pic_select.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ProfilePic extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final int totalCredits;
  final int usedCredits;
  final String? imagePath; // URL manual passada (opcional)
  final bool isEditable;
  final VoidCallback? onTap;

  const ProfilePic({
    super.key,
    this.size = 120.0,
    this.strokeWidth = 6.0,
    this.totalCredits = 1000, // Total de créditos disponíveis
    this.usedCredits = 25,   // Créditos já utilizados
    this.imagePath,
    this.isEditable = false,
    this.onTap,
  });

  @override
  State<ProfilePic> createState() => _ProfilePicState();
}

class _ProfilePicState extends State<ProfilePic> {
  String? _serverImageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Widget para carregar imagem com autenticação
  Widget _buildAuthenticatedImage(String imageUrl) {
    return FutureBuilder<Uint8List?>(
      future: _loadImageWithAuth(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.hasError) {
          debugPrint('Erro ao carregar imagem autenticada: ${snapshot.error}');
          return _buildDefaultAvatar();
        } else if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        } else {
          return _buildDefaultAvatar();
        }
      },
    );
  }

  /// Carrega imagem com headers de autenticação
  Future<Uint8List?> _loadImageWithAuth(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Carrega imagem de perfil do servidor
  Future<void> _loadProfileImage() async {
    if (widget.imagePath != null) {
      // Se uma imagePath foi fornecida manualmente, usa ela
      return;
    }

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final imageUrl = await ProfilePicSelect.getProfileImageUrl();
      if (mounted) {
        setState(() {
          _serverImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar imagem de perfil: $e');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  /// Método público para recarregar a imagem do servidor
  void refreshProfileImage() {
    _loadProfileImage();
  }

  /// Método público para verificar se existe uma imagem de perfil
  bool hasProfileImage() {
    return widget.imagePath != null || _serverImageUrl != null;
  }

  @override
  Widget build(BuildContext context) {
    // Variáveis calculadas baseadas nos créditos
    final int remainingCredits = widget.totalCredits - widget.usedCredits;
    final double progress = remainingCredits / widget.totalCredits; // Percentual de créditos restantes
    final int progressPercentage = (progress * 100).toInt();
    
    // Determina qual imagem usar: manual, do servidor, ou padrão
    final String? effectiveImagePath = widget.imagePath ?? _serverImageUrl;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            // Círculo de fundo (progresso não preenchido)
            Center(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0, // Círculo completo como fundo
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            
            // Barra de progresso circular (créditos)
            Center(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Transform.rotate(
                  angle: -math.pi / 2, // Inicia do topo
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: widget.strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ),
            ),

            // Imagem de perfil no centro
            Center(
              child: Container(
                width: widget.size - (widget.strokeWidth * 2) - 8, // Espaço para a borda
                height: widget.size - (widget.strokeWidth * 2) - 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isLoadingImage
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : effectiveImagePath != null
                          ? (effectiveImagePath.startsWith('http') 
                              ? _buildAuthenticatedImage(effectiveImagePath)
                              : Image.asset(
                                  effectiveImagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                ))
                          : _buildDefaultAvatar(),
                ),
              ),
            ),

            // Ícone de edição (se editável)
            if (widget.isEditable)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

            // Indicador de porcentagem de créditos (opcional)
            if (progress < 1.0)
              Positioned(
                bottom: widget.isEditable ? 35 : 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progressPercentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Determina a cor da barra de progresso baseada na porcentagem
  Color _getProgressColor(double progress) {
    if (progress >= 0.7) {
      return Colors.green; // Verde para 70% ou mais
    } else if (progress >= 0.4) {
      return Colors.orange; // Laranja para 40-69%
    } else {
      return Colors.red; // Vermelho para menos de 40%
    }
  }

  /// Constrói o avatar padrão quando não há imagem
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: (widget.size - (widget.strokeWidth * 2) - 8) * 0.6,
        color: Colors.white,
      ),
    );
  }
}
