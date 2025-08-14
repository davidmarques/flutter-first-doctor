/// Exemplo de como migrar os módulos para usar URL dinâmica
/// 
/// ANTES (usando URL fixa):
/// ```dart
/// final url = Uri.parse('$apiBaseUrl/endpoint');
/// ```
/// 
/// DEPOIS (usando URL dinâmica):
/// ```dart
/// final baseUrl = await ApiConfig.getCurrentUrl();
/// final url = Uri.parse('$baseUrl/endpoint');
/// ```
/// 
/// OU usando a função helper:
/// ```dart
/// final url = await buildApiUrl('/endpoint');
/// ```

import 'config_base.dart';

/// Helper function para construir URLs da API dinamicamente
Future<Uri> buildApiUrl(String endpoint) async {
  final baseUrl = await ApiConfig.getCurrentUrl();
  return Uri.parse('$baseUrl$endpoint');
}

/// Helper function para fazer requisições HTTP com URL dinâmica
/// Exemplo de uso nos módulos existentes
class ApiHelper {
  /// Constrói uma URL completa com base nas configurações atuais
  static Future<String> getFullUrl(String endpoint) async {
    final baseUrl = await ApiConfig.getCurrentUrl();
    return '$baseUrl$endpoint';
  }
  
  /// Constrói um Uri com base nas configurações atuais
  static Future<Uri> getUri(String endpoint) async {
    final baseUrl = await ApiConfig.getCurrentUrl();
    return Uri.parse('$baseUrl$endpoint');
  }
}

/// Exemplo de migração para mod_medcalc.dart:
/// 
/// ANTES:
/// final url = Uri.parse('$apiBaseUrl/calcsearch/${_userCountry ?? 'br'}');
/// 
/// DEPOIS:
/// final url = await ApiHelper.getUri('/calcsearch/${_userCountry ?? 'br'}');
/// 
/// ANTES:
/// final url = Uri.parse('$apiBaseUrl/calcdata/${_userCountry ?? 'br'}/$calculatorId');
/// 
/// DEPOIS:
/// final url = await ApiHelper.getUri('/calcdata/${_userCountry ?? 'br'}/$calculatorId');
