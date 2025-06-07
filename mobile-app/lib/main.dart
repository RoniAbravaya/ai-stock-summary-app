import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/mock_data_service.dart';
import 'services/language_service.dart';
import 'config/app_config.dart';
import 'screens/language_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'dart:async';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('📱 Background message received: ${message.messageId}');
  } catch (e) {
    print('⚠️ Background message handler error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    firebaseInitialized = true;

    // Set up background message handler only if Firebase is working
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      print('✅ Firebase messaging background handler set');
    } catch (e) {
      print('⚠️ Firebase messaging setup failed: $e');
    }

    // Initialize Firebase services
    await FirebaseService().initialize();
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('🔄 Running app without Firebase features...');
    firebaseInitialized = false;
  }

  // Initialize Language Service
  try {
    await LanguageService().initialize();
    print('✅ Language service initialized');
  } catch (e) {
    print('⚠️ Language service initialization failed: $e');
  }

  runApp(AIStockSummaryApp(firebaseEnabled: firebaseInitialized));
}

class AIStockSummaryApp extends StatefulWidget {
  const AIStockSummaryApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<AIStockSummaryApp> createState() => _AIStockSummaryAppState();
}

class _AIStockSummaryAppState extends State<AIStockSummaryApp> {
  final LanguageService _languageService = LanguageService();
  late StreamController<String> _languageStreamController;

  @override
  void initState() {
    super.initState();
    _languageStreamController = StreamController<String>.broadcast();
  }

  @override
  void dispose() {
    _languageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _languageStreamController.stream,
      initialData: _languageService.currentLanguage,
      builder: (context, snapshot) {
        return MaterialApp(
          title: _languageService.translate('app_name'),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(AppConfig.primaryBlue),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: AppTextStyles.fontFamily,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Color(AppConfig.primaryBlue),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryBlue),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(AppConfig.primaryBlue),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: AppTextStyles.fontFamily,
          ),
          debugShowCheckedModeBanner: AppConfig.isDevelopment,
          home: AuthWrapper(
            firebaseEnabled: widget.firebaseEnabled,
            onLanguageChanged: () {
              _languageStreamController.add(_languageService.currentLanguage);
            },
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.firebaseEnabled,
    required this.onLanguageChanged,
  });

