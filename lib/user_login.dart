import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_create_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleSignInInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '962139125344-b4gbehpghq5s1t77f9m9ksm8bhl0u0i0.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
      debugPrint('Google Sign-In inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar Google Sign-In: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // No need to navigate manually - AuthWrapper will handle it
      } on FirebaseAuthException catch (e) {
        String message = 'Falha no login';
        if (e.code == 'user-not-found') {
          message = 'Usuário não encontrado para este email';
        } else if (e.code == 'wrong-password') {
          message = 'Senha incorreta';
        } else if (e.code == 'invalid-email') {
          message = 'Email inválido';
        } else if (e.code == 'invalid-credential') {
          message = 'Email ou senha incorretos';
        } else if (e.code == 'user-disabled') {
          message = 'Usuário desabilitado';
        } else if (e.code == 'too-many-requests') {
          message = 'Muitas tentativas. Tente novamente mais tarde';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro desconhecido durante o login'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_isGoogleSignInInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In não está inicializado. Aguarde...')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Iniciando Google Sign-In...');
      
      // Fazer logout primeiro para garantir nova autenticação
      await GoogleSignIn.instance.signOut();
      
      debugPrint('Iniciando processo de autenticação...');
      
      // Iniciar o processo de autenticação
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        debugPrint('Login cancelado pelo usuário');
        return;
      }

      debugPrint('Usuário Google obtido: ${googleUser.email}');

      // Obter os detalhes de autenticação
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Falha ao obter token de ID do Google');
      }

      debugPrint('Token de autenticação obtido');

      // Criar credencial para o Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Credencial Firebase criada');

      // Fazer login no Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      debugPrint('Login Firebase concluído: ${userCredential.user?.email}');
      
      // Verificar se é o primeiro login (criar documentos se necessário)
      final user = userCredential.user;
      if (user != null) {
        // Verificar se documento do usuário existe, se não, criar
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'country': '',
            'currency': '',
            'display_name': user.displayName ?? '',
            'email': user.email ?? '',
            'language': '',
          });
        }
        
        // Verificar se documento de config existe, se não, criar
        final configDoc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
        if (!configDoc.exists) {
          await FirebaseFirestore.instance.collection('config').doc(user.uid).set({
            'journals': <String>[], // Array vazio de strings
            'scribetype': null, // Null para forçar configuração
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login realizado com sucesso! Bem-vindo, ${userCredential.user?.displayName ?? userCredential.user?.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // AuthWrapper irá tratar a navegação automaticamente
      
    } catch (e) {
      debugPrint('Erro durante Google Sign-In: $e');
      
      String errorMessage = 'Erro durante login com Google';
      
      if (e.toString().contains('network_error')) {
        errorMessage = 'Erro de rede. Verifique sua conexão.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Login cancelado.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Falha no login. Tente novamente.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Title
                  Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/icone-fdoctor.webp',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.medical_services,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bem-vindo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Entre na sua conta para continuar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite seu email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Por favor, digite um email válido';
                  }
                  return null;
                },
                  ),
                  
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
                  ),
                  
                  const SizedBox(height: 24),

                  // Login Button
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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou', style: TextStyle(color: Color(0xFF666666))),
                  ),
                  Expanded(child: Divider()),
                ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Google Sign-In Button
                  SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  label: Text(
                    'Entrar com Google',
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : const Color(0xFF757575),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0B2), // Laranja claro
                    side: BorderSide(
                      color: _isLoading ? Colors.grey.shade300 : const Color(0xFFFF9800), // Borda laranja
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Create Account Link
                  GestureDetector(
                onTap: _isLoading ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAccountScreen(),
                    ),
                  );
                },
                child: Text(
                  'Não tem uma conta? Criar conta',
                  style: TextStyle(
                    color: _isLoading 
                      ? Colors.grey 
                      : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
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
