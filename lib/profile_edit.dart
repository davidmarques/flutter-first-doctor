import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _loading = true;
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
        _loading = false;
        _errorMsg = 'Usuário não autenticado.';
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _displayNameController.text = data?['display_name'] ?? user.displayName ?? '';
        _emailController.text = data?['email'] ?? user.email ?? '';
        _languageController.text = data?['language'] ?? '';
        _currencyController.text = data?['currency'] ?? '';
        _countryController.text = data?['country'] ?? '';
        _loading = false;
        _errorMsg = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Erro ao carregar dados do perfil: $e';
      });
    }
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

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'display_name': _displayNameController.text.trim(),
      'email': _emailController.text.trim(),
      'language': _languageController.text.trim(),
      'currency': _currencyController.text.trim(),
      'country': _countryController.text.trim(),
    });
    if (mounted) {
      // Verifica se veio de um fluxo de setup inicial
      final canPop = Navigator.of(context).canPop();
      if (canPop) {
        Navigator.pop(context);
      } else {
        // Se não pode fazer pop, significa que veio do setup inicial
        // Redireciona para a verificação novamente
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
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
            title: const Text(
              'Edit Profile',
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
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMsg != null
                  ? Center(
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
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              style: const TextStyle(color: Colors.black87),
                              validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              style: const TextStyle(color: Colors.black87),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _languageController,
                              decoration: InputDecoration(
                                labelText: 'Language',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _currencyController,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 24),
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
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _saveProfile();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
}