  final bool firebaseEnabled;
  final VoidCallback onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      // Show login screen without Firebase authentication
      return LoginScreen(
        firebaseEnabled: firebaseEnabled,
        onLanguageChanged: onLanguageChanged,
      );
    }

    return StreamBuilder(
      stream: FirebaseService().auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return HomeScreen(
            firebaseEnabled: firebaseEnabled,
            onLanguageChanged: onLanguageChanged,
          );
        }

        return LoginScreen(
          firebaseEnabled: firebaseEnabled,
          onLanguageChanged: onLanguageChanged,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();

    return Scaffold(
      backgroundColor: Color(AppConfig.primaryBlue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              languageService.translate('app_name'),
              style: TextStyle(
                fontSize: AppTextStyles.headingLarge,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.firebaseEnabled,
    required this.onLanguageChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  final bool firebaseEnabled;
  final VoidCallback onLanguageChanged;
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _languageService = LanguageService();
  bool _isLoading = false;
  bool _isSignUpMode = false; // Toggle between sign-in and sign-up

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConfig.backgroundGray),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.trending_up,
                  size: 80,
                  color: Color(AppConfig.primaryBlue),
                ),
                const SizedBox(height: 20),
                Text(
                  _languageService.translate('app_name'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.headingLarge,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _languageService.translate('app_tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium,
                    color: Color(AppConfig.textLight),
                  ),
                ),
                const SizedBox(height: 16),

                // Mode indicator
                Text(
                  _isSignUpMode
                      ? _languageService.translate('auth_create_account')
                      : _languageService.translate('auth_welcome_back'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.headingSmall,
                    fontWeight: FontWeight.w600,
                    color: Color(AppConfig.primaryBlue),
                  ),
                ),

                // Show Firebase status
                if (!widget.firebaseEnabled) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Running in demo mode - Firebase features disabled',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: AppTextStyles.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Display Name field (only for sign-up)
                if (_isSignUpMode && widget.firebaseEnabled) ...[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: _languageService.translate('auth_full_name'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (_isSignUpMode && (value?.isEmpty ?? true)) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _languageService.translate('auth_email'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _languageService.translate('auth_password'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    if (_isSignUpMode && value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Confirm Password field (only for sign-up)
                if (_isSignUpMode && widget.firebaseEnabled) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _languageService.translate(
                        'auth_confirm_password',
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (_isSignUpMode && value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Main action button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleMainAction,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_getMainButtonText()),
                ),

                // Toggle between sign-in and sign-up
                if (widget.firebaseEnabled) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(
                      _isSignUpMode
                          ? _languageService.translate('auth_have_account')
                          : _languageService.translate('auth_no_account'),
                      style: TextStyle(color: Color(AppConfig.primaryBlue)),
                    ),
                  ),

                  // Social login options (only for sign-in)
                  if (!_isSignUpMode) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: Text(
                        _languageService.translate('auth_sign_in_google'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMainButtonText() {
    if (!widget.firebaseEnabled) {
      return 'Continue (Demo)';
    }
    return _isSignUpMode
        ? _languageService.translate('auth_sign_up')
        : _languageService.translate('auth_sign_in');
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _clearForm();
    });
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _displayNameController.clear();
  }

  Future<void> _handleMainAction() async {
    if (_isSignUpMode) {
      await _signUpWithEmail();
    } else {
      await _signInWithEmail();
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Check if widget is still mounted

    setState(() => _isLoading = true);

    try {
      if (widget.firebaseEnabled) {
        await FirebaseService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Demo mode - simulate login
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => HomeScreen(
                    firebaseEnabled: false,
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Check if widget is still mounted

    setState(() => _isLoading = true);

    try {
      if (widget.firebaseEnabled) {
        await FirebaseService().registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
        if (mounted) {
          _showSuccessSnackBar('Account created successfully! Welcome!');
        }
      } else {
        // Demo mode - simulate registration
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _showSuccessSnackBar('Demo account created!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => HomeScreen(
                    firebaseEnabled: false,
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (widget.firebaseEnabled) {
        await FirebaseService().signInWithGoogle();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(AppConfig.primaryRed),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(AppConfig.primaryGreen),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.firebaseEnabled,
    required this.onLanguageChanged,
  });

  final bool firebaseEnabled;
  final VoidCallback onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseEnabled) {
      _checkAdminStatus();
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      DocumentSnapshot? userDoc = await FirebaseService().getUserData();
      if (userDoc != null && userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            _isAdmin = userData['role'] == 'admin';
          });
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  List<Widget> get _screens => [
    DashboardScreen(firebaseEnabled: widget.firebaseEnabled),
    FavoritesScreen(firebaseEnabled: widget.firebaseEnabled),
    NewsScreen(firebaseEnabled: widget.firebaseEnabled),
    ProfileScreen(
      firebaseEnabled: widget.firebaseEnabled,
      onLanguageChanged: widget.onLanguageChanged,
    ),
    if (_isAdmin) AdminScreen(firebaseEnabled: widget.firebaseEnabled),
  ];

  List<BottomNavigationBarItem> get _navItems {
    final languageService = LanguageService();
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: languageService.translate('nav_dashboard'),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: languageService.translate('nav_favorites'),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.article),
        label: languageService.translate('nav_news'),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: languageService.translate('nav_profile'),
      ),
      if (_isAdmin)
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: languageService.translate('nav_admin'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(AppConfig.primaryBlue),
        unselectedItemColor: Color(AppConfig.textLight),
        items: _navItems,
      ),
    );
  }
}

// Dashboard Screen - Trending Stocks
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConfig.appName} - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (firebaseEnabled) {
                await FirebaseService().signOut();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (_) => LoginScreen(
                          firebaseEnabled: false,
                          onLanguageChanged: () {},
                        ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: firebaseEnabled ? _buildFirebaseContent() : _buildMockContent(),
    );
  }

  Widget _buildFirebaseContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMockContent(); // Fallback to mock data
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMockContent(); // Fallback to mock data
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final stockDoc = snapshot.data!.docs[index];
            final stock = stockDoc.data() as Map<String, dynamic>;

            return _buildStockCard(context, stock, stockDoc.id);
          },
        );
      },
    );
  }

  Widget _buildMockContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MockDataService().getStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Unable to load stocks', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final stock = snapshot.data![index];
            return _buildStockCard(context, stock, stock['symbol']);
          },
        );
      },
    );
  }

  Widget _buildStockCard(
    BuildContext context,
    Map<String, dynamic> stock,
    String stockId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(AppConfig.primaryBlue),
          child: Text(
            stock['symbol']?.substring(0, 2) ?? '??',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          stock['symbol'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(stock['name'] ?? 'No name available'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${stock['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${stock['change'] >= 0 ? '+' : ''}${stock['change']?.toStringAsFixed(2) ?? '0.00'}%',
              style: TextStyle(
                color: (stock['change'] ?? 0) >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          // Add to favorites
          _addToFavorites(context, stockId);
        },
      ),
    );
  }

  void _addToFavorites(BuildContext context, String stockId) async {
    try {
      if (firebaseEnabled) {
        await FirebaseService().addToFavorites(stockId);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to favorites!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}

// Favorites Screen - AI Summary and Generate Button
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: firebaseEnabled ? _buildFirebaseContent() : _buildMockContent(),
    );
  }

  Widget _buildFirebaseContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getFavoriteStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMockContent(); // Fallback to mock data
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMockContent(); // Fallback to mock data
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final favoriteDoc = snapshot.data!.docs[index];
            final favorite = favoriteDoc.data() as Map<String, dynamic>;
            final stockId = favorite['stockId'];

            return _buildFavoriteCard(context, stockId);
          },
        );
      },
    );
  }

  Widget _buildMockContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MockDataService().getFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No favorites yet', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Add stocks from Dashboard to generate AI summaries'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final favorite = snapshot.data![index];
            return _buildFavoriteCard(context, favorite['stockId']);
          },
        );
      },
    );
  }

  Widget _buildFavoriteCard(BuildContext context, String stockId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stockId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromFavorites(context, stockId),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced spacing
            ElevatedButton.icon(
              onPressed: () => _generateAISummary(context, stockId),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate AI Summary'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryContent(stockId),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(String stockId) {
    if (firebaseEnabled) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseService().getStockSummary(stockId),
        builder: (context, summarySnapshot) {
          if (summarySnapshot.hasData && summarySnapshot.data!.exists) {
            try {
              final summary =
                  summarySnapshot.data!.data() as Map<String, dynamic>?;
              if (summary != null) {
                return _buildSummaryContainer(
                  summary['content'] ?? 'No summary available',
                );
              }
            } catch (e) {
              print('❌ Error parsing summary data: $e');
            }
          }
          return _buildMockSummaryContent(stockId);
        },
      );
    } else {
      return _buildMockSummaryContent(stockId);
    }
  }

  Widget _buildMockSummaryContent(String stockId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: MockDataService().getSummary(stockId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildSummaryContainer(snapshot.data!['content']);
        }
        return const Text('No summary generated yet');
      },
    );
  }

  Widget _buildSummaryContainer(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Summary:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  void _removeFromFavorites(BuildContext context, String stockId) async {
    try {
      if (firebaseEnabled) {
        await FirebaseService().removeFromFavorites(stockId);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _generateAISummary(BuildContext context, String stockId) async {
    // TODO: Implement AI summary generation via backend API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Summary generation coming soon...')),
    );
  }
}

// News Screen - Latest Financial News
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial News')),
      body: firebaseEnabled ? _buildFirebaseContent() : _buildMockContent(),
    );
  }

  Widget _buildFirebaseContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMockContent(); // Fallback to mock data
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMockContent(); // Fallback to mock data
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final newsDoc = snapshot.data!.docs[index];
            final news = newsDoc.data() as Map<String, dynamic>;

            return _buildNewsCard(news);
          },
        );
      },
    );
  }

  Widget _buildMockContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MockDataService().getNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Unable to load news', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final news = snapshot.data![index];
            return _buildNewsCard(news);
          },
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news['title'] ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              news['description'] ?? 'No description available',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  news['source'] ?? 'Unknown source',
                  style: TextStyle(
                    color: Color(AppConfig.primaryBlue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(news['publishedAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}

// Profile Screen - Usage Stats, Subscription Status, Settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.firebaseEnabled,
    required this.onLanguageChanged,
  });

  final bool firebaseEnabled;
  final VoidCallback onLanguageChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService().translate('profile_title'))),
      body:
          widget.firebaseEnabled
              ? _buildFirebaseContent()
              : _buildMockContent(),
    );
  }

  Widget _buildFirebaseContent() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseService().firestore
              .collection('users')
              .doc(FirebaseService().currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !FirebaseService().isFirestoreAvailable) {
          return _buildMockContent(); // Fallback to mock data
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildMockContent(); // Fallback to mock data
        }

        try {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return _buildMockContent(); // Fallback to mock data
          }

          final user = FirebaseService().currentUser!;

          return _buildProfileContent(
            context,
            userData,
            user.email,
            user.displayName,
            user.photoURL,
          );
        } catch (e) {
          print('❌ Error parsing user data: $e');
          return _buildMockContent(); // Fallback to mock data
        }
      },
    );
  }

  Widget _buildMockContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: MockDataService().getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Unable to load profile', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        final userData = snapshot.data!;
        return _buildProfileContent(
          context,
          userData,
          userData['email'],
          userData['displayName'],
          userData['photoURL'],
        );
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic> userData,
    String? email,
    String? displayName,
    String? photoURL,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(AppConfig.primaryBlue),
                  backgroundImage:
                      photoURL != null ? NetworkImage(photoURL) : null,
                  child:
                      photoURL == null
                          ? Text(
                            displayName?.substring(0, 1) ??
                                email?.substring(0, 1) ??
                                '?',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email ?? LanguageService().translate('profile_no_email'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        userData['role'] == 'admin'
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    userData['role'] == 'admin'
                        ? LanguageService().translate('profile_admin')
                        : LanguageService().translate('profile_user'),
                    style: TextStyle(
                      color:
                          userData['role'] == 'admin'
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Usage Statistics Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Color(AppConfig.primaryBlue)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LanguageService().translate('profile_usage_stats'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  LanguageService().translate('profile_subscription_type'),
                  _getSubscriptionDisplay(userData['subscriptionType']),
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  LanguageService().translate('profile_summaries_used'),
                  '${userData['summariesUsed'] ?? 0}/${userData['summariesLimit'] ?? 10}',
                ),
                const SizedBox(height: 12),
                // Progress bar for summary usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService().translate('profile_monthly_usage'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value:
                          (userData['summariesUsed'] ?? 0) /
                          (userData['summariesLimit'] ?? 10),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(
                          userData['summariesUsed'] ?? 0,
                          userData['summariesLimit'] ?? 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUsageMessage(
                        userData['summariesUsed'] ?? 0,
                        userData['summariesLimit'] ?? 10,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subscription Management Card
        if (userData['subscriptionType'] != 'premium') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageService().translate('premium_upgrade'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(LanguageService().translate('premium_unlock')),
                  const SizedBox(height: 4),
                  Text(
                    LanguageService().translate('premium_features'),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _upgradeToPremium(context),
                    icon: const Icon(Icons.star),
                    label: Text(LanguageService().translate('premium_price')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Free Summary Options Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_collection,
                      color: Color(AppConfig.primaryGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LanguageService().translate('rewards_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(AppConfig.primaryGreen).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Color(AppConfig.primaryGreen),
                    ),
                  ),
                  title: Text(
                    LanguageService().translate('rewards_watch_ad'),
                    style: TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    LanguageService().translate('rewards_get_summary'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ElevatedButton(
                      onPressed: () => _watchRewardedAd(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConfig.primaryGreen),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(LanguageService().translate('rewards_watch')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Settings Card
        Card(
          child: Column(
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications,
                title: LanguageService().translate('settings_notifications'),
                subtitle: LanguageService().translate(
                  'settings_notifications_desc',
                ),
                onTap: () => _openNotificationSettings(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: LanguageService().translate('settings_language'),
                subtitle: LanguageService().translate('settings_language_desc'),
                onTap: () => _openLanguageSettings(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: LanguageService().translate('settings_help'),
                subtitle: LanguageService().translate('settings_help_desc'),
                onTap: () => _openHelpSupport(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: LanguageService().translate('settings_privacy'),
                subtitle: LanguageService().translate('settings_privacy_desc'),
                onTap: () => _openPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.logout,
                title: LanguageService().translate('auth_sign_out'),
                subtitle:
                    widget.firebaseEnabled
                        ? LanguageService().translate('settings_sign_out_desc')
                        : LanguageService().translate('settings_demo_sign_out'),
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getSubscriptionDisplay(String? subscriptionType) {
    switch (subscriptionType) {
      case 'premium':
        return LanguageService().translate('profile_premium');
      case 'free':
      default:
        return LanguageService().translate('profile_free');
    }
  }

  Color _getProgressColor(int used, int limit) {
    final ratio = used / limit;
    if (ratio >= 0.9) return Colors.red;
    if (ratio >= 0.7) return Colors.orange;
    return Color(AppConfig.primaryGreen);
  }

  String _getUsageMessage(int used, int limit) {
    final remaining = limit - used;
    if (remaining <= 0)
      return LanguageService().translate('usage_no_remaining');
    if (remaining == 1)
      return LanguageService().translate('usage_remaining_singular');
    return LanguageService().translateWithParams('usage_remaining', {
      'count': remaining.toString(),
    });
  }

  void _upgradeToPremium(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LanguageService().translate('premium_upgrade')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LanguageService().translate('premium_features_include')),
                SizedBox(height: 8),
                Text(LanguageService().translate('premium_monthly_summaries')),
                Text(LanguageService().translate('premium_priority_support')),
                Text(LanguageService().translate('premium_advanced_analytics')),
                Text(LanguageService().translate('premium_ad_free')),
                SizedBox(height: 16),
                Text(LanguageService().translate('premium_price_info')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(LanguageService().translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageService().translate('premium_coming_soon'),
                      ),
                    ),
                  );
                },
                child: Text(LanguageService().translate('premium_subscribe')),
              ),
            ],
          ),
    );
  }

  void _watchRewardedAd(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LanguageService().translate('rewards_watch_ad')),
            content: Text(LanguageService().translate('rewards_watch_video')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(LanguageService().translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement rewarded ad functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageService().translate('rewards_coming_soon'),
                      ),
                    ),
                  );
                },
                child: Text(LanguageService().translate('watch_ad')),
              ),
            ],
          ),
    );
  }

  void _openNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => NotificationSettingsScreen(
              firebaseEnabled: widget.firebaseEnabled,
            ),
      ),
    );
  }

  void _openLanguageSettings(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
    );

    // If language was changed, trigger the callback
    if (result == true && widget.onLanguageChanged != null) {
      widget.onLanguageChanged!();
    }
  }

  void _openHelpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageService().translate('settings_help_coming')),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageService().translate('settings_privacy_coming')),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              LanguageService().translate('settings_sign_out_confirm'),
            ),
            content: Text(
              widget.firebaseEnabled
                  ? LanguageService().translate('settings_sign_out_question')
                  : LanguageService().translate('settings_return_login'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(LanguageService().translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    if (widget.firebaseEnabled) {
                      await FirebaseService().signOut();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (_) => LoginScreen(
                                firebaseEnabled: false,
                                onLanguageChanged: () {},
                              ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageService().translateWithParams(
                            'error_sign_out',
                            {'error': e.toString()},
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(LanguageService().translate('auth_sign_out')),
              ),
            ],
          ),
    );
  }
}

