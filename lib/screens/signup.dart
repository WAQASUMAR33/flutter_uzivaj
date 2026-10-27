import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '/theme/app_theme.dart';
import '/providers/signup_provider.dart';
import '/screens/terms_screen.dart';
import '/screens/login.dart';
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

  final _nationalityFieldKey = GlobalKey<FormFieldState<Country>>();
  Country? _selectedNationality;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

  Future<void> _openCountryPicker({FormFieldState<Country>? field}) async {
    final l = AppStrings.of(context, listen: false);
    final country = await showDialog<Country>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CountryPickerDialog(
        title: l.selectNationality,
        searchHint: l.searchCountryHint,
      ),
    );

    if (country != null) {
      setState(() {
        _selectedNationality = country;
        _updateMobileWithCountryCode(country);
      });
      field?.didChange(country);
      _nationalityFieldKey.currentState?.didChange(country);
    }
  }

  void _updateMobileWithCountryCode(Country country) {
    final newPrefix = '+${country.phoneCode}';
    final current = _mobileController.text.trim();

    if (current.isEmpty) {
      _mobileController.text = '$newPrefix ';
    } else if (current.startsWith('+')) {
      final spaceIndex = current.indexOf(' ');
      if (spaceIndex != -1 && spaceIndex < current.length - 1) {
        final localDigits = current.substring(spaceIndex + 1).trim();
        _mobileController.text = '$newPrefix $localDigits';
      } else {
        _mobileController.text = '$newPrefix ';
      }
    } else {
      _mobileController.text = '$newPrefix $current';
    }

    _mobileController.selection = TextSelection.fromPosition(
      TextPosition(offset: _mobileController.text.length),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Apptheme.bluecolor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 48,
                color: Apptheme.bluecolor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Email Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please Verify the email first, check your inbox',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Apptheme.bluecolor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  // Country / Nationality Picker (Select First)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.nationalityLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      FormField<Country>(
                        key: _nationalityFieldKey,
                        initialValue: _selectedNationality,
                        validator: (_) =>
                            _selectedNationality == null ? l.nationalityRequired : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openCountryPicker(field: field),
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
                                          child: Text(
                                            '${_selectedNationality!.name} (+${_selectedNationality!.phoneCode})',
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(Icons.public, color: Colors.grey),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l.selectNationality,
                                            style: TextStyle(
                                                color: Colors.grey.shade500, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
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
                  // Mobile Number with auto country code
                  CustomTextField(
                    title: l.mobileLabel,
                    labelText: _selectedNationality != null
                        ? '+${_selectedNationality!.phoneCode} 91 234 5678'
                        : '+385 91 234 5678',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_android,
                    onTap: () {
                      if (_selectedNationality == null) {
                        _openCountryPicker();
                      }
                    },
                    validator: (value) {
                      if (_selectedNationality == null) {
                        return l.selectNationality;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l.mobileRequired;
                      }
                      final expectedPrefix = '+${_selectedNationality!.phoneCode}';
                      final cleaned = value.replaceAll(RegExp(r'\s+'), '');
                      final expectedCleanedPrefix = expectedPrefix.replaceAll(RegExp(r'\s+'), '');
                      if (!cleaned.startsWith(expectedCleanedPrefix) ||
                          cleaned.length <= expectedCleanedPrefix.length + 3) {
                        return l.mobileInvalid;
                      }
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
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                  CustomTextField(
                    title: l.confirmPasswordLabel,
                    labelText: l.repeatPassword,
                    controller: _confirmPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
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
                                  _showVerificationDialog(context);
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
  final IconData? icon;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
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
    this.icon,
    this.prefixIcon,
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
          obscuringCharacter: '•',
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: labelText,
            prefixIcon: prefixIcon ?? (icon != null ? Icon(icon) : null),
            suffixIcon: suffixIcon,
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

class _CountryPickerDialog extends StatefulWidget {
  final String title;
  final String searchHint;

  const _CountryPickerDialog({
    required this.title,
    required this.searchHint,
  });

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final List<Country> _allCountries;
  List<Country> _filteredCountries = [];

  static const List<String> _popularCodes = [
    'HR', 'BA', 'RS', 'SI', 'DE', 'AT', 'CH', 'GB', 'US'
  ];
  List<Country> _popularCountries = [];

  @override
  void initState() {
    super.initState();
    final service = CountryService();
    _allCountries = service.getAll();
    _filteredCountries = List.from(_allCountries);
    _popularCountries = _popularCodes
        .map((code) => service.findByCode(code))
        .whereType<Country>()
        .toList();

    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase().replaceAll('+', '');
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(_allCountries);
      } else {
        _filteredCountries = _allCountries.where((c) {
          final nameMatch = c.name.toLowerCase().contains(query);
          final codeMatch = c.countryCode.toLowerCase().contains(query);
          final phoneMatch = c.phoneCode.contains(query);
          return nameMatch || codeMatch || phoneMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight > 700 ? 580.0 : (screenHeight * 0.85);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: dialogHeight,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.public, color: Apptheme.bluecolor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Search Input
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          splashRadius: 18,
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    borderSide: const BorderSide(color: Apptheme.bluecolor, width: 1.5),
                  ),
                ),
              ),
            ),
            // Popular countries quick chips
            if (_searchController.text.isEmpty && _popularCountries.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _popularCountries.map((c) {
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(c),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '${c.flagEmoji} ${c.name} (+${c.phoneCode})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],
            // Countries list
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Text(
                        'No country found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (ctx, index) {
                        final country = _filteredCountries[index];
                        return ListTile(
                          dense: true,
                          leading: Text(
                            country.flagEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            country.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            country.countryCode,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${country.phoneCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Apptheme.bluecolor,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
