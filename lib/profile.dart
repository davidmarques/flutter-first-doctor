import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_pic.dart';
import 'profile_credit_info.dart';
import 'profile_pic_select.dart';
import 'services/credit_service.dart';
import 'main.dart';

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
  UserCredits? _userCredits; // Créditos do usuário
  final _formKey = GlobalKey<FormState>();
  final _profilePicKey = GlobalKey<State<ProfilePic>>(); // Chave para controlar ProfilePic
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _languageController = TextEditingController();
  final _currencyController = TextEditingController();
  final _countryController = TextEditingController();

  /// Verifica se um campo obrigatório está vazio e precisa de atenção visual
  bool _needsAttention(String value) {
    return value.trim().isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Navega para o Dashboard principal com verificação
  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UserOnboardingWrapper()),
      (route) => false,
    );
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userData = null;
        _userCredits = null;
        _errorMsg = 'Usuário não autenticado.';
      });
      return;
    }
    try {
      // Carrega dados do perfil e créditos em paralelo
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        CreditService.getUserCredits(),
      ]);
      
      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final credits = results[1] as UserCredits?;
      
      final data = doc.data();
      if (data == null) {
        setState(() {
          _userData = null;
          _userCredits = credits;
          _errorMsg = null;
        });
        return;
      }
      setState(() {
        _userData = data;
        _userCredits = credits;
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
        _userCredits = null;
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
                  // Se não conseguir voltar, vai para o Dashboard
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    _navigateToDashboard();
                  }
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
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight,
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
                  // Se não conseguir voltar, vai para o Dashboard
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    _navigateToDashboard();
                  }
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
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight,
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
                // Se não conseguir voltar, vai para o Dashboard
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  _navigateToDashboard();
                }
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
                    ? () {
                        if (_hasChanged) {
                          // Se há mudanças, valida e salva
                          if (_formKey.currentState!.validate()) {
                            _saveProfile();
                          }
                        } else {
                          // Se não há mudanças, cancela a edição (mesmo comportamento do botão X)
                          setState(() {
                            _isEditing = false;
                            _hasChanged = false;
                            _displayNameController.text = _userData?['display_name'] ?? '';
                            _emailController.text = _userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
                            _languageController.text = _userData?['language'] ?? '';
                            _currencyController.text = _userData?['currency'] ?? '';
                            _countryController.text = _userData?['country'] ?? '';
                          });
                        }
                      }
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
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Imagem de perfil com barra de progresso
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ProfilePic(
                              key: _profilePicKey,
                              size: 120,
                              totalCredits: _userCredits?.total ?? 1000,
                              usedCredits: _userCredits?.used ?? 0,
                              isEditable: _isEditing,
                              onTap: _isEditing ? () async {
                                // Usa o ProfilePicSelect para selecionar e fazer upload da imagem
                                final result = await ProfilePicSelect.selectAndUploadImage(context);
                                if (result != null && result.success) {
                                  debugPrint('Imagem enviada com sucesso: ${result.imageUrl}');
                                  
                                  // Marca como alterado
                                  setState(() {
                                    _hasChanged = true;
                                  });
                                  
                                  // Força o refresh da imagem de perfil imediatamente
                                  final profilePicState = _profilePicKey.currentState;
                                  if (profilePicState != null) {
                                    (profilePicState as dynamic).refreshProfileImage();
                                  }
                                  
                                  // Aguarda um pouco para garantir que a imagem foi atualizada
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  
                                  // Recarrega a página para atualizar completamente o estado
                                  _loadUserData();
                                }
                              } : null,
                            ),
                            // Botão para remover imagem (visível apenas no modo de edição E se há imagem)
                            if (_isEditing)
                              FutureBuilder<String?>(
                                future: ProfilePicSelect.getProfileImageUrl(),
                                builder: (context, snapshot) {
                                  // Só mostra o botão se há uma imagem
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(6),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          tooltip: 'Remover imagem de perfil',
                                          onPressed: () async {
                                            // Confirmação antes de deletar
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Remover imagem'),
                                                content: const Text('Tem certeza que deseja remover sua imagem de perfil?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                    ),
                                                    child: const Text('Remover'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                // Remove a imagem do servidor com loading
                                                final result = await ProfilePicSelect.deleteProfileImageWithLoading(
                                                  context: context,
                                                  loadingMessage: 'Removendo imagem...',
                                                );

                                                if (result.success) {
                                                  // Marca como alterado
                                                  setState(() {
                                                    _hasChanged = true;
                                                  });
                                                  
                                                  // Força o refresh da imagem de perfil imediatamente
                                                  final profilePicState = _profilePicKey.currentState;
                                                  if (profilePicState != null) {
                                                    (profilePicState as dynamic).refreshProfileImage();
                                                  }
                                                  
                                                  // Aguarda um pouco para garantir que a interface foi atualizada
                                                  await Future.delayed(const Duration(milliseconds: 300));
                                                  
                                                  // Recarrega a página para atualizar completamente o estado
                                                  _loadUserData();
                                                  
                                                  // Mostra mensagem de sucesso
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Imagem removida com sucesso!')),
                                                  );
                                                } else {
                                                  // Mostra erro
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erro ao remover imagem: ${result.error}'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                // Mostra erro
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Erro ao remover imagem: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Se não há imagem, não mostra o botão
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Informações de créditos
                        ProfileCreditInfo(
                          totalCredits: _userCredits?.total ?? 1000,
                          usedCredits: _userCredits?.used ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Aviso sobre campos obrigatórios vazios
                  if (_needsAttention(_displayNameController.text))
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alguns campos obrigatórios ainda não foram preenchidos',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Campos do formulário
                  TextFormField(
                    controller: _displayNameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: _needsAttention(_displayNameController.text) 
                          ? const TextStyle(color: Colors.red) 
                          : null,
                      hintText: _needsAttention(_displayNameController.text) && !_isEditing
                          ? 'Campo obrigatório - clique em Editar para preencher'
                          : null,
                      hintStyle: const TextStyle(color: Colors.red, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(
                          color: _needsAttention(_displayNameController.text) 
                              ? Colors.red 
                              : Colors.grey,
                          width: _needsAttention(_displayNameController.text) ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(
                          color: _needsAttention(_displayNameController.text) 
                              ? Colors.red 
                              : Colors.grey,
                          width: _needsAttention(_displayNameController.text) ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(
                          color: _needsAttention(_displayNameController.text) 
                              ? Colors.red 
                              : Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: _needsAttention(_displayNameController.text)
                          ? Colors.yellow.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),

                    ),
                    style: const TextStyle(color: Colors.black87),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onChanged: (value) {
                      setState(() => _hasChanged = true);
                    },
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
                  // Campos currency, language e country foram ocultados, mas continuam sendo carregados/salvos
                ],
              ),
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
