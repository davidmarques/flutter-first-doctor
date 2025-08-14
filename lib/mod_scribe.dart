import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';
import 'mod_scribe_config_modal.dart';

class ScribePage extends StatefulWidget {
  const ScribePage({super.key});

  @override
  State<ScribePage> createState() => _ScribePageState();
}

class _ScribePageState extends State<ScribePage> {
  String? _currentScribeType;
  Map<String, dynamic>? _scribeTypesByCountry;
  bool _loadingScribeType = true;
  String? _scribeTypeError;
  String? _userCountry; // Adicionar país do usuário

  // Mantém apenas uma versão de initState e dispose (já existente logo acima)

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  String _getScribeTypeName(String? typeKey) {
    if (typeKey == null || _scribeTypesByCountry == null) return typeKey ?? '';
    String country = _scribeTypesByCountry!.keys.first;
    final countryTypes = _scribeTypesByCountry![country] ?? _scribeTypesByCountry!['us'];
    final type = countryTypes[typeKey];
    return type != null && type['name'] != null ? type['name'] : typeKey;
  }

  void _showCustomScribeTypeDialog(BuildContext context) async {
    if (_scribeTypesByCountry == null) return;
    
    await ScribeTypeModal.show(
      context: context,
      scribeTypesByCountry: _scribeTypesByCountry!,
      currentScribeType: _currentScribeType,
      onScribeTypeChanged: (String newType) {
        setState(() {
          _currentScribeType = newType;
        });
      },
    );
  }

