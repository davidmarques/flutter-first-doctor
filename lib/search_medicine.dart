import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config_base.dart';

class SearchMedicinePage extends StatefulWidget {
  const SearchMedicinePage({super.key});

  @override
  State<SearchMedicinePage> createState() => _SearchMedicinePageState();
}

class _SearchMedicinePageState extends State<SearchMedicinePage> {
  Future<http.Response> _fetchAuthenticatedLabel(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    
    return await http.get(
      Uri.parse('$apiBaseUrl/searchlabelassets/br/$id'),
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
                                nomeProduto.isNotEmpty ? nomeProduto : 'Etiqueta do medicamento',
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
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
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
      final url = Uri.parse('$apiBaseUrl/searchmedicine/br/$query');
      
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
            _error = data['message'] ?? 'No results.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _results = [];
          _error = 'Error: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _results = [];
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search for medicine',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (!_loading && _results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final nomeProduto = item['nome_produto'] ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(nomeProduto),
                        subtitle: Text(
                          'Categoria: ${item['categoria_regulatoria'] ?? ''}\n'
                          'Classe: ${item['classe_terapeutica'] ?? ''}\n'
                          'Princípio ativo: ${item['principio_ativo'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.help_outline),
                              tooltip: 'Pergunta',
                              onPressed: () {
                                // TODO: Add question button functionality
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.label_outline),
                              tooltip: 'Etiqueta do medicamento',
                              onPressed: () {
                                _showLabelDialog(item['id'] ?? '', nomeProduto);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
