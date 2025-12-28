import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/password_requirements_widget.dart';
import './widgets/profile_photo_upload_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/terms_privacy_widget.dart';

class Registration extends StatefulWidget {
  const Registration({Key? key}) : super(key: key);

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _termsAccepted = false;
  XFile? _selectedImage;

  // Validation states
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    setState(() {
      _emailValid = emailRegex.hasMatch(email);
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _passwordValid = password.length >= 8 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]')) &&
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    setState(() {
      _confirmPasswordValid = _confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text == _passwordController.text;
    });
  }

  bool get _isFormValid =>
      _emailValid && _passwordValid && _confirmPasswordValid && _termsAccepted;

  Future<void> _createAccount() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      // Simulate account creation process
      await Future.delayed(Duration(seconds: 2));

      // Mock validation - check for existing email
      if (_emailController.text.toLowerCase() == 'test@example.com') {
        _showErrorDialog(
            'An account with this email already exists. Please use a different email or try signing in.');
        return;
      }

      // Show success message
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(
          'Failed to create account. Please check your internet connection and try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Simulate Google Sign-In process
      await Future.delayed(Duration(seconds: 2));

      // Navigate to dashboard on success
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showErrorDialog('Google Sign-In failed. Please try again.');
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isAppleLoading = true);

    try {
      // Simulate Apple Sign-In process
      await Future.delayed(Duration(seconds: 2));

      // Navigate to dashboard on success
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showErrorDialog('Apple Sign-In failed. Please try again.');
    } finally {
      setState(() => _isAppleLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text('Registration Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text('Welcome!'),
            ],
          ),
          content: Text(
              'Your account has been created successfully. Welcome to AI Stock Summary!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: Text('Get Started'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 5.w,
          ),
        ),
        title: Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),

                // Progress Indicator
                ProgressIndicatorWidget(
                  currentStep: 1,
                  totalSteps: 1,
                ),

                SizedBox(height: 4.h),

                // Welcome Text
                Text(
                  'Join AI Stock Summary',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Create your account to start tracking stocks with AI-powered insights',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),

                SizedBox(height: 4.h),

                // Google Sign-In Button
                Container(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton.icon(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    icon: _isGoogleLoading
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'g_translate',
                            size: 5.w,
                          ),
                    label: Text(
                      _isGoogleLoading ? 'Signing In...' : 'Continue with Google',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
                      side: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Apple Sign-In Button (Required for App Store Guideline 4.8)
                Container(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton.icon(
                    onPressed: _isAppleLoading ? null : _signInWithApple,
                    icon: _isAppleLoading
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'apple',
                            color: Colors.white,
                            size: 5.w,
                          ),
                    label: Text(
                      _isAppleLoading ? 'Signing In...' : 'Continue with Apple',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'or',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Profile Photo Upload
                Center(
                  child: ProfilePhotoUploadWidget(
                    selectedImage: _selectedImage,
                    onImageSelected: (XFile? image) {
                      setState(() => _selectedImage = image);
                    },
                  ),
                ),

                SizedBox(height: 4.h),

                // Email Field
                Text(
                  'Email Address',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'email',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: _emailValid ? 'check_circle' : 'error',
                              color: _emailValid
                                  ? AppTheme.lightTheme.colorScheme.tertiary
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          )
                        : null,
                  ),
                ),

                SizedBox(height: 3.h),

                // Password Field
                Text(
                  'Password',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Create a strong password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_passwordController.text.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: CustomIconWidget(
                              iconName:
                                  _passwordValid ? 'check_circle' : 'error',
                              color: _passwordValid
                                  ? AppTheme.lightTheme.colorScheme.tertiary
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          ),
                        IconButton(
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                          icon: CustomIconWidget(
                            iconName: _isPasswordVisible
                                ? 'visibility_off'
                                : 'visibility',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Password Requirements
                if (_passwordController.text.isNotEmpty)
                  PasswordRequirementsWidget(
                      password: _passwordController.text),

                SizedBox(height: 3.h),

                // Confirm Password Field
                Text(
                  'Confirm Password',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: CustomIconWidget(
                              iconName: _confirmPasswordValid
                                  ? 'check_circle'
                                  : 'error',
                              color: _confirmPasswordValid
                                  ? AppTheme.lightTheme.colorScheme.tertiary
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                          icon: CustomIconWidget(
                            iconName: _isConfirmPasswordVisible
                                ? 'visibility_off'
                                : 'visibility',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Terms and Privacy
                TermsPrivacyWidget(
                  isAccepted: _termsAccepted,
                  onChanged: (bool? value) {
                    setState(() => _termsAccepted = value ?? false);
                  },
                ),

                SizedBox(height: 4.h),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid && !_isLoading ? _createAccount : null,
                    child: _isLoading
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Sign In Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/login'),
                            child: Text(
                              'Sign In',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}