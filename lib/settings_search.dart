import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';

class SettingsSearchSection extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onChanged;
  final Map<String, dynamic>? initialConfig;
  final bool useGradientBackground;
  const SettingsSearchSection({
    Key? key, 
    this.onChanged, 
    this.initialConfig,
    this.useGradientBackground = false,
  }) : super(key: key);

  @override
  State<SettingsSearchSection> createState() => _SettingsSearchSectionState();
}

class _SettingsSearchSectionState extends State<SettingsSearchSection> {
  // bool _advancedSearch = false; // Removido campo advancedSearch
  bool _loading = true;
  String? _error;
  String? _userLang;
  Map<String, dynamic>? _journals;
  List<String> _availableJournalIds = [];
  Set<String> _selectedJournalIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      String lang = userData?['language'] ?? 'en';
      _userLang = lang;
      // Carregar journals do endpoint de forma autenticada
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final idToken = await firebaseUser?.getIdToken();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/journals'),
        headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Impressão para depuração: mostra as chaves do JSON
        // ignore: avoid_print
        print('[SettingsSearchSection] Chaves do JSON de journals: \\${data.keys.toList()}');
        _journals = data;
        _availableJournalIds = _getJournalIdsForLang(data, lang);
      } else {
        throw Exception('Erro ao buscar journals');
      }
      // Carregar config inicial (agora IDs)
      final selected = widget.initialConfig?['journals'] as List?;
      // Garante que só IDs válidos estejam selecionados
      if (selected != null) {
        _selectedJournalIds = Set<String>.from(selected.where((id) => _availableJournalIds.contains(id)));
      } else {
        _selectedJournalIds = {};
      }
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar configurações: $e'; _loading = false; });
    }
  }

  List<String> _getJournalIdsForLang(Map<String, dynamic> data, String lang) {
    final List<String> result = [];
    data.forEach((id, value) {
      if (value['langlist'] != null && value['langlist'][lang] != null) {
        result.add(id);
      }
    });
    // fallback para 'en' se não houver nenhum no idioma
    if (result.isEmpty && lang != 'en') {
      data.forEach((id, value) {
        if (value['langlist'] != null && value['langlist']['en'] != null) {
          result.add(id);
        }
      });
    }
    return result;
  }

  // void _loadInitialConfig() { /* Removido pois não é mais necessário */ }

  // void _onAdvancedSearchChanged(bool? value) { /* Removido */ }

  void _onJournalChanged(bool? value, String journalKey) {
    setState(() {
      if (value == true) {
        _selectedJournalIds.add(journalKey);
      } else {
        _selectedJournalIds.remove(journalKey);
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      // Sempre envia os IDs
      final payload = {
        'journals': _selectedJournalIds.toList(),
      };
      // Impressão para depuração
      // ignore: avoid_print
      print('[SettingsSearchSection] Enviando para onChanged: journals = \\${payload['journals']}');
      widget.onChanged!(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configurações do módulo Search',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_availableJournalIds.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revistas eletrônicas disponíveis para seu idioma:'),
              ..._availableJournalIds.map((journalId) {
                final journal = _journals![journalId];
                final lang = _userLang ?? 'en';
                final articles = journal['langlist'][lang]?['articles'] ?? 0;
                final name = journal['name'] ?? journalId;
                
                if (widget.useGradientBackground) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/soft-gradient-diagonal.webp'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Card(
                      elevation: 0,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${journal['url']}  |  Artigos: $articles',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        value: _selectedJournalIds.contains(journalId),
                        activeColor: Colors.black87,
                        onChanged: (val) => _onJournalChanged(val, journalId),
                      ),
                    ),
                  );
                } else {
                  return CheckboxListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${journal['url']}  |  Artigos: $articles',
                    ),
                    value: _selectedJournalIds.contains(journalId),
                    onChanged: (val) => _onJournalChanged(val, journalId),
                  );
                }
              }).toList(),
            ],
          ),
      ],
    );
  }
}
