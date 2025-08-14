import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'config_base.dart';

class CalculatorSearchModal extends StatefulWidget {
  final String userCountry;

  const CalculatorSearchModal({super.key, required this.userCountry});

  @override
  State<CalculatorSearchModal> createState() => _CalculatorSearchModalState();
}

class _CalculatorSearchModalState extends State<CalculatorSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _calculators = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCalculators(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _calculators = [];
        _errorMessage = 'Digite pelo menos 3 caracteres para buscar';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final url = Uri.parse('$baseUrl/calcsearch/${widget.userCountry}/${Uri.encodeComponent(query.trim())}');
      final response = await http.get(
        url,
        headers: idToken != null ? {'Authorization': 'Bearer $idToken'} : {},
      );

      final responseJson = json.decode(response.body);
      
      if (responseJson['success'] == true) {
        final calcList = responseJson['calcList'] as List? ?? [];
        setState(() {
          _calculators = calcList.map<Map<String, String>>((calc) {
            String description = calc['description'] ?? '';
            if (description.length > 200) {
              description = '${description.substring(0, 200)}...';
            }
            return {
              'id': calc['id'] ?? '',
              'name': calc['name'] ?? '',
              'description': description,
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = responseJson['message'] ?? 'Erro ao buscar calculadoras';
          _calculators = [];
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Erro de conexão: $e';
        _calculators = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Buscar Calculadora'),
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
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Digite o nome da calculadora',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              onChanged: (value) {
                                // Debounce search
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (_searchController.text == value) {
                                    _searchCalculators(value);
                                  }
                                });
                              },
                              onSubmitted: _searchCalculators,
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
                              onPressed: () => _searchCalculators(_searchController.text),
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
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (!_loading && _calculators.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          child: ListView.builder(
                            itemCount: _calculators.length,
                            itemBuilder: (context, index) {
                              final calc = _calculators[index];
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
                                        // Informações da calculadora
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                calc['name']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                calc['description']!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Botão de ação
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pop(context, calc);
                                              },
                                              icon: const Icon(Icons.add, size: 16),
                                              label: const Text('Selecionar'),
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
                    if (!_loading && _calculators.isEmpty && _searchController.text.isNotEmpty && _errorMessage == null)
                      const Expanded(
                        child: Center(
                          child: Text('Nenhum resultado encontrado.'),
                        ),
                      ),
                    if (!_loading && _calculators.isEmpty && _searchController.text.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Digite pelo menos 3 caracteres para buscar calculadoras',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
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
