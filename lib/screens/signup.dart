import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '/theme/app_theme.dart';
import '/providers/signup_provider.dart';
import '/screens/home.dart';
import '/screens/terms_screen.dart';
import '/l10n/app_strings.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Country? _selectedNationality;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Apptheme.bluecolor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.createAccount,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(l.joinUzivaj,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    title: l.fullNameLabel,
                    labelText: l.fullNameHint,
                    controller: _fullnameController,
                    keyboardType: TextInputType.name,
                    icon: Icons.person_outline,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? l.fullNameRequired : null,
                  ),
                  CustomTextField(
                    title: l.emailLabel,
                    labelText: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l.emailRequired;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return l.emailInvalid;
                      return null;
                    },
                  ),
                  CustomTextField(
                    title: l.mobileLabel,
                    labelText: '+385 91 234 5678',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_android,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l.mobileRequired;
                      if (!value.startsWith('+385')) return l.mobileInvalid;
                      return null;
                    },
                  ),
                  CustomTextField(
                    title: l.dobLabel,
                    labelText: l.dobHint,
                    controller: _dobController,
                    keyboardType: TextInputType.datetime,
                    icon: Icons.cake_outlined,
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dobController.text =
                              "${pickedDate.day.toString().padLeft(2, '0')} / ${pickedDate.month.toString().padLeft(2, '0')} / ${pickedDate.year}";
                        });
                      }
                    },
                    validator: (value) =>
                        (value == null || value.isEmpty) ? l.dobRequired : null,
                  ),
                  // Nationality Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.nationalityLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      FormField<Country>(
                        validator: (_) =>
                            _selectedNationality == null ? l.nationalityRequired : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: false,
                                  countryListTheme: CountryListThemeData(
                                    borderRadius: BorderRadius.circular(16),
                                    inputDecoration: InputDecoration(
                                      hintText: l.searchCountryHint,
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                  onSelect: (Country country) {
                                    setState(() => _selectedNationality = country);
                                    field.didChange(country);
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: field.hasError ? Colors.red : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if (_selectedNationality != null) ...[
                                      Text(_selectedNationality!.flagEmoji,
                                          style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(_selectedNationality!.name,
                                            style: const TextStyle(fontSize: 16)),
                                      ),
                                    ] else ...[
                                      const Icon(Icons.public, color: Colors.grey),
                                      const SizedBox(width: 10),
                                      Text(l.selectNationality,
                                          style: TextStyle(
                                              color: Colors.grey.shade500, fontSize: 16)),
                                    ],
                                    const Spacer(),
                                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 12),
                                child: Text(
                                  field.errorText!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  Text(l.genderLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Consumer<SignupProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        children: [
                          Expanded(child: _buildGenderPill('Male', l.male, provider)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildGenderPill('Female', l.female, provider)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildGenderPill(
                                  'Prefer not to say', l.preferNotToSay, provider)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    title: l.passwordLabel,
                    labelText: l.createStrongPassword,
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l.passwordRequired;
                      if (value.length < 8 || value.length > 20) return l.passwordLength;
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) return l.passwordLowercase;
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return l.passwordUppercase;
                      if (!RegExp(r'(?=.*\d)').hasMatch(value)) return l.passwordDigit;
                      return null;
                    },
                  ),
                  CustomTextField(
                    title: l.confirmPasswordLabel,
                    labelText: l.repeatPassword,
                    controller: _confirmPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l.confirmPasswordRequired;
                      if (value != _passwordController.text) return l.passwordsMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<SignupProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: provider.agreedToTerms,
                            onChanged: provider.toggleTerms,
                            activeColor: Apptheme.bluecolor,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: l.iAgreeTo,
                                style: const TextStyle(fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: l.termsOfService,
                                    style: const TextStyle(
                                        color: Apptheme.bluecolor,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            fullscreenDialog: true,
                                            builder: (_) => const TermsScreen(isOverlay: true),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<SignupProvider>(
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                if (provider.selectedGender.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l.pleaseSelectGender)),
                                  );
                                  return;
                                }
                                if (!provider.agreedToTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l.pleaseAgreeTerms)),
                                  );
                                  return;
                                }

                                final parts = _dobController.text.split(' / ');
                                final apiDob = '${parts[2]}-${parts[1]}-${parts[0]}';

                                final success = await provider.register(
                                  fullname: _fullnameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  phoneNumber: _mobileController.text.trim(),
                                  nationality: _selectedNationality!.name,
                                  dateOfBirth: apiDob,
                                );

                                if (!context.mounted) return;
                                if (success) {
                                  // Registration logs the user in → go straight
                                  // to Home. Onboarding is a first-launch-only
                                  // walkthrough (revisit via Profile → Help).
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const HomeScreen()),
                                    (route) => false,
                                  );
                                } else if (provider.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(provider.error!)),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Apptheme.bluecolor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(l.createAccount,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderPill(String apiValue, String displayLabel, SignupProvider provider) {
    final isSelected = provider.selectedGender == apiValue;
    return GestureDetector(
      onTap: () => provider.setGender(apiValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade100,
          border: Border.all(
              color: isSelected ? Apptheme.bluecolor : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            displayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Apptheme.bluecolor : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String title;
  final String labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData icon;
  final IconData? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.title,
    required this.labelText,
    required this.controller,
    required this.keyboardType,
    required this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: labelText,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
