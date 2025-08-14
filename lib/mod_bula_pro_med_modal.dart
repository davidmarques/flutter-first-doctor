import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';

class BulaProMedModal {
  static Future<void> show({
    required BuildContext context,
    required List<String> jaSelecionadas,
    required void Function(String id, String nome) onSelecionar,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AdicionarMedicacaoModal(
          jaSelecionadas: jaSelecionadas,
          onSelecionar: onSelecionar,
        );
      },
    );
  }
}

class _AdicionarMedicacaoModal extends StatefulWidget {
  final List<String> jaSelecionadas;
  final void Function(String id, String nome) onSelecionar;
  
  const _AdicionarMedicacaoModal({
    required this.jaSelecionadas, 
    required this.onSelecionar,
  });

  @override
  State<_AdicionarMedicacaoModal> createState() => _AdicionarMedicacaoModalState();
}

class _AdicionarMedicacaoModalState extends State<_AdicionarMedicacaoModal> {
  String? _userCountry;
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserCountry() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        setState(() {
          _userCountry = (userData?['country'] ?? 'br').toString().toLowerCase();
        });
      }
    } catch (e) {
      setState(() {
        _userCountry = 'br'; // fallback
      });
    }
  }

  Future<http.Response> _fetchAuthenticatedLabel(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    
    // Obter a URL base dinâmica
    final baseUrl = await ApiConfig.getCurrentUrl();
    return await http.get(
      Uri.parse('$baseUrl/searchlabelassets/${_userCountry ?? 'br'}/$id/'),
      headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
    );
  }

  Future<void> _showLabelDialog(String id, String nomeProduto) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.7),
            body: FutureBuilder<http.Response>(
              future: _fetchAuthenticatedLabel(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Erro ao carregar', style: TextStyle(color: Colors.white)),
                        Text('${snapshot.error}', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  final data = snapshot.data!.body;
                  return Container(
                    color: Colors.white,
                    width: double.infinity,
                    height: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                nomeProduto.isNotEmpty ? nomeProduto : 'Bula do medicamento',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Html(data: data),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Nenhum dado encontrado.', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchMedicine(_controller.text);
    });
  }

  Future<void> _searchMedicine(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final url = Uri.parse('$baseUrl/searchmedicine/${_userCountry ?? 'br'}/$query');
      
      // Obter token de autenticação do Firebase
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      
      final response = await http.get(
        url,
        headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['mediList'] != null) {
          setState(() {
            _results = data['mediList'];
            _loading = false;
          });
        } else {
          setState(() {
            _results = [];
            _error = data['message'] ?? 'Nenhum resultado.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _results = [];
          _error = 'Erro: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _results = [];
        _error = 'Erro: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Adicionar Medicação'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                labelText: 'Buscar medicação',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              onSubmitted: _searchMedicine,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.black87),
                              onPressed: () => _searchMedicine(_controller.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (!_loading && _results.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          child: ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              final idProduto = item['id']?.toString() ?? '';
                              final nomeProduto = item['nome_produto'] ?? '';
                              final jaAdicionada = widget.jaSelecionadas.contains(idProduto);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Informações da medicação
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nomeProduto,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Categoria: ${item['categoria_regulatoria'] ?? ''}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                                              ),
                                              Text(
                                                'Classe: ${item['classe_terapeutica'] ?? ''}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                                              ),
                                              Text(
                                                'Princípio ativo: ${item['principio_ativo'] ?? ''}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Botões de ação
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.description_outlined, size: 16),
                                              label: const Text('Bula'),
                                              onPressed: () {
                                                _showLabelDialog(idProduto, nomeProduto);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black87,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            jaAdicionada
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.grey[300]!),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check, color: Colors.green, size: 16),
                                                        SizedBox(width: 4),
                                                        Text('Adicionado', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                                      ],
                                                    ),
                                                  )
                                                : ElevatedButton.icon(
                                                    onPressed: () {
                                                      widget.onSelecionar(idProduto, nomeProduto);
                                                      Navigator.of(context).pop();
                                                    },
                                                    icon: const Icon(Icons.add, size: 16),
                                                    label: const Text('Adicionar'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.lightGreen[200],
                                                      foregroundColor: Colors.black87,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (!_loading && _results.isEmpty && _controller.text.isNotEmpty && _error == null)
                      const Expanded(
                        child: Center(
                          child: Text('Nenhum resultado encontrado.'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
