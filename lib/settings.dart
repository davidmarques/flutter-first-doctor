import 'package:flutter/material.dart';
import 'settings_scribe.dart';
import 'settings_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Métodos auxiliares para comparação
  String? _initialScribeType;
  String? _currentScribeType;
  Map<String, dynamic>? _initialSearchConfig;
  Map<String, dynamic>? _currentSearchConfig;
  List<String> _initialJournals = [];
  List<String> _currentJournals = [];
  bool _saving = false;
  bool _loaded = false;
  String? _saveError;

  bool _listEquals(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map? a, Map? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _hasChanges() {
    final scribeChanged = _currentScribeType != _initialScribeType;
    final searchChanged = !_mapEquals(_currentSearchConfig, _initialSearchConfig);
    final journalsChanged = !_listEquals(_currentJournals, _initialJournals);
    return scribeChanged || searchChanged || journalsChanged;
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
    final data = doc.data();
    setState(() {
      _initialScribeType = data?['scribetype'];
      _currentScribeType = data?['scribetype'];
      // Garante que só IDs válidos estejam em journals
      _initialJournals = data?['journals'] != null ? List<String>.from(data!['journals'].where((id) => id is String)) : [];
      _currentJournals = data?['journals'] != null ? List<String>.from(data!['journals'].where((id) => id is String)) : [];
      _loaded = true;
    });
  }

  Future<void> _saveConfig() async {
    setState(() { _saving = true; _saveError = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      // Remove advancedSearch e journals do search antes de salvar
      Map<String, dynamic> searchToSave = {};
      if (_currentSearchConfig != null) {
        searchToSave = Map<String, dynamic>.from(_currentSearchConfig!);
        searchToSave.remove('advancedSearch');
        searchToSave.remove('journals');
      }
      // Salva apenas os IDs das revistas
      await FirebaseFirestore.instance.collection('config').doc(user.uid).set({
        'scribetype': _currentScribeType,
        'journals': _currentJournals,
      }, SetOptions(merge: true));
      setState(() {
        _initialScribeType = _currentScribeType;
        _initialSearchConfig = _currentSearchConfig != null ? Map<String, dynamic>.from(_currentSearchConfig!) : {};
        _initialJournals = List<String>.from(_currentJournals);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuração salva!')));
      
      // Verifica se veio de um fluxo de setup inicial
      final canPop = Navigator.of(context).canPop();
      if (!canPop) {
        // Se não pode fazer pop, significa que veio do setup inicial
        // Redireciona para a verificação novamente
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      setState(() { _saveError = 'Erro ao salvar: $e'; });
    } finally {
      setState(() { _saving = false; });
    }
  }

  void _onScribeTypeChanged(String? newType) {
    setState(() {
      _currentScribeType = newType;
    });
  }

  void _onSearchConfigChanged(Map<String, dynamic> newConfig) {
    setState(() {
      final configCopy = Map<String, dynamic>.from(newConfig);
      List<String>? journalIds;
      if (configCopy['journals'] != null && configCopy['journals'] is List) {
        // Garante que só IDs válidos sejam usados
        journalIds = List<String>.from(configCopy['journals'].where((id) => id is String));
        configCopy.remove('journals');
      }
      _currentSearchConfig = configCopy;
      if (journalIds != null) {
        _currentJournals = journalIds;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/strong-radial-gradient.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              tooltip: 'Voltar',
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
            title: const Text(
              'Configurações',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              if (_loaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: (!_saving && _hasChanges())
                        ? _saveConfig
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/soft-gradient-diagonal.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Seção Search
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SettingsSearchSection(
                  initialConfig: {
                    'journals': _currentJournals,
                    // Adicione outros campos se necessário
                  },
                  onChanged: _onSearchConfigChanged,
                ),
              ),
              const SizedBox(height: 32),
              // Seção Scribe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SettingsScribeSection(
                  onChanged: _onScribeTypeChanged,
                ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(_saveError!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
