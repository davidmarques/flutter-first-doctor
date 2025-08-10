import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _hasChanged = false;
  Map<String, dynamic>? _userData;
  String? _errorMsg;
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _languageController = TextEditingController();
  final _currencyController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userData = null;
        _errorMsg = 'Usuário não autenticado.';
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          _userData = null;
          _errorMsg = null;
        });
        return;
      }
      setState(() {
        _userData = data;
        _displayNameController.text = data['display_name'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _languageController.text = data['language'] ?? '';
        _currencyController.text = data['currency'] ?? '';
        _countryController.text = data['country'] ?? '';
        _hasChanged = false;
        _errorMsg = null;
      });
    } catch (e) {
      setState(() {
        _userData = null;
        _errorMsg = 'Erro ao carregar dados do perfil: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'display_name': _displayNameController.text,
      'email': _emailController.text,
      'language': _languageController.text,
      'currency': _currencyController.text,
      'country': _countryController.text,
    }, SetOptions(merge: true));
    setState(() {
      _isEditing = false;
      _hasChanged = false;
    });
    _loadUserData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currencyController.dispose();
    _emailController.dispose();
    _languageController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exibe loading enquanto _userData não foi carregado
    if (_userData == null && _errorMsg == null) {
      // Caso não exista documento do usuário, mostra mensagem e botão para completar cadastro
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
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Seu perfil ainda não está completo.\nClique abaixo para preencher seus dados.',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/diagonal-gradient.webp'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          // Cria documento mínimo no Firestore
                          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                            'email': user.email ?? '',
                            'display_name': '',
                            'language': '',
                            'currency': '',
                            'country': '',
                          });
                          setState(() {
                            _isEditing = true;
                            _hasChanged = false;
                            _displayNameController.text = '';
                            _emailController.text = user.email ?? '';
                            _languageController.text = '';
                            _currencyController.text = '';
                            _countryController.text = '';
                          });
                          // Recarrega para garantir que _userData não fique nulo
                          _loadUserData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Completar cadastro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_errorMsg != null) {
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
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
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
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cancelar edição',
                  onPressed: () {
                    // Desfaz alterações e sai do modo edição
                    setState(() {
                      _isEditing = false;
                      _hasChanged = false;
                      _displayNameController.text = _userData?['display_name'] ?? '';
                      _emailController.text = _userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
                      _languageController.text = _userData?['language'] ?? '';
                      _currencyController.text = _userData?['currency'] ?? '';
                      _countryController.text = _userData?['country'] ?? '';
                    });
                  },
                ),
              TextButton(
                onPressed: _isEditing
                    ? (_hasChanged ? () {
                          if (_formKey.currentState!.validate()) {
                            _saveProfile();
                          }
                        } : null)
                    : () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                child: Text(
                  _isEditing ? 'Salvar' : 'Editar',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() => _hasChanged = true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    enabled: false, // email não editável
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                    ),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _languageController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Language',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (_) => setState(() => _hasChanged = true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currencyController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (_) => setState(() => _hasChanged = true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (_) => setState(() => _hasChanged = true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
