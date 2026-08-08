import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/services/userStorageService.dart';
import '/services/apiService.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';

class RedeemHistoryScreen extends StatefulWidget {
  const RedeemHistoryScreen({super.key});

  @override
  State<RedeemHistoryScreen> createState() => _RedeemHistoryScreenState();
}

class _RedeemHistoryScreenState extends State<RedeemHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await UserStorageService().getUser();
      final customerId = user?['id'] as int?;
      if (customerId == null) throw Exception('Not logged in');

      final data = await ApiService().getRedeemHistory(customerId: customerId);
      if (mounted) {
        setState(() {
          _history = (data['redemptions'] as List?) ?? [];
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
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Apptheme.bluecolor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Redeem History',
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
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No redemptions yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your redeemed offers will appear here.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = _history[i] as Map<String, dynamic>;
                        final offer = item['offer'] as Map<String, dynamic>?;
                        final merchant =
                            item['merchant'] as Map<String, dynamic>?;
                        final discount =
                            item['offerDiscount'] as String? ?? '';
                        final savings = item['savings'];
                        final date = _formatDate(
                            item['redeemedAt'] as String?);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Apptheme.bluecolor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_offer_outlined,
                                  color: Apptheme.bluecolor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (merchant != null)
                                      Text(
                                        merchant[isEn ? 'nameEn' : 'nameHr'] as String? ?? merchant['name'] as String? ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    if (offer != null)
                                      Text(
                                        offer[isEn ? 'titleEn' : 'titleHr'] as String? ?? offer['title'] as String? ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (discount.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.orange.withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              discount,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        if (savings != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Saved €$savings',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
    );
  }
}
