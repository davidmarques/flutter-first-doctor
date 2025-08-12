import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';

class MedCalcPage extends StatefulWidget {
  const MedCalcPage({super.key});

  @override
  State<MedCalcPage> createState() => _MedCalcPageState();
}

class _MedCalcPageState extends State<MedCalcPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Ferramenta, 1 = Histórico
  final List<String> _calculadoras = [];
  final Map<String, String> _calculadorasNomes = {};
  final TextEditingController _perguntaController = TextEditingController();
  String? _resposta;
  String? _userCountry;
  bool _loadingQuestion = false;
  String? _pendingMessage;
  List<Map<String, String>>? _resultParts;

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
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

  @override
  void dispose() {
    _perguntaController.dispose();
    super.dispose();
  }

  Future<void> _enviarPergunta() async {
    setState(() {
      _loadingQuestion = true;
      _resposta = null;
      _resultParts = null;
      _pendingMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // Construir o corpo da requisição
      final Map<String, dynamic> requestBody = {
        'calculatorId1': _calculadoras[0],
        'question': _perguntaController.text.trim(),
      };
      
      if (_calculadoras.length > 1) {
        requestBody['calculatorId2'] = _calculadoras[1];
      }

      final url = Uri.parse('$apiBaseUrl/medicalcalculator/${_userCountry ?? 'br'}');
      final response = await http.post(
        url,
        body: json.encode(requestBody),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      );

      final responseJson = json.decode(response.body);
      if (responseJson['success'] != true) {
        setState(() { _loadingQuestion = false; });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseJson['message'] ?? 'Erro ao enviar pergunta')),
          );
        }
        return;
      }

      final taskhash = responseJson['taskhash'];
      String pendingMsg = responseJson['message'] ?? 'Processando pergunta...';
      setState(() { _pendingMessage = pendingMsg; });

      // Iniciar polling
      bool done = false;
      while (!done && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        
        final statusUrl = Uri.parse('$apiBaseUrl/medicalcalculator/$taskhash');
        final statusResp = await http.get(
          statusUrl,
          headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
        );
        
        final statusJson = json.decode(statusResp.body);
        if (statusJson['success'] != true) {
          setState(() { _loadingQuestion = false; });
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
          
          setState(() {
            _loadingQuestion = false;
            _resposta = data['result'] ?? '';
            _pendingMessage = null;
            
            // Processar result_parts
            if (data['result_parts'] != null) {
              _resultParts = (data['result_parts'] as List).map<Map<String, String>>((item) => {
                'titulo': item['titulo'] ?? '',
                'conteudo': item['conteudo'] ?? '',
              }).toList();
            }
          });
        }
      }
    } catch (e) {
      setState(() { _loadingQuestion = false; });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    }
  }

  void _abrirModalAdicionarCalculadora() async {
    // TODO: Implementar modal para seleção de calculadoras
    // Por enquanto, adiciona uma calculadora de exemplo
    if (_calculadoras.length < 2) {
      setState(() {
        final id = 'calc_${DateTime.now().millisecondsSinceEpoch}';
        _calculadoras.add(id);
        _calculadorasNomes[id] = 'Calculadora de exemplo';
      });
    }
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
                        'MedCalc',
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
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1 - Seleção de calculadoras
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              ..._calculadoras.map((id) => Chip(
                                    label: Text(_calculadorasNomes[id] ?? id),
                                    onDeleted: () => setState(() {
                                      _calculadoras.remove(id);
                                      _calculadorasNomes.remove(id);
                                    }),
                                  )),
                              if (_calculadoras.length < 2)
                                ElevatedButton.icon(
                                  onPressed: _abrirModalAdicionarCalculadora,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar calculadora'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 2 - Pergunta
                          TextField(
                            controller: _perguntaController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Digite sua pergunta sobre a(s) calculadora(s)',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.5),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/diagonal-gradient.webp'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _calculadoras.isEmpty || _perguntaController.text.trim().isEmpty || _loadingQuestion
                                    ? null
                                    : _enviarPergunta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _loadingQuestion
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _pendingMessage ?? 'Processando...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _calculadoras.isEmpty
                                            ? 'Selecione ao menos uma calculadora'
                                            : _calculadoras.length == 1
                                                ? 'Perguntar sobre ${_calculadorasNomes[_calculadoras[0]] ?? _calculadoras[0]}'
                                                : 'Perguntar sobre as calculadoras',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // 3 - Resposta
                          if (_resposta != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Html(data: _resposta!),
                            ),
                            if (_resultParts != null && _resultParts!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Resultados da Calculadora:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...(_resultParts!.map((section) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ExpansionTile(
                                  title: Text(
                                    section['titulo'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Html(data: section['conteudo'] ?? ''),
                                    ),
                                  ],
                                ),
                              ))),
                            ],
                          ],
                        ],
                      ),
                    )
                    : const Center(
                        child: Text(
                          'Aqui será exibido o histórico de pesquisas.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
