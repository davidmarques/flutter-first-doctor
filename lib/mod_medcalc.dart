import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_base.dart';
import 'mod_medcalc_modal.dart';
import 'mod_medcalc_ans.dart';

class MedCalcPage extends StatefulWidget {
  const MedCalcPage({super.key});

  @override
  State<MedCalcPage> createState() => _MedCalcPageState();
}

class _MedCalcPageState extends State<MedCalcPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Ferramenta, 1 = Histórico
  String? _calculadoraId;
  String? _calculadoraNome;
  String? _calculadoraDescricao;
  String? _calculadoraPerguntas;
  final TextEditingController _respostasController = TextEditingController();
  String? _resposta;
  String? _userCountry;
  bool _loadingQuestion = false;
  bool _loadingCalculatorData = false;
  String? _pendingMessage;

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
    _respostasController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculatorData(String calculatorId) async {
    setState(() {
      _loadingCalculatorData = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final url = Uri.parse('$baseUrl/calcdata/${_userCountry ?? 'br'}/$calculatorId');
      final response = await http.get(
        url,
        headers: idToken != null ? {'Authorization': 'Bearer $idToken'} : {},
      );

      final responseJson = json.decode(response.body);
      
      if (responseJson['success'] == true && responseJson['data'] != null) {
        final data = responseJson['data'];
        setState(() {
          _calculadoraNome = data['name'] ?? _calculadoraNome;
          _calculadoraDescricao = data['description'] ?? _calculadoraDescricao;
          _calculadoraPerguntas = data['questions'] ?? '';
          // Popular o campo de respostas com as perguntas
          _respostasController.text = _calculadoraPerguntas ?? '';
          _loadingCalculatorData = false;
        });
      } else {
        setState(() {
          _loadingCalculatorData = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseJson['message'] ?? 'Erro ao carregar dados da calculadora')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loadingCalculatorData = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    }
  }

  Future<void> _enviarPergunta() async {
    if (_calculadoraId == null) return;
    
    setState(() {
      _loadingQuestion = true;
      _resposta = null;
      _pendingMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // Construir o corpo da requisição para calcexec
      final Map<String, dynamic> requestBody = {
        'id': _calculadoraId!,
        'questions': _respostasController.text.trim(),
      };

      // Obter a URL base dinâmica
      final baseUrl = await ApiConfig.getCurrentUrl();
      final url = Uri.parse('$baseUrl/calcexec/${_userCountry ?? 'br'}');
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

      final taskhash = responseJson['task'];
      setState(() { _pendingMessage = 'Processando cálculo...'; });

      // Iniciar polling para calcexec
      bool done = false;
      while (!done && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        
        // Obter a URL base dinâmica para o status
        final baseUrl = await ApiConfig.getCurrentUrl();
        final statusUrl = Uri.parse('$baseUrl/calcexec/${_userCountry ?? 'br'}/$taskhash');
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
            // Não precisamos mais de result_parts para calcexec
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

  void _selecionarCalculadora() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalculatorSearchModal(userCountry: _userCountry ?? 'br'),
    );

    if (result != null) {
      setState(() {
        _calculadoraId = result['id']!;
        _calculadoraNome = result['name']!;
        _calculadoraDescricao = result['description']!;
        _calculadoraPerguntas = null;
        // Limpar resposta anterior ao selecionar nova calculadora
        _resposta = null;
        _respostasController.clear();
      });

      // Carregar dados detalhados da calculadora
      await _loadCalculatorData(result['id']!);
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
                          // 1 - Seleção de calculadora
                          if (_calculadoraId == null) ...[
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
                                child: ElevatedButton.icon(
                                  onPressed: _selecionarCalculadora,
                                  icon: const Icon(Icons.calculate),
                                  label: const Text('Selecionar Calculadora'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Calculadora selecionada
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _calculadoraNome ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _selecionarCalculadora,
                                        icon: const Icon(Icons.swap_horiz, size: 16),
                                        label: const Text('Trocar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _calculadoraDescricao ?? '',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Caixa de perguntas da calculadora
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.quiz_outlined, color: Colors.orange[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Perguntas da Calculadora',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_loadingCalculatorData)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (_calculadoraPerguntas != null && _calculadoraPerguntas!.isNotEmpty)
                                    Text(
                                      _calculadoraPerguntas!,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Carregando perguntas da calculadora...',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Campo de respostas ou resultado
                            if (_resposta != null) ...[
                              // Mostrar resultado do cálculo usando o componente modularizado
                              MedCalcAnswerWidget(
                                answer: _resposta!,
                                onRefreshCalculation: () {
                                  setState(() {
                                    _resposta = null;
                                    _respostasController.text = _calculadoraPerguntas ?? '';
                                  });
                                },
                              ),
                            ] else ...[
                              // Campo de respostas
                              TextField(
                                controller: _respostasController,
                                minLines: 4,
                                maxLines: 12,
                                decoration: InputDecoration(
                                  labelText: 'Responda às perguntas acima',
                                  hintText: 'Edite o texto acima adicionando suas respostas após cada pergunta...',
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  helperText: 'Dica: Mantenha as perguntas e adicione suas respostas após cada uma',
                                  helperMaxLines: 2,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Botão principal - só aparece quando não há resultado
                            if (_resposta == null) ...[
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
                                    onPressed: _calculadoraId == null || _respostasController.text.trim().isEmpty || _loadingQuestion
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
                                            _calculadoraId == null
                                                ? 'Selecione uma calculadora'
                                                : _respostasController.text.trim().isEmpty
                                                    ? 'Responda às perguntas'
                                                    : 'Efetuar Cálculo',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
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
