/// Configurações globais do app
import 'package:shared_preferences/shared_preferences.dart';

/// Hostname base da API - Modo padrão (produção)
const String _productionApiUrl = 'https://api.first.doctor';
const String _developmentApiUrl = 'https://devapi.first.doctor';

// IMPORTANTE: apiBaseUrl não é mais uma constante!
// Use ApiConfig.getCurrentUrl() ou getCurrentApiUrl() para obter a URL atual
@Deprecated('Use ApiConfig.getCurrentUrl() para obter a URL dinâmica')
const String apiBaseUrl = _productionApiUrl;

/// Classe utilitária para gerenciar URLs da API
class ApiConfig {
  static const String _productionUrl = _productionApiUrl;
  static const String _developmentUrl = _developmentApiUrl;
  
  /// Obtém a URL atual baseada nas configurações do usuário
  static Future<String> getCurrentUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isDevelopmentMode = prefs.getBool('isDevelopmentMode') ?? false;
    
    // Debug: Log para verificar qual modo está sendo usado
    print('DEBUG ApiConfig: isDevelopmentMode = $isDevelopmentMode');
    print('DEBUG ApiConfig: Using URL = ${isDevelopmentMode ? _developmentUrl : _productionUrl}');
    
    return isDevelopmentMode ? _developmentUrl : _productionUrl;
  }
  
  /// Verifica se está em modo desenvolvimento
  static Future<bool> isDevelopmentMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDevelopmentMode') ?? false;
  }
  
  /// Define o modo da API
  static Future<void> setDevelopmentMode(bool isDevelopment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDevelopmentMode', isDevelopment);
    print('DEBUG ApiConfig: setDevelopmentMode called with $isDevelopment');
  }
  
  /// Força o modo de produção (limpa configuração de desenvolvimento)
  static Future<void> forceProductionMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isDevelopmentMode'); // Remove a chave para usar o padrão (false)
    print('DEBUG ApiConfig: Forced production mode - removed isDevelopmentMode key');
  }
}

/// Função para obter a URL atual baseada nas configurações (retrocompatibilidade)
Future<String> getCurrentApiUrl() async {
  return ApiConfig.getCurrentUrl();
}

/// Função para verificar se está em modo desenvolvimento (retrocompatibilidade)
Future<bool> isDevelopmentMode() async {
  return ApiConfig.isDevelopmentMode();
}