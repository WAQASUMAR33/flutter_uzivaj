import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/services/apiService.dart';
import '/l10n/app_strings.dart';

Future<void> showSupportSheet(
  BuildContext context, {
  Map<String, dynamic>? userData,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SupportSheet(userData: userData),
  );
}

class SupportSheet extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const SupportSheet({super.key, this.userData});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _messageCtrl;

  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _ticketResponse;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.userData?['fullname'] as String? ?? '',
    );
    _emailCtrl = TextEditingController(
      text: widget.userData?['email'] as String? ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.userData?['phoneNumber'] as String? ?? '',
    );
    _subjectCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final customerId = widget.userData?['id'] as int? ?? 0;
      final response = await ApiService().sendSupportMessage(
        customerId: customerId,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _submitting = false;
          _ticketResponse = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    if (_ticketResponse != null) {
      final ticket = _ticketResponse!['ticket'] as Map<String, dynamic>?;
      final ticketId = ticket?['id']?.toString() ?? '#';
      final status = ticket?['status']?.toString() ?? 'PENDING';
      final successMsg =
          _ticketResponse!['message']?.toString() ?? l.supportSuccess;

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              successMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Ticket #$ticketId · Status: $status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Apptheme.bluecolor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l.doneBtn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.contactSupport,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _label(l.fullNameLabel),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDeco(l.fullNameHint),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.fullNameRequired : null,
              ),
              const SizedBox(height: 12),
              _label(l.emailLabel),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDeco('user@example.com'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.emailRequired : null,
              ),
              const SizedBox(height: 12),
              _label(l.mobileLabel),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('+1234567890'),
              ),
              const SizedBox(height: 12),
              _label(l.supportSubject),
              TextFormField(
                controller: _subjectCtrl,
                decoration: _inputDeco('e.g. Subscription Renewal Issue'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l.supportSubjectRequired
                    : null,
              ),
              const SizedBox(height: 12),
              _label(l.supportMessage),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: _inputDeco(
                  'Hello support team, I need assistance...',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l.supportMessageRequired
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Apptheme.bluecolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l.submitBtn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
}
