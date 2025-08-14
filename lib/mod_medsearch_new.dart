// Widget externo para exibir a lista de artigos encontrados
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'config_base.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'mod_medsearch_config_modal.dart';

class MedSearchArticleList extends StatelessWidget {
  final List<dynamic> articles;
  const MedSearchArticleList({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artigos encontrados:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...articles.map(
          (article) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(
                article['titulo'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['autores'] != null)
                    Text(
                      'Autores: ${(article['autores'] as List).join(", ")}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (article['revista'] != null)
                    Text(
                      'Revista: ${article['revista']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (article['data'] != null)
                    Text(
                      'Ano: ${article['data']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (article['fonte'] != null)
                    Text(
                      'Fonte: ${article['fonte']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (article['doi'] != null)
                    Text(
                      'DOI: ${article['doi']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
              trailing: article['link'] != null
                  ? IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'Abrir artigo',
                      onPressed: () {
                        final url = article['link'];
                        if (url != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Link: $url')));
                        }
                      },
                    )
                  : null,
              onTap: null,
            ),
          ),
        ),
      ],
    );
  }
}

class MedSearchPage extends StatefulWidget {
  const MedSearchPage({super.key});

  @override
  State<MedSearchPage> createState() => _MedSearchPageState();
}

class _MedSearchPageState extends State<MedSearchPage> {
  @override
  void initState() {
    super.initState();
    _questionController.addListener(() {
      _questionTextNotifier.value = _questionController.text;
    });
    _loadJournalsOnStart();
  }

  void _loadJournalsOnStart() async {
    setState(() { _loadingConfig = true; });
    try {
      final firestoreJournals = await _getJournalsFromFirestore();
      setState(() {
        _journals = List<String>.from(firestoreJournals);
        _loadingConfig = false;
      });
    } catch (e) {
      setState(() {
        _loadingConfig = false;
        _configError = 'Erro ao carregar revistas: $e';
      });
    }
  }

  List<String> _journals = [];
  bool _loadingConfig = false;
  String? _configError;
  int _selectedTab = 0;
  bool _searching = false;
  String? _responseHtml;
  List<dynamic>? _articleList;
  String? _pendingMessage;
  late int _yearFrom = DateTime.now().year - 5;
  late int _yearTo = DateTime.now().year;
  final TextEditingController _questionController = TextEditingController();
  final ValueNotifier<String> _questionTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<int> _yearFromNotifier = ValueNotifier<int>(
    DateTime.now().year - 5,
  );
  final ValueNotifier<int> _yearToNotifier = ValueNotifier<int>(
    DateTime.now().year,
  );

  @override
  void dispose() {
    _questionController.dispose();
    _yearFromNotifier.dispose();
    _questionTextNotifier.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchJournalsJson() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final idToken = await firebaseUser?.getIdToken();
    
    // Obter a URL base dinâmica
    final baseUrl = await ApiConfig.getCurrentUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/journals'),
      headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erro ao buscar journals');
    }
  }

  Future<List<String>> _getJournalsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['journals'] != null && data['journals'] is List) {
      return List<String>.from(data['journals'].where((id) => id is String || id is int).map((id) => id.toString()));
    }
    return [];
  }

  void _showCustomJournalsDialog() async {
    // Sempre busca os IDs salvos no Firestore antes de abrir o modal
    final firestoreJournals = await _getJournalsFromFirestore();
    
    await MedSearchConfigModal.show(
      context: context,
      currentJournals: firestoreJournals,
      onJournalsChanged: (List<String> newJournals) {
        setState(() {
          _journals = List<String>.from(newJournals);
        });
      },
    );
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
                        'MedSearch',
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
                    ? _loadingConfig
                        ? const Center(child: CircularProgressIndicator())
                        : _configError != null
                            ? Center(
                                child: Text(
                                  _configError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: _fetchJournalsJson(),
                                      builder: (context, snapshot) {
                                        String selectedNames = '';
                                        if (_journals.isEmpty) {
                                          selectedNames = 'Nenhuma revista selecionada';
                                        } else if (snapshot.hasData) {
                                          final journalsJson = snapshot.data!;
                                          final names = _journals
                                              .map((id) => journalsJson[id]?['name'] ?? id)
                                              .toList();
                                          selectedNames = 'Revistas selecionadas: ${names.join(", ")}';
                                        } else {
                                          selectedNames = 'Carregando revistas...';
                                        }
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedNames,
                                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _showCustomJournalsDialog,
                                                child: const Text('Customizar', style: TextStyle(fontSize: 13)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _questionController,
                                        expands: true,
                                        minLines: null,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          labelText: 'Digite sua questão científica',
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(8)),
                                          ),
                                          hintText: 'Ex: Qual a evidência para uso de X em Y?',
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.5),
                                        ),
                                        enabled: !_searching,
                                        textInputAction: TextInputAction.newline,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: _yearFromNotifier,
                                            builder: (context, yearFromValue, _) {
                                              return DropdownButtonFormField<int>(
                                                value: yearFromValue,
                                                decoration: InputDecoration(
                                                  labelText: 'De',
                                                  border: const OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.5),
                                                ),
                                                items: List.generate(10, (i) {
                                                  final year = DateTime.now().year - 9 + i;
                                                  final enabled = year < _yearTo;
                                                  return DropdownMenuItem(
                                                    value: year,
                                                    enabled: enabled,
                                                    child: Text(
                                                      year.toString(),
                                                      style: TextStyle(
                                                        color: enabled ? null : Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                onChanged: (val) {
                                                  if (val != null && val < _yearTo) {
                                                    setState(() {
                                                      _yearFrom = val;
                                                      _yearFromNotifier.value = val;
                                                      // Se ano fim ficou inválido, ajusta
                                                      if (_yearTo <= val) {
                                                        _yearTo = val + 1;
                                                        _yearToNotifier.value = _yearTo;
                                                      }
                                                    });
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: _yearToNotifier,
                                            builder: (context, yearToValue, _) {
                                              return DropdownButtonFormField<int>(
                                                value: yearToValue,
                                                decoration: InputDecoration(
                                                  labelText: 'A',
                                                  border: const OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.5),
                                                ),
                                                items: List.generate(10, (i) {
                                                  final year = DateTime.now().year - 9 + i;
                                                  final enabled = year > _yearFrom;
                                                  return DropdownMenuItem(
                                                    value: year,
                                                    enabled: enabled,
                                                    child: Text(
                                                      year.toString(),
                                                      style: TextStyle(
                                                        color: enabled ? null : Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                onChanged: (val) {
                                                  if (val != null && val > _yearFrom) {
                                                    setState(() {
                                                      _yearTo = val;
                                                      _yearToNotifier.value = val;
                                                      // Se ano início ficou inválido, ajusta
                                                      if (_yearFrom >= val) {
                                                        _yearFrom = val - 1;
                                                        _yearFromNotifier.value = _yearFrom;
                                                      }
                                                    });
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_responseHtml != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Html(data: _responseHtml!),
                                        ),
                                      ),
                                    if (_articleList != null && _articleList!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: MedSearchArticleList(articles: _articleList!),
                                      ),
                                    const SizedBox(height: 8),
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
                            child: ValueListenableBuilder<String>(
                              valueListenable: _questionTextNotifier,
                              builder: (context, questionText, _) {
                                return ElevatedButton.icon(
                                  onPressed: _searching || questionText.trim().isEmpty ? null : () async {
                                    setState(() {
                                      _searching = true;
                                      _responseHtml = null;
                                      _articleList = null;
                                      _pendingMessage = null;
                                    });

                                    // Buscar ids dos jornais selecionados
                                    List<int> selectedJournalIds = [];
                                    String? idToken;
                                    try {
                                      final firebaseUser = FirebaseAuth.instance.currentUser;
                                      idToken = await firebaseUser?.getIdToken();
                                      
                                      // Obter a URL base dinâmica
                                      final baseUrl = await ApiConfig.getCurrentUrl();
                                      final journalsResp = await http.get(
                                        Uri.parse('$baseUrl/journals'),
                                        headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
                                      );
                                      final journalsJson = json.decode(journalsResp.body) as Map<String, dynamic>;
                                      for (final name in _journals) {
                                        final entry = journalsJson[name];
                                        if (entry != null && entry['id'] != null) {
                                          selectedJournalIds.add(
                                            entry['id'] is int
                                                ? entry['id']
                                                : int.tryParse(entry['id'].toString()) ?? 0,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setState(() { _searching = false; });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro ao buscar ids dos jornais: $e')),
                                        );
                                      }
                                      return;
                                    }

                                    // Obter a URL base dinâmica
                                    final baseUrl = await ApiConfig.getCurrentUrl();
                                    final url = Uri.parse('$baseUrl/medsearch');
                                    final postBody = json.encode({
                                      'request': questionText.trim(),
                                      'daterange': {
                                        'from': _yearFrom.toString(),
                                        'to': _yearTo.toString(),
                                      },
                                      'journals': selectedJournalIds,
                                      'options': {},
                                    });

                                    try {
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
                                        setState(() { _searching = false; });
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
                                        final statusUrl = Uri.parse('$baseUrl/medsearch/$taskhash');
                                        final statusResp = await http.get(
                                          statusUrl,
                                          headers: idToken != null ? { 'Authorization': 'Bearer $idToken' } : {},
                                        );
                                        final statusJson = json.decode(statusResp.body);
                                        if (statusJson['success'] != true) {
                                          setState(() { _searching = false; });
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
                                            _searching = false;
                                            _responseHtml = data['responseBody'] ?? '';
                                            _articleList = data['articleList'] as List<dynamic>?;
                                            _pendingMessage = null;
                                          });
                                        }
                                      }
                                    } catch (e) {
                                      setState(() { _searching = false; });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro de conexão: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: _searching
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.search, color: Colors.white),
                                  label: Text(
                                    _searching && _pendingMessage != null
                                        ? _pendingMessage!
                                        : 'Buscar Artigos',
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
                                );
                              },
                            ),
                          ),
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
