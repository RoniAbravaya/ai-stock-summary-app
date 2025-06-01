import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/mock_data_service.dart';
import 'config/app_config.dart';

// Top-level function to handle background messages
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

  runApp(AIStockSummaryApp(firebaseEnabled: firebaseInitialized));
}

class AIStockSummaryApp extends StatelessWidget {
  const AIStockSummaryApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
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
      home: AuthWrapper(firebaseEnabled: firebaseEnabled),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      // Show login screen without Firebase authentication
      return LoginScreen(firebaseEnabled: firebaseEnabled);
    }

    return StreamBuilder(
      stream: FirebaseService().auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return HomeScreen(firebaseEnabled: firebaseEnabled);
        }

        return LoginScreen(firebaseEnabled: firebaseEnabled);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConfig.primaryBlue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              AppConfig.appName,
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
  const LoginScreen({super.key, required this.firebaseEnabled});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  final bool firebaseEnabled;
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
                  AppConfig.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.headingLarge,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Stock Summaries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium,
                    color: Color(AppConfig.textLight),
                  ),
                ),
                const SizedBox(height: 16),

                // Mode indicator
                Text(
                  _isSignUpMode ? 'Create Account' : 'Welcome Back',
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
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
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
                  decoration: const InputDecoration(
                    labelText: 'Email',
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
                  decoration: const InputDecoration(
                    labelText: 'Password',
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
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
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
                          ? 'Already have an account? Sign In'
                          : 'Don\'t have an account? Sign Up',
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
                      label: const Text('Sign in with Google'),
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
    return _isSignUpMode ? 'Create Account' : 'Sign In';
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
              builder: (_) => HomeScreen(firebaseEnabled: false),
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
              builder: (_) => HomeScreen(firebaseEnabled: false),
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
  const HomeScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

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
    ProfileScreen(firebaseEnabled: widget.firebaseEnabled),
    if (_isAdmin) AdminScreen(firebaseEnabled: widget.firebaseEnabled),
  ];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    if (_isAdmin)
      const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ),
  ];

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
                    builder: (_) => LoginScreen(firebaseEnabled: false),
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
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: firebaseEnabled ? _buildFirebaseContent() : _buildMockContent(),
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
                  email ?? 'No email',
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
                    userData['role'] == 'admin' ? 'Admin' : 'User',
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
                    const Text(
                      'Usage Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Subscription Type',
                  _getSubscriptionDisplay(userData['subscriptionType']),
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'AI Summaries Used',
                  '${userData['summariesUsed'] ?? 0}/${userData['summariesLimit'] ?? 10}',
                ),
                const SizedBox(height: 12),
                // Progress bar for summary usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Summary Usage',
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
                      const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock unlimited AI summaries and premium features',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 100 AI summaries per month\n• Priority support\n• Advanced analytics\n• No ads',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _upgradeToPremium(context),
                    icon: const Icon(Icons.star),
                    label: const Text('Upgrade Now - \$9.99/month'),
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
                    const Text(
                      'Get More Summaries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                  title: const Text(
                    'Watch Rewarded Ad',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Get +1 summary instantly'),
                  trailing: ElevatedButton(
                    onPressed: () => _watchRewardedAd(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryGreen),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Watch'),
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
                title: 'Notifications',
                subtitle: 'Manage push notifications',
                onTap: () => _openNotificationSettings(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Change app language',
                onTap: () => _openLanguageSettings(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () => _openHelpSupport(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () => _openPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context: context,
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle:
                    firebaseEnabled
                        ? 'Sign out of your account'
                        : 'Return to login',
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
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
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
        return 'Premium';
      case 'free':
      default:
        return 'Free';
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
    if (remaining <= 0) return 'No summaries remaining this month';
    if (remaining == 1) return '1 summary remaining this month';
    return '$remaining summaries remaining this month';
  }

  void _upgradeToPremium(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Upgrade to Premium'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium features include:'),
                SizedBox(height: 8),
                Text('• 100 AI summaries per month'),
                Text('• Priority support'),
                Text('• Advanced analytics'),
                Text('• Ad-free experience'),
                SizedBox(height: 16),
                Text('Price: \$9.99/month'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium subscription coming soon...'),
                    ),
                  );
                },
                child: const Text('Subscribe'),
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
            title: const Text('Watch Rewarded Ad'),
            content: const Text(
              'Watch a short video ad to get +1 summary instantly.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement rewarded ad functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rewarded ads coming soon...'),
                    ),
                  );
                },
                child: const Text('Watch Ad'),
              ),
            ],
          ),
    );
  }

  void _openNotificationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon...')),
    );
  }

  void _openLanguageSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language settings coming soon...')),
    );
  }

  void _openHelpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & Support coming soon...')),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy coming soon...')),
    );
  }

  void _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: Text(
              firebaseEnabled
                  ? 'Are you sure you want to sign out of your account?'
                  : 'Return to login screen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    if (firebaseEnabled) {
                      await FirebaseService().signOut();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(firebaseEnabled: false),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
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
  List<Map<String, dynamic>> _selectedUsers = [];
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12), // Reduced from 16 to 12
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Content Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Content',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Notification Title',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Notification Message',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.message),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Audience Selection Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Audience',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedAudience,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.group),
                            ),
                            items:
                                _audienceOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAudience = value!;
                                if (value != 'specific_users') {
                                  _selectedUsers.clear();
                                }
                              });
                            },
                          ),

                          // Specific Users Selection
                          if (_selectedAudience == 'specific_users') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      labelText: 'Search Users',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: _searchUsers,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _loadAllUsers,
                                  child: const Text('Load All'),
                                ),
                              ],
                            ),

                            // Selected Users
                            if (_selectedUsers.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Selected Users (${_selectedUsers.length})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  itemCount: _selectedUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = _selectedUsers[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(user['email'] ?? 'Unknown'),
                                      subtitle: Text(user['role'] ?? 'user'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () {
                                          setState(() {
                                            _selectedUsers.removeAt(index);
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],

                            // Search Results
                            if (_searchResults.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                height:
                                    200, // Constrained height for search results
                                child: Card(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Search Results (${_searchResults.length})',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed:
                                                  _selectAllSearchResults,
                                              child: const Text('Select All'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: _searchResults.length,
                                          itemBuilder: (context, index) {
                                            final user = _searchResults[index];
                                            final isSelected = _selectedUsers
                                                .any(
                                                  (selected) =>
                                                      selected['uid'] ==
                                                      user['uid'],
                                                );
                                            return CheckboxListTile(
                                              title: Text(
                                                user['email'] ?? 'Unknown',
                                              ),
                                              subtitle: Text(
                                                '${user['role'] ?? 'user'} • ${user['subscriptionType'] ?? 'free'}',
                                              ),
                                              value: isSelected,
                                              onChanged: (checked) {
                                                setState(() {
                                                  if (checked == true) {
                                                    if (!isSelected) {
                                                      _selectedUsers.add(user);
                                                    }
                                                  } else {
                                                    _selectedUsers.removeWhere(
                                                      (selected) =>
                                                          selected['uid'] ==
                                                          user['uid'],
                                                    );
                                                  }
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Send Button (always at bottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Reduced from 16
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon:
                          _isSending
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.send),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Notification',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
  final int _usersPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: _filterUsers,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loadUsers,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Reload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Total Users: ${_users.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        'Showing: ${_getDisplayedUsersInfo()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: Card(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'User Management',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (_filteredUsers.isNotEmpty)
                          Text(
                            'Page ${_currentPage + 1} of ${(_filteredUsers.length / _usersPerPage).ceil()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),

                  // Users List
                  Expanded(
                    child:
                        _filteredUsers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isLoading
                                        ? 'Loading users...'
                                        : 'No users found',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _getDisplayedUsers().length,
                              itemBuilder: (context, index) {
                                final user = _getDisplayedUsers()[index];
                                return _buildUserTile(user);
                              },
                            ),
                  ),

                  // Pagination
                  if (_filteredUsers.length > _usersPerPage)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
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
                                (_currentPage + 1) * _usersPerPage <
                                        _filteredUsers.length
                                    ? _nextPage
                                    : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final canPromote = !isAdmin && widget.firebaseEnabled;
    final canRevoke =
        isAdmin &&
        widget.firebaseEnabled &&
        user['email'] != FirebaseService().auth.currentUser?.email;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
        child: Icon(
          isAdmin ? Icons.admin_panel_settings : Icons.person,
          color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
        ),
      ),
      title: Text(user['email'] ?? 'Unknown Email'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Role: ${user['role'] ?? 'user'}'),
              if (user['email'] ==
                  FirebaseService().auth.currentUser?.email) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'You',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            'Subscription: ${user['subscriptionType'] ?? 'free'} • '
            'Summaries: ${user['summariesUsed'] ?? 0}/${user['summariesLimit'] ?? 10}',
          ),
        ],
      ),
      trailing:
          canPromote
              ? ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _promoteToAdmin(user),
                icon: const Icon(Icons.admin_panel_settings, size: 16),
                label: const Text('Promote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
              : canRevoke
              ? ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _revokeAdminRole(user),
                icon: const Icon(Icons.person_remove, size: 16),
                label: const Text('Revoke'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              )
              : isAdmin
              ? Chip(
                label: Text(
                  user['email'] == FirebaseService().auth.currentUser?.email
                      ? 'Admin (You)'
                      : 'Admin',
                ),
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade700),
              )
              : null,
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

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await FirebaseService().getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading users: ${e.toString()}');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers =
            _users
                .where(
                  (user) =>
                      user['email']?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false,
                )
                .toList();
      }
      _currentPage = 0;
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

  void _promoteToAdmin(Map<String, dynamic> user) async {
    final confirmed = await _showConfirmDialog(
      'Promote to Admin',
      'Are you sure you want to promote ${user['email']} to admin?\n\n'
          'This will grant them full administrative privileges.',
    );

    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseService().grantAdminRole(user['email']);
      _showSuccessSnackBar('User promoted to admin successfully!');
      _loadUsers(); // Reload to show updated role
    } catch (e) {
      _showErrorSnackBar('Error promoting user: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _revokeAdminRole(Map<String, dynamic> user) async {
    final confirmed = await _showConfirmDialog(
      'Revoke Admin Role',
      'Are you sure you want to revoke the admin role from ${user['email']}?\n\n'
          'This will remove their administrative privileges.',
    );

    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseService().revokeAdminRole(user['email']);
      _showSuccessSnackBar('Admin role revoked successfully!');
      _loadUsers(); // Reload to show updated role
    } catch (e) {
      _showErrorSnackBar('Error revoking admin role: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
                    // System Health Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.health_and_safety,
                                  color: _getSystemStatusColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'System Health',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'System Status',
                              _stats?['systemStatus'] ?? 'Unknown',
                              _getSystemStatusColor(),
                            ),
                            _buildStatRow(
                              'Last Updated',
                              DateTime.now().toString().split('.')[0],
                              Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // User Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'User Statistics',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Users',
                                    _stats?['totalUsers']?.toString() ?? '0',
                                    Icons.people_outline,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Premium Users',
                                    _stats?['activeSubscriptions']
                                            ?.toString() ??
                                        '0',
                                    Icons.star,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Free Users',
                                    _getFreeUsersCount().toString(),
                                    Icons.person_outline,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Active Today',
                                    _getActiveUsersCount().toString(),
                                    Icons.trending_up,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Usage Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Usage Statistics',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Total Summaries Generated',
                              _stats?['summariesGenerated']?.toString() ?? '0',
                              Colors.green.shade700,
                            ),
                            _buildStatRow(
                              'Daily Average',
                              _getDailyAverage().toString(),
                              Colors.green.shade500,
                            ),
                            _buildStatRow(
                              'Monthly Average',
                              _getMonthlyAverage().toString(),
                              Colors.green.shade300,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recent Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Activity',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'New Registrations Today',
                              _getNewRegistrationsToday().toString(),
                              Colors.orange.shade700,
                            ),
                            _buildStatRow(
                              'Errors (Last 24h)',
                              _getErrorCount().toString(),
                              _getErrorCount() > 0 ? Colors.red : Colors.green,
                            ),
                            _buildStatRow(
                              'Peak Usage Hour',
                              _getPeakUsageHour(),
                              Colors.orange.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Refresh Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Statistics'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }

  Color _getSystemStatusColor() {
    final status = _stats?['systemStatus']?.toString().toLowerCase();
    if (status == 'online') return Colors.green;
    if (status == 'offline mode') return Colors.orange;
    return Colors.red;
  }

  int _getFreeUsersCount() {
    final total = _stats?['totalUsers'] as int? ?? 0;
    final premium = _stats?['activeSubscriptions'] as int? ?? 0;
    return (total - premium).clamp(0, total);
  }

  int _getActiveUsersCount() {
    // Simulated data - in real app, this would come from Firebase analytics
    final total = _stats?['totalUsers'] as int? ?? 0;
    return (total * 0.3).round(); // Assume 30% of users are active today
  }

  int _getDailyAverage() {
    final total = _stats?['summariesGenerated'] as int? ?? 0;
    return (total / 30).round(); // Rough 30-day average
  }

  int _getMonthlyAverage() {
    final total = _stats?['summariesGenerated'] as int? ?? 0;
    return total; // Assume current number is monthly total
  }

  int _getNewRegistrationsToday() {
    // Simulated data - in real app, this would be calculated from today's registrations
    return widget.firebaseEnabled ? 2 : 0;
  }

  int _getErrorCount() {
    // Simulated data - in real app, this would come from error logging
    return widget.firebaseEnabled ? 0 : 1;
  }

  String _getPeakUsageHour() {
    // Simulated data - in real app, this would be calculated from usage analytics
    return widget.firebaseEnabled ? '14:00-15:00' : 'N/A';
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> stats;
      if (widget.firebaseEnabled) {
        stats = await FirebaseService().getSystemStats();
      } else {
        // Demo data for offline mode
        stats = {
          'totalUsers': 1,
          'activeSubscriptions': 0,
          'summariesGenerated': 5,
          'systemStatus': 'Demo Mode',
        };
      }

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _stats = {
          'totalUsers': 'Error',
          'activeSubscriptions': 'Error',
          'summariesGenerated': 'Error',
          'systemStatus': 'Error',
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading statistics: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
