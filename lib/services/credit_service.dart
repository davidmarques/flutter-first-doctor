import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config_base.dart';

/// Serviço responsável pela comunicação com a API de créditos do usuário
class CreditService {
  
  /// Obtém os créditos do usuário da API
  static Future<UserCredits?> getUserCredits() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      // Obtém a URL base da API
      final baseUrl = await ApiConfig.getCurrentUrl();
      final endpoint = '$baseUrl/my_credit';

      // Obtém token de autenticação
      final idToken = await user.getIdToken();
      
      // Faz requisição GET para buscar créditos
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['credits'] != null) {
          final creditsData = responseData['credits'];
          return UserCredits(
            total: creditsData['total'] ?? 0,
            used: creditsData['used'] ?? 0,
          );
        } else {
          throw Exception('Resposta inválida da API');
        }
      } else if (response.statusCode == 404) {
        // Usuário não tem créditos configurados, retorna valores padrão
        return UserCredits(total: 1000, used: 0);
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar créditos: $e');
    }
  }
}

/// Classe para representar os créditos do usuário
class UserCredits {
  final int total;
  final int used;
  
  UserCredits({
    required this.total,
    required this.used,
  });
  
  /// Créditos restantes
  int get remaining => total - used;
  
  /// Porcentagem de créditos usados (0.0 a 1.0)
  double get usedPercentage => total > 0 ? used / total : 0.0;
  
  /// Porcentagem de créditos restantes (0.0 a 1.0)
  double get remainingPercentage => total > 0 ? remaining / total : 1.0;

  @override
  String toString() {
    return 'UserCredits{total: $total, used: $used, remaining: $remaining}';
  }
}
