import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '/theme/app_theme.dart';
import '/services/userStorageService.dart';
import '/services/apiService.dart';
import '/screens/subscription_screen.dart';
import '/screens/onboarding_screen.dart';
import '/l10n/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _subStatus;
  bool _loading = true;
  double _totalSavings = 0;
  int _totalOffersUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _openEditSheet() async {
    if (_userData == null) return;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(userData: _userData!),
    );
    if (updated != null && mounted) {
      await UserStorageService().saveUser(updated);
      setState(() => _userData = updated);
    }
  }

  Future<void> _loadData() async {
    final user = await UserStorageService().getUser();
    if (!mounted) return;
    setState(() => _userData = user);

    final customerId = user?['id'] as int?;
    if (customerId != null) {
      try {
        final status = await ApiService().getSubscriptionStatus(
          customerId: customerId,
        );
        if (mounted) setState(() => _subStatus = status);
      } catch (_) {}

      // Fetch redeem history and compute combined savings
      try {
        final historyData = await ApiService().getRedeemHistory(
          customerId: customerId,
        );
        final redemptions = (historyData['redemptions'] as List?) ?? [];
        double savings = 0;
        for (final item in redemptions) {
          final s = item['savings'];
          if (s != null) {
            savings += (s is num) ? s.toDouble() : (double.tryParse(s.toString()) ?? 0);
          }
        }
        if (mounted) {
          setState(() {
            _totalSavings = savings;
            _totalOffersUsed = redemptions.length;
          });
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  String _initials() {
    final name = _userData?['fullname'] as String? ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty)
      return parts[0][0].toUpperCase();
    return '?';
  }

  String _memberSince(AppStrings l) {
    final raw = _userData?['createdAt'] as String?;
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return l.memberSince('${months[dt.month - 1]} ${dt.year}');
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatSavings(double value) {
    if (value == value.truncateToDouble()) {
      return '€${value.toInt()}';
    }
    return '€${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);

    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final fullname = _userData?['fullname'] as String? ?? 'Guest';
    final email = _userData?['email'] as String? ?? '';
    final phone = _userData?['phoneNumber'] as String? ?? '';
    final nationality = _userData?['nationality'] as String? ?? '';
    final memberSinceStr = _memberSince(l);

    final isSubscribed = _subStatus?['subscribed'] == true;
    final subPlan = _subStatus?['plan'] as String?;
    final subStatus = _subStatus?['status'] as String?;
    final subEndDate = _formatDate(_subStatus?['endDate'] as String?);
    final subPrice = _subStatus?['price'];
    final subCurrency = _subStatus?['currency'] as String? ?? 'EUR';
    final daysRemaining = _subStatus?['daysRemaining'] as int? ?? 0;
    final subPackage =
        _subStatus?['subscriptionPackage'] as Map<String, dynamic>?;
    final packageTitle = subPackage?['title'] as String?;

    final badgeLabel = isSubscribed
        ? (subPlan ?? 'MEMBER').replaceAll('_', ' ')
        : 'MEMBER';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Blue header ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  color: Apptheme.bluecolor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.myProfile,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Icon(
                            Icons.settings_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.orange,
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (memberSinceStr.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                memberSinceStr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Stats row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(value: _formatSavings(_totalSavings), label: l.estSaved),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(value: '$_totalOffersUsed', label: l.offersUsed),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Account section ───────────────────────────────────────────
              _SectionLabel(l.accountSection),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (email.isNotEmpty)
                      _AccountRow(
                        icon: Icons.mail_outline,
                        text: email,
                        isFirst: true,
                        isLast: phone.isEmpty && nationality.isEmpty,
                      ),
                    if (phone.isNotEmpty)
                      _AccountRow(
                        icon: Icons.phone_android,
                        text: phone,
                        isFirst: email.isEmpty,
                        isLast: nationality.isEmpty,
                      ),
                    if (nationality.isNotEmpty)
                      _AccountRow(
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.redAccent,
                        text: nationality,
                        isFirst: email.isEmpty && phone.isEmpty,
                        isLast: true,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Subscription section ──────────────────────────────────────
              _SectionLabel(l.subscriptionSection),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSubscribed
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (packageTitle != null)
                                      Text(
                                        packageTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    if (subPlan != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Apptheme.bluecolor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          subPlan,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Apptheme.bluecolor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (subPrice != null)
                                Text(
                                  '${subCurrency == 'EUR' ? '€' : subCurrency}$subPrice',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Apptheme.bluecolor,
                                  ),
                                ),
                            ],
                          ),
                          if (subEndDate.isNotEmpty || daysRemaining > 0) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (subEndDate.isNotEmpty)
                                  _SubDetail(
                                    label: 'Expires',
                                    value: subEndDate,
                                  ),
                                if (daysRemaining > 0)
                                  _SubDetail(
                                    label: 'Days left',
                                    value: '$daysRemaining',
                                    valueColor: daysRemaining < 30
                                        ? Colors.orange
                                        : Colors.green.shade600,
                                  ),
                                if (subStatus != null)
                                  _SubDetail(
                                    label: 'Status',
                                    value: subStatus,
                                    valueColor: Colors.green.shade600,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l.noActiveSubscription,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            ),
                            child: Text(
                              l.subscribe,
                              style: const TextStyle(
                                color: Apptheme.bluecolor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // ── Help section ──────────────────────────────────────────────
              _SectionLabel(l.helpSection),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: Apptheme.bluecolor,
                    size: 22,
                  ),
                  title: Text(
                    l.howItWorks,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    l.howItWorksSub,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(replay: true),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SubDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SubDetail({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Apptheme.bluecolor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  const _EditProfileSheet({required this.userData});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nationalityCtrl;
  String? _gender;
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.userData['fullname'] as String? ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.userData['phoneNumber'] as String? ?? '',
    );
    _nationalityCtrl = TextEditingController(
      text: widget.userData['nationality'] as String? ?? '',
    );
    // normalize to lowercase so it matches DropdownMenuItem values
    final rawGender = (widget.userData['gender'] as String?)?.toLowerCase();
    _gender = const ['male', 'female', 'other'].contains(rawGender)
        ? rawGender
        : null;
    final rawDob = widget.userData['dateOfBirth'] as String?;
    if (rawDob != null) {
      try {
        _dob = DateTime.parse(rawDob);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalityCtrl.dispose();
    super.dispose();
  }

  String _formatDob(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _pickNationality() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (country) {
        setState(() => _nationalityCtrl.text = country.name);
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!
        .save(); // triggers onSaved on all fields, including gender
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = widget.userData['id'] as int;
      final imageUrl = widget.userData['imageUrl'] as String? ?? '';
      final updated = await ApiService().updateProfile(
        id: id,
        fullname: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        nationality: _nationalityCtrl.text.trim(),
        dateOfBirth: _dob != null ? _formatDob(_dob!) : '',
        gender: _gender ?? '',
        imageUrl: imageUrl,
      );
      // merge updated fields back into existing user map
      final merged = {...widget.userData, ...updated};
      if (mounted) Navigator.pop(context, merged);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // Full name
              _label('Full Name'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDeco('Enter full name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Phone
              _label('Phone Number'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('e.g. +38512345678'),
              ),
              const SizedBox(height: 14),

              // Nationality
              _label('Nationality'),
              TextFormField(
                controller: _nationalityCtrl,
                readOnly: true,
                onTap: _pickNationality,
                decoration: _inputDeco(
                  'Select country',
                ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
              ),
              const SizedBox(height: 14),

              // Date of birth
              _label('Date of Birth'),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDeco('Select date').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    controller: TextEditingController(
                      text: _dob != null ? _formatDob(_dob!) : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Gender
              _label('Gender'),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _inputDeco('Select gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => _gender = v,
                onSaved: (v) => _gender = v,
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Apptheme.bluecolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Apptheme.bluecolor, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
  );
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  final bool isFirst;
  final bool isLast;

  const _AccountRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, indent: 52, color: Colors.grey.shade100),
        ListTile(
          leading: Icon(
            icon,
            color: iconColor ?? Colors.grey.shade600,
            size: 20,
          ),
          title: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          dense: true,
          onTap: () {},
        ),
      ],
    );
  }
}