// Admin Screen - Comprehensive tabbed admin panel
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotificationsTab(firebaseEnabled: widget.firebaseEnabled),
          UserManagementTab(firebaseEnabled: widget.firebaseEnabled),
          StatisticsTab(firebaseEnabled: widget.firebaseEnabled),
        ],
      ),
    );
  }
}

// Notifications Tab - Push notification management with audience targeting
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key, required this.firebaseEnabled});
  final bool firebaseEnabled;

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedAudience = 'all_users';
  final List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSending = false;

  final Map<String, String> _audienceOptions = {
    'all_users': 'All Users',
    'free_users': 'Free Users',
    'premium_users': 'Premium Users',
    'specific_users': 'Specific Users',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Notification Content Card
              _buildNotificationContentCard(),
              const SizedBox(height: 16),

              // Audience Selection Card
              _buildAudienceSelectionCard(),
              const SizedBox(height: 20),

              // Send Button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Push Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send targeted notifications to your users',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Notification Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title Field
            _buildInputField(
              controller: _titleController,
              label: 'Notification Title',
              hint: 'Enter a compelling title...',
              icon: Icons.title,
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Message Field
            _buildInputField(
              controller: _messageController,
              label: 'Message Content',
              hint: 'Write your notification message...',
              icon: Icons.message,
              maxLines: 4,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Target Audience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Audience Selector
            _buildAudienceSelector(),

            // User Selection (if specific users selected)
            if (_selectedAudience == 'specific_users') ...[
              const SizedBox(height: 20),
              _buildUserSelection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children:
            _audienceOptions.entries.map((entry) {
              final isSelected = _selectedAudience == entry.key;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAudience = entry.key;
                    if (entry.key != 'specific_users') {
                      _selectedUsers.clear();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.shade50 : Colors.transparent,
                    border: Border(
                      bottom:
                          entry.key != _audienceOptions.keys.last
                              ? BorderSide(color: Colors.grey.shade200)
                              : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getAudienceIcon(entry.key),
                        color:
                            isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _isSending
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [Colors.green.shade500, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isSending ? Colors.grey : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendNotification,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSending)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.send, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              _isSending ? 'Sending Notification...' : 'Send Notification',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAudienceIcon(String audienceType) {
    switch (audienceType) {
      case 'free_users':
        return Icons.people_outline;
      case 'premium_users':
        return Icons.workspace_premium;
      case 'specific_users':
        return Icons.person_pin;
      default:
        return Icons.public;
    }
  }

  Widget _buildUserSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Specific Users',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by email...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade600),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onChanged: _searchUsers,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _loadAllUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Load All',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Selected Users
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Users (${_selectedUsers.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                (user['email'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['email'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    user['role'] ?? 'user',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade400,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedUsers.removeAt(index);
                                });
                              },
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        // Search Results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search Results (${_searchResults.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _selectAllSearchResults,
                        icon: Icon(
                          Icons.select_all,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        label: Text(
                          'Select All',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUsers.any(
                        (selected) => selected['uid'] == user['uid'],
                      );
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!isSelected) {
                                  _selectedUsers.add(user);
                                }
                              } else {
                                _selectedUsers.removeWhere(
                                  (selected) => selected['uid'] == user['uid'],
                                );
                              }
                            });
                          },
                          title: Text(
                            user['email'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${user['role'] ?? 'user'} • ${user['subscriptionType'] ?? 'free'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (user['email'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          activeColor: Colors.blue.shade600,
                          checkColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _searchUsers(String query) async {
    if (!widget.firebaseEnabled) return;

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await FirebaseService().searchUsersByEmail(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackBar('Error searching users: ${e.toString()}');
    }
  }

  void _loadAllUsers() async {
    if (!widget.firebaseEnabled) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await FirebaseService().getAllUsers();
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _searchController.clear();
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackBar('Error loading users: ${e.toString()}');
    }
  }

  void _selectAllSearchResults() {
    setState(() {
      for (final user in _searchResults) {
        final isAlreadySelected = _selectedUsers.any(
          (selected) => selected['uid'] == user['uid'],
        );
        if (!isAlreadySelected) {
          _selectedUsers.add(user);
        }
      }
    });
  }

  void _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter both title and message');
      return;
    }

    if (_selectedAudience == 'specific_users' && _selectedUsers.isEmpty) {
      _showErrorSnackBar('Please select at least one user');
      return;
    }

    if (!widget.firebaseEnabled) {
      _showSuccessSnackBar('Demo mode - Notification would be sent');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      switch (_selectedAudience) {
        case 'all_users':
          await FirebaseService().sendNotificationToAllUsers(title, message);
          break;
        case 'free_users':
          await FirebaseService().sendNotificationToUserType(
            'free',
            title,
            message,
          );
          break;
        case 'premium_users':
          await FirebaseService().sendNotificationToUserType(
            'premium',
            title,
            message,
          );
          break;
        case 'specific_users':
          for (final user in _selectedUsers) {
            await FirebaseService().sendNotificationToUser(
              user['email'],
              title,
              message,
            );
          }
          break;
      }

      _showSuccessSnackBar('Notification sent successfully!');
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedUsers.clear();
        _searchResults.clear();
        _selectedAudience = 'all_users';
      });
    } catch (e) {
      _showErrorSnackBar('Error sending notification: ${e.toString()}');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// User Management Tab - Admin promotion with search and browse
class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key, required this.firebaseEnabled});
  final bool firebaseEnabled;

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  int _currentPage = 0;
  final int _usersPerPage = 10; // Reduced for better mobile experience

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Search Section
              _buildSearchSection(),

              // Users List
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_alt, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage roles and permissions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_users.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Search Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar and reload button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: Icon(
                      Icons.search_outlined,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: _filterUsers,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _isLoading
                          ? Colors.grey.shade400
                          : Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loadUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 16,
                          ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                'Total Users',
                '${_users.length}',
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                'Showing',
                _getDisplayedUsersInfo(),
                Icons.visibility,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'User List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (_filteredUsers.isNotEmpty)
                  Text(
                    'Page ${_currentPage + 1} of ${(_filteredUsers.length / _usersPerPage).ceil()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : ListView.builder(
                      itemCount: _getDisplayedUsers().length,
                      itemBuilder: (context, index) {
                        final user = _getDisplayedUsers()[index];
                        return _buildUserTile(user, index);
                      },
                    ),
          ),

          // Pagination
          if (_filteredUsers.length > _usersPerPage) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            child: const Text('Previous'),
          ),
          Text(
            'Page ${_currentPage + 1} of ${(_filteredUsers.length / _usersPerPage).ceil()}',
          ),
          ElevatedButton(
            onPressed:
                (_currentPage + 1) * _usersPerPage < _filteredUsers.length
                    ? _nextPage
                    : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    setState(() {
      _currentPage = (_currentPage - 1).clamp(
        0,
        (_filteredUsers.length / _usersPerPage).ceil() - 1,
      );
    });
  }

  void _nextPage() {
    setState(() {
      _currentPage = (_currentPage + 1).clamp(
        0,
        (_filteredUsers.length / _usersPerPage).ceil() - 1,
      );
    });
  }

  List<Map<String, dynamic>> _getDisplayedUsers() {
    final startIndex = _currentPage * _usersPerPage;
    final endIndex = (startIndex + _usersPerPage).clamp(
      0,
      _filteredUsers.length,
    );
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  String _getDisplayedUsersInfo() {
    if (_filteredUsers.isEmpty) return '0 users';
    final startIndex = _currentPage * _usersPerPage + 1;
    final endIndex = ((_currentPage + 1) * _usersPerPage).clamp(
      0,
      _filteredUsers.length,
    );
    return '$startIndex-$endIndex of ${_filteredUsers.length}';
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final isAdmin = user['role'] == 'admin';
    final canPromote = !isAdmin && widget.firebaseEnabled;
    final currentUserEmail = FirebaseService().auth.currentUser?.email;
    final canRevoke =
        isAdmin && widget.firebaseEnabled && user['email'] != currentUserEmail;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // User Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'] ?? 'Unknown Email',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isAdmin
                                      ? Colors.red.shade50
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['role'] ?? 'user',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isAdmin
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['subscriptionType'] ?? 'free',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Action Buttons - Responsive Row
            Row(
              children: [
                if (canPromote) ...[
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            _isProcessing ? null : () => _promoteToAdmin(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Promote',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ] else if (canRevoke) ...[
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            _isProcessing ? null : () => _revokeAdminRole(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Revoke',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isAdmin ? Colors.red.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              isAdmin
                                  ? Colors.red.shade200
                                  : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            size: 14,
                            color:
                                isAdmin
                                    ? Colors.red.shade600
                                    : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdmin ? 'Admin' : 'User',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  isAdmin
                                      ? Colors.red.shade600
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () => _showUserOptions(user),
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserOptions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                  ),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.pop(context);
                    _showUserDetails(user);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email'] ?? 'Unknown'}'),
                Text('Role: ${user['role'] ?? 'user'}'),
                Text('Subscription: ${user['subscriptionType'] ?? 'free'}'),
                Text('Summaries Used: ${user['summariesUsed'] ?? 0}'),
                Text('Summaries Limit: ${user['summariesLimit'] ?? 10}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _loadUsers() async {
    if (!widget.firebaseEnabled) {
      setState(() {
        _users = [
          {
            'email': 'demo@example.com',
            'role': 'user',
            'subscriptionType': 'free',
            'summariesUsed': 3,
            'summariesLimit': 10,
          },
        ];
        _filteredUsers = _users;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final users = await FirebaseService().getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading users: ${e.toString()}');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers =
          query.trim().isEmpty
              ? _users
              : _users
                  .where(
                    (user) =>
                        user['email']?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false,
                  )
                  .toList();
      _currentPage = 0;
    });
  }

  void _promoteToAdmin(Map<String, dynamic> user) async {
    final confirmed = await _showConfirmDialog(
      'Promote to Admin',
      'Are you sure you want to promote ${user['email']} to admin?',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await FirebaseService().grantAdminRole(user['email']);
      _showSuccessSnackBar('User promoted to admin successfully!');
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('Error promoting user: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _revokeAdminRole(Map<String, dynamic> user) async {
    final confirmed = await _showConfirmDialog(
      'Revoke Admin Role',
      'Are you sure you want to revoke the admin role from ${user['email']}?',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await FirebaseService().revokeAdminRole(user['email']);
      _showSuccessSnackBar('Admin role revoked successfully!');
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('Error revoking admin role: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Statistics Tab - Real-time system statistics dashboard
class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key, required this.firebaseEnabled});
  final bool firebaseEnabled;

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    try {
      if (widget.firebaseEnabled) {
        final stats = await FirebaseService().getSystemStats();
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _stats = {
              'totalUsers': 0,
              'activeSubscriptions': 0,
              'summariesGenerated': 0,
              'systemStatus': 'Offline Mode',
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Statistics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text('Total Users: ${_stats['totalUsers'] ?? 0}'),
                            Text(
                              'Premium Users: ${_stats['activeSubscriptions'] ?? 0}',
                            ),
                            Text(
                              'Summaries Generated: ${_stats['summariesGenerated'] ?? 0}',
                            ),
                            Text(
                              'System Status: ${_stats['systemStatus'] ?? 'Unknown'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to initialize the app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Please check your Firebase configuration'),
            ],
          ),
        ),
      ),
    );
  }
}
