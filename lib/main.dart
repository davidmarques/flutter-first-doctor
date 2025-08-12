import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_login.dart';
import 'profile_edit.dart';
import '_app_feature_card.dart';
import '_app_drawer.dart';
import 'mod_bula_pro.dart';
import 'mod_scribe.dart';
import 'mod_medsearch.dart';
import 'mod_medcalc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI overlay style for edge-to-edge support
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
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

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (!userDoc.exists) {
        return const EditProfilePage();
      }

      bool needsSetup = false;
      
      // Check if user has incomplete profile data
      if (userData == null ||
          userData['name']?.toString().trim().isEmpty == true ||
          userData['country']?.toString().trim().isEmpty == true ||
          userData['specialty']?.toString().trim().isEmpty == true) {
        needsSetup = true;
      }

      if (needsSetup) {
        return const EditProfilePage();
      }

      // User is properly set up, go to main dashboard
      return const Dashboard();
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao verificar configuração do usuário: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('Erro ao carregar dados do usuário', style: TextStyle(color: Colors.red)),
            ),
          );
        }
        
        return snapshot.data!;
      },
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/diagonal-gradient.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          children: [
            // Cabeçalho fixo - toca o topo da tela como mod_bula_pro.dart
            Container(
              height: 120,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
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
                            color: Colors.black.withValues(alpha: 0.1),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Área de conteúdo com background soft-gradient-diagonal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/soft-gradient-diagonal.webp'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  top: false, // Não adiciona padding no topo para o header tocar a tela
                  child: Padding(
                    padding: const EdgeInsets.all(24.0), // Padding interno
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 16),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Selecione uma função',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                            final cards = [
                              AppFeatureCard(
                                title: 'Scribe',
                                subtitle: 'Transcrição médica inteligente',
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
                                subtitle: 'Busca inteligente de medicamentos',
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
                              AppFeatureCard(
                                title: 'MedCalc',
                                subtitle: 'Calculadoras médicas avançadas',
                                color: Colors.orange.shade50,
                                icon: Icons.calculate,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MedCalcPage()),
                                  );
                                },
                              ),
                            ];
                            return cards[index];
                          },
                          childCount: 4,
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
