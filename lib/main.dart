import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_login.dart';
import 'profile_edit.dart';
import '_app_feature_card.dart';
import '_app_drawer.dart';
import 'mod_bula_pro.dart';
import 'mod_scribe.dart';
import 'mod_medsearch.dart';
import 'settings.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  // You can perform any asynchronous initialization here if needed.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Exemplo de cores: primária azul, secundária laranja
    const primaryColor = Color(0xFF002FFF); // azul
    const secondaryColor = Color.fromARGB(255, 255, 0, 0); // laranja
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'FirstDoctor',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while waiting for auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, check profile and settings
          return const UserOnboardingWrapper();
        }
        
        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

class UserOnboardingWrapper extends StatelessWidget {
  const UserOnboardingWrapper({super.key});

  Future<Widget> _checkUserSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Scaffold(
          body: Center(
            child: Text('Usuário não autenticado', style: TextStyle(color: Colors.red)),
          ),
        );
      }

      // Verificar perfil
      final profileDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final profileData = profileDoc.data();
      
      if (profileData == null) {
        return const ProfileSetupWrapper();
      }
      
      // Verificar TODOS os campos obrigatórios do perfil
      final displayName = (profileData['display_name'] ?? '').toString().trim();
      final country = (profileData['country'] ?? '').toString().trim();
      final currency = (profileData['currency'] ?? '').toString().trim();
      final language = (profileData['language'] ?? '').toString().trim();
      
      final profileIncomplete = displayName.isEmpty || country.isEmpty || currency.isEmpty || language.isEmpty;
      
      if (profileIncomplete) {
        return const ProfileSetupWrapper();
      }

      // Verificar configurações
      final configDoc = await FirebaseFirestore.instance.collection('config').doc(user.uid).get();
      final configData = configDoc.data();
      
      if (configData == null) {
        return const SettingsSetupWrapper();
      }
      
      // Verificar TODOS os campos obrigatórios da configuração
      final scribeType = configData['scribetype'];
      final journals = configData['journals'] as List?;
      
      // Ambos os campos são obrigatórios
      final configIncomplete = scribeType == null || journals == null || journals.isEmpty;
      
      if (configIncomplete) {
        return const SettingsSetupWrapper();
      }

      // Tudo OK - mostrar home
      return const Home(title: 'FirstDoctor');
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao verificar configurações: $e',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkUserSetup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando configurações...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return snapshot.data ?? const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class ProfileSetupWrapper extends StatelessWidget {
  const ProfileSetupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Complete seu perfil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Para usar o aplicativo, você precisa completar seu perfil com informações básicas.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const EditProfilePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Completar Perfil'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSetupWrapper extends StatelessWidget {
  const SettingsSetupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Configure suas preferências',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Para usar o aplicativo, você precisa configurar suas preferências dos módulos.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Configurar Aplicativo'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['display_name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/soft-gradient-diagonal.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Fundo do cabeçalho
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/diagonal-gradient.webp'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Botão do menu
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Builder(
                            builder: (BuildContext context) {
                              return IconButton(
                                icon: const Icon(Icons.menu, color: Colors.black87),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Texto de boas-vindas
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'FirstDoctor',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${(_userName != null && _userName!.isNotEmpty) ? _userName : (user?.email ?? 'User')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 24, left: 0, right: 0, bottom: 16),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'Selecione uma função',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.white24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverMasonryGrid.count(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            itemBuilder: (context, index) {
                              final cards = [
                                AppFeatureCard(
                                  title: 'Scribe',
                                  subtitle: 'Seu assistente com prontuários',
                                  color: Colors.blue.shade50,
                                  icon: Icons.edit_document,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ScribePage()),
                                    );
                                  },
                                ),
                                AppFeatureCard(
                                  title: 'MedSearch',
                                  subtitle: 'Busca científica para profissionais de saúde',
                                  color: Colors.green.shade50,
                                  icon: Icons.search,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MedSearchPage()),
                                    );
                                  },
                                ),
                                AppFeatureCard(
                                  title: 'BulaPro',
                                  subtitle: 'Tudo que você precisa sobre medicações',
                                  color: Colors.deepPurple.shade50,
                                  icon: Icons.medication,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const BulaProPage()),
                                    );
                                  },
                                ),
                              ];
                              return cards[index];
                            },
                            childCount: 3,
                          ),
                        ],
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
