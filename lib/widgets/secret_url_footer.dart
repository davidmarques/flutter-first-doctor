import 'package:flutter/material.dart';
import '../config_base.dart';

class SecretUrlFooter extends StatefulWidget {
  const SecretUrlFooter({super.key});

  @override
  State<SecretUrlFooter> createState() => _SecretUrlFooterState();
}

class _SecretUrlFooterState extends State<SecretUrlFooter> {
  int _tapCount = 0;
  bool _isDevelopmentMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    final isDev = await ApiConfig.isDevelopmentMode();
    setState(() {
      _isDevelopmentMode = isDev;
    });
    print('DEBUG SecretUrlFooter: Current mode loaded - isDevelopmentMode = $isDev');
  }

  Future<void> _toggleUrlMode() async {
    final newMode = !_isDevelopmentMode;
    
    await ApiConfig.setDevelopmentMode(newMode);
    setState(() {
      _isDevelopmentMode = newMode;
    });

    // Mostrar notificação
    if (mounted) {
      final message = newMode 
          ? '🧪 Modo de desenvolvimento ativado\nURL: https://devapi.first.doctor'
          : '🚀 Modo de produção ativado\nURL: https://api.first.doctor';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: newMode ? Colors.orange[600] : Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _onTap() {
    setState(() {
      _tapCount++;
    });

    // Reset counter após 3 segundos sem tap
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _tapCount = 0;
        });
      }
    });

    // Quando atingir 7 taps, alterna o modo
    if (_tapCount == 7) {
      _toggleUrlMode();
      setState(() {
        _tapCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FirstDoctor - Todos os direitos reservados',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            // Indicador visual discreto do modo atual (apenas para desenvolvedores)
            if (_isDevelopmentMode)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
