import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '/theme/app_theme.dart';
import '/services/apiService.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';

class TermsScreen extends StatefulWidget {
  final bool isOverlay;
  const TermsScreen({super.key, this.isOverlay = false});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String? _htmlEn;
  String? _htmlHr;
  String? _updatedAt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getTermsAndConditions();
      if (mounted) {
        setState(() {
          _htmlEn = data['contentEn'] as String? ?? data['content'] as String?;
          _htmlHr = data['contentHr'] as String? ?? data['content'] as String?;
          _updatedAt = data['updatedAt'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Last updated: ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final displayHtml = isEn ? _htmlEn : _htmlHr;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isOverlay
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Terms & Conditions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
              ),
              centerTitle: true,
            )
          : AppBar(
              backgroundColor: Apptheme.bluecolor,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Terms & Conditions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              centerTitle: true,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _load();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Apptheme.bluecolor),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_updatedAt != null && _updatedAt!.isNotEmpty) ...[
                        Text(
                          _formatDate(_updatedAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                      ],
                      HtmlWidget(
                        displayHtml ?? '',
                        textStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
