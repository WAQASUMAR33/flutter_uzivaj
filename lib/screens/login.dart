import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/screens/signup.dart';
import '/screens/home.dart';
import '/providers/authProvider.dart';
import '/providers/login_provider.dart';
import '/providers/locale_provider.dart';
import '/l10n/app_strings.dart';
import '/screens/forgot_password_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _socialLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordFlow(BuildContext context, {String initialEmail = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: initialEmail),
      ),
    );
  }

  void _showSuspendedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Suspended'),
        content: const Text('your account has been suspended contact admin team'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Scaffold(
      backgroundColor: Apptheme.bluecolor,
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/SVG/uzivaj_logo.png',
                                  height: 90,
                                ),
                                _LanguageToggle(),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.welcomeBack,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.signInToContinue,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom White Section
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24.0),
                          color: Colors.white,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Email Field
                                    Text(
                                      l.emailLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: 'your@email.com',
                                        prefixIcon: const Icon(
                                          Icons.mail_outline,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return l.emailRequired;
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                                          return l.emailInvalid;
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Password Field
                                    Text(
                                      l.passwordLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      obscuringCharacter: '•',
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return l.passwordRequired;
                                        if (value.length < 8 || value.length > 20) return l.passwordLength;
                                        if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) return l.passwordLowercase;
                                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return l.passwordUppercase;
                                        if (!RegExp(r'(?=.*\d)').hasMatch(value)) return l.passwordDigit;
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _showForgotPasswordFlow(
                                          context,
                                          initialEmail: _emailController.text.trim(),
                                        ),
                                        child: Text(
                                          l.forgotPassword,
                                          style: const TextStyle(
                                            color: Apptheme.bluecolor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Sign In Button
                                    Consumer<LoginProvider>(
                                      builder: (context, loginProvider, child) {
                                        return ElevatedButton(
                                          onPressed: loginProvider.isLoading
                                              ? null
                                              : () async {
                                                  if (!_formKey.currentState!.validate()) return;
                                                  final success = await loginProvider.login(
                                                    email: _emailController.text.trim(),
                                                    password: _passwordController.text,
                                                  );
                                                  if (!context.mounted) return;
                                                  if (success) {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => const HomeScreen(),
                                                      ),
                                                    );
                                                  } else if (loginProvider.error != null) {
                                                    if (loginProvider.error!.contains('suspended')) {
                                                      _showSuspendedDialog(context);
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(loginProvider.error!)),
                                                      );
                                                    }
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Apptheme.bluecolor,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: loginProvider.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                      color: Colors.white, strokeWidth: 2),
                                                )
                                              : Text(
                                                  l.signIn,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.grey.shade300)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            l.orContinueWith,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.grey.shade300)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Social buttons — side by side
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return SizedBox(
                                          width: double.infinity,
                                          child: _SocialButton(
                                            label: 'Google',
                                            icon: FontAwesomeIcons.google,
                                            iconColor: const Color(0xFFEA4335),
                                            loading: _socialLoading == 'google',
                                            disabled: authProvider.isLoading,
                                            onTap: () async {
                                              setState(() => _socialLoading = 'google');
                                              final success = await authProvider.signInWithGoogle();
                                              if (!context.mounted) return;
                                              setState(() => _socialLoading = null);
                                              if (success) {
                                                Navigator.pushReplacement(context,
                                                    MaterialPageRoute(builder: (_) => const HomeScreen()));
                                              } else if (authProvider.error != null) {
                                                if (authProvider.error!.contains('suspended')) {
                                                  _showSuspendedDialog(context);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(authProvider.error!)));
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    // Guest button — subtle
                                    TextButton(
                                      onPressed: () => Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                        (route) => false,
                                      ),
                                      child: Text(
                                        l.continueAsGuest,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Sign Up Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(l.noAccount,
                                            style: const TextStyle(color: Colors.black54)),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const SignupScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            l.signUp,
                                            style: const TextStyle(
                                              color: Apptheme.bluecolor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Social sign-in button ─────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final Color iconColor;
  final bool loading;
  final bool disabled;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.loading = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = !loading && !disabled;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.grey.shade200 : Colors.grey.shade100,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
              )
            else
              FaIcon(
                icon,
                size: 18,
                color: disabled ? Colors.grey.shade300 : iconColor,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: disabled ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ── Language toggle button ─────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final isEN = provider.isEnglish;
    return GestureDetector(
      onTap: () => provider.toggleLocale(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEN ? 'EN' : 'HR',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.language, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}