  Future<void> _loadScribeType() async {
    setState(() { _loadingScribeType = true; _scribeTypeError = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      
      // Carregar configuração do usuário (inclui scribetype)
      final configDoc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
      final configData = configDoc.data();
      final scribeType = configData?['scribetype'] as String?;
      _currentScribeType = scribeType;
      
      // Carregar país do perfil do usuário
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      String countryFromFirestore = userData?['country'] ?? 'us';
      _userCountry = countryFromFirestore.toLowerCase(); // Converter para minúsculo
      
      // Obter token de autenticação do Firebase
      final idToken = await user.getIdToken();
      
      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/scribetypes'),
        headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
      );
      if (response.statusCode == 200) {
        final types = json.decode(response.body) as Map<String, dynamic>;
        _scribeTypesByCountry = types;
      }
      setState(() { _loadingScribeType = false; });
    } catch (e) {
      setState(() { _scribeTypeError = 'Erro ao carregar modo de prontuário: $e'; _loadingScribeType = false; });
    }
  }
  bool _generating = false;
  String? _pendingMessage;
  String? _output;
  String? _originalMessage;
  String? _responseBody;
  bool _canUndo = false;
  bool _canRedo = false;
  int _selectedTab = 0; // 0 = Ferramenta, 1 = Histórico
  final TextEditingController _inputController = TextEditingController();
  // Para atualizar o estado quando o texto muda
  @override
  void initState() {
    super.initState();
    _loadScribeType();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    super.dispose();
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
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Center(
                      child: Text(
                        'Scribe',
                        style: TextStyle(
                          color: _selectedTab == 0 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  child: Text(
                    'Histórico',
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
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
          child: Column(
            children: [
              Expanded(
                child: _selectedTab == 0
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_loadingScribeType)
                              const Center(child: CircularProgressIndicator()),
                            if (_scribeTypeError != null)
                              Text(_scribeTypeError!, style: const TextStyle(color: Colors.red)),
                            if (!_loadingScribeType && _currentScribeType != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Modo de prontuário: ${_getScribeTypeName(_currentScribeType)}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _scribeTypesByCountry == null ? null : () => _showCustomScribeTypeDialog(context),
                                      child: const Text('Customizar', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                expands: true,
                                minLines: null,
                                maxLines: null,
                                decoration: InputDecoration(
                                  labelText: 'Digite palavras soltas ou tópicos',
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  hintText: 'Ex: febre, tosse, dor de cabeça...',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                ),
                                enabled: !_generating,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                            if (_output != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(_output!, style: const TextStyle(fontSize: 16)),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Aqui será exibido o histórico do Scribe.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            if (_selectedTab == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/diagonal-gradient.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _generating || _inputController.text.trim().isEmpty ? null : () async {
                              setState(() {
                                _generating = true;
                                _output = null;
                                _pendingMessage = null;
                                _originalMessage = null;
                                _responseBody = null;
                                _canUndo = false;
                                _canRedo = false;
                              });
                              
                              // Obter a URL base dinâmica
                              final baseUrl = await ApiConfig.getCurrentUrl();
                              final url = Uri.parse('$baseUrl/scribe/${_userCountry ?? 'us'}');
                              final postBody = json.encode({
                                'scribetype': _currentScribeType,
                                'scribetext': _inputController.text.trim(),
                              });
                                try {
                                  // Obter token de autenticação do Firebase
                                  final user = FirebaseAuth.instance.currentUser;
                                  final idToken = await user?.getIdToken();
                                  
                                  final resp = await http.post(
                                    url, 
                                    body: postBody, 
                                    headers: {
                                      'Content-Type': 'application/json',
                                      if (idToken != null) 'Authorization': 'Bearer $idToken',
                                    },
                                  );
                                  final respJson = json.decode(resp.body);
                                  if (respJson['success'] != true) {
                                    setState(() { _generating = false; });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(respJson['message'] ?? 'Erro ao enviar requisição')),
                                      );
                                    }
                                    return;
                                  }
                                  final taskhash = respJson['taskhash'];
                                  String pendingMsg = respJson['message'] ?? 'Processando...';
                                  setState(() { _pendingMessage = pendingMsg; });
                                  bool done = false;
                                  while (!done && mounted) {
                                    await Future.delayed(const Duration(seconds: 2));
                                    
                                    // Obter a URL base dinâmica para o status
                                    final baseUrl = await ApiConfig.getCurrentUrl();
                                    final statusUrl = Uri.parse('$baseUrl/scribe/$taskhash');
                                    
                                    // Obter token de autenticação para requisição de status
                                    final user = FirebaseAuth.instance.currentUser;
                                    final idToken = await user?.getIdToken();
                                    
                                    final statusResp = await http.get(
                                      statusUrl,
                                      headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
                                    );
                                    final statusJson = json.decode(statusResp.body);
                                    print('Valor recebido: ${statusResp.body}');
                                    if (statusJson['success'] != true) {
                                      setState(() { _generating = false; });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(statusJson['message'] ?? 'Erro ao consultar status')),
                                        );
                                      }
                                      return;
                                    }
                                    setState(() { _pendingMessage = statusJson['message'] ?? 'Processando...'; });
                                    if (statusJson['status'] == 'done') {
                                      done = true;
                                      final data = statusJson['data'] ?? {};
                                      print('Status = done - Valor em data: $data');
                                      print('Valor encontrado em scribeIn: ${data['scribeIn']}');
                                      print('Valor encontrado em scribeOut: ${data['scribeOut']}');
                                      setState(() {
                                        _generating = false;
                                        _originalMessage = data['scribeIn'] ?? '';
                                        _responseBody = data['scribeOut'] ?? '';
                                        _inputController.text = _responseBody ?? '';
                                        _output = null;
                                        _pendingMessage = null;
                                        _canUndo = _originalMessage != null && _originalMessage!.isNotEmpty;
                                        _canRedo = false;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  setState(() { _generating = false; });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro de conexão: $e')),
                                    );
                                  }
                                }
                              },
                        icon: _generating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          _generating && _pendingMessage != null
                              ? _pendingMessage!
                              : 'Enriquecer Prontuário',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: _canUndo && !_canRedo
                        ? 'Desfazer (voltar ao texto original)'
                        : _canRedo
                            ? 'Refazer (voltar ao texto enriquecido)'
                            : 'Desfazer',
                    icon: Icon(
                      _canUndo && !_canRedo
                          ? Icons.undo
                          : _canRedo
                              ? Icons.redo
                              : Icons.undo,
                      color: (_canUndo || _canRedo) ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    onPressed: (!_canUndo && !_canRedo) ? null : () {
                      setState(() {
                        if (_canUndo && !_canRedo && _originalMessage != null) {
                          _inputController.text = _originalMessage!;
                          _canUndo = false;
                          _canRedo = true;
                        } else if (_canRedo && _responseBody != null) {
                          _inputController.text = _responseBody!;
                          _canUndo = true;
                          _canRedo = false;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}