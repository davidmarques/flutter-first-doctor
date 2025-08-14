import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Removido SharedPreferences e profile.dart, não são mais necessários
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';


class SettingsScribeSection extends StatefulWidget {
  final void Function(String?)? onChanged;
  const SettingsScribeSection({Key? key, this.onChanged}) : super(key: key);

  @override
  State<SettingsScribeSection> createState() => _SettingsScribeSectionState();
}

class _SettingsScribeSectionState extends State<SettingsScribeSection> {
  Map<String, dynamic>? _scribeTypesByCountry;
  String? _selectedTypeKey;
  String? _countryCode;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final doc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
      final data = doc.data();
      final initialType = data?['scribetype'] as String?;
      _selectedTypeKey = initialType;
      await _loadCountryAndScribeTypes();
    } catch (e) {
      setState(() { _error = 'Erro ao carregar configuração inicial: $e'; _loading = false; });
    }
  }

  Future<void> _loadCountryAndScribeTypes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      String countryFromFirestore = userData?['country'] ?? 'us';
      String country = countryFromFirestore.toLowerCase(); // Converter para minúsculo
      _countryCode = country;
      
      // Obter token de autenticação do Firebase
      final idToken = await user.getIdToken();
      
      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/scribetypes'),
        headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _scribeTypesByCountry = data;
          _loading = false;
        });
      } else {
        setState(() { _error = 'Erro ao buscar tipos de scribe'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erro de conexão: $e'; _loading = false; });
    }
  }

  void _onTypeSelected(String typeKey) {
    setState(() { _selectedTypeKey = typeKey; });
    if (widget.onChanged != null) widget.onChanged!(typeKey);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configurações do módulo Scribe',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (!_loading && _scribeTypesByCountry != null)
          _buildScribeTypeSelector(context),
      ],
    );
  }

  Widget _buildScribeTypeSelector(BuildContext context) {
    final country = _countryCode ?? 'us';
    
    // Acessar os tipos do país específico, com fallback para 'us'
    final countryTypes = _scribeTypesByCountry![country] ?? _scribeTypesByCountry!['us'];
    
    if (countryTypes == null) {
      return const Text('Nenhum tipo de prontuário disponível');
    }
    
    final typeKeys = (countryTypes as Map<String, dynamic>).keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecione o tipo de prontuário para seu país:'),
        const SizedBox(height: 8),
        ...typeKeys.map((typeKey) {
          final type = countryTypes[typeKey] as Map<String, dynamic>;
          return RadioListTile<String>(
            title: Text(type['name'] ?? typeKey),
            subtitle: Text(type['description'] ?? ''),
            value: typeKey,
            groupValue: _selectedTypeKey,
            onChanged: (val) {
              if (val != null && val != _selectedTypeKey) {
                _onTypeSelected(val);
              }
            },
          );
        }).toList(),
      ],
    );
  }
}



