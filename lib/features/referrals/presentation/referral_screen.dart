import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final referralStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/referrals/stats');
  final body = response.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  });

final referralListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/referrals');
  final body = response.data as Map<String, dynamic>;
  return (body['data'] as List?) ?? [];
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(referralStatsProvider);
    final listAsync = ref.watch(referralListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => Container(height: 220, color: AppColors.primary),
              error: (_, __) => Container(height: 220, color: AppColors.primary),
              data: (stats) => _ReferralHero(stats: stats),
            ),
          ),

          // Stats grid
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox(height: 100, child: LoadingOverlay()),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _StatsGrid(stats: stats),
            ),
          ),

          // Program details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    )),
                    const SizedBox(height: 8),
                    ...['Share your unique referral link with friends',
                        'They sign up and place their first order',
                        'You earn ₦500 when they cross the minimum spend'].map((s) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)))),
                        ]),
                      )),
                  ],
                ),
              ),
            ),
          ),

          // My referrals header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('My Referrals', style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 16,
              )),
            ),
          ),

          // Referral list
          listAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 80, child: LoadingOverlay())),
            error: (e, _) => SliverToBoxAdapter(child: ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(referralListProvider))),
            data: (refs) => refs.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'No referrals yet',
                      subtitle: 'Share your link and start earning',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final r = refs[i] as Map<String, dynamic>;
                        return _ReferralItem(referral: r);
                      },
                      childCount: refs.length,
                    ),
                  ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

class _ReferralHero extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _ReferralHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final refCode = stats['referral_code'] as String? ?? '';
    final refLink = stats['referral_link'] as String? ?? '';
    final bonusPerRef = (stats['bonus_per_referral'] as num?)?.toDouble() ?? 500;
    final currency = 'NGN';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF060f20), Color(0xFF1A3A6B), Color(0xFF2451A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('👥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Referral Program', style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              )),
              Text('Earn ${CurrencyFormatter.format(bonusPerRef, currency)} per referral',
                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 20),

          // Referral code box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your referral code', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(refCode, style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins', letterSpacing: 2,
                  )),
                ]),
              ),
              Row(children: [
                // Copy button
                _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: refLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Link copied! Share with friends 🔗'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Share button
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppColors.secondary,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: refLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Link copied! Share with friends 🔗'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    );
                  },
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1A3A6B),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats['total_referrals'] ?? 0;
    final paid = stats['paid_referrals'] ?? 0;
    final earned = (stats['total_bonus_earned'] as num?)?.toDouble() ?? 0;
    final pending = stats['pending_referrals'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _StatCard(label: 'Total', value: '$total', icon: '👥', color: AppColors.primary),
        const SizedBox(width: 10),
        _StatCard(label: 'Paid', value: '$paid', icon: '✅', color: AppColors.success),
        const SizedBox(width: 10),
        _StatCard(label: 'Pending', value: '$pending', icon: '⏳', color: AppColors.warning),
        const SizedBox(width: 10),
        _StatCard(label: 'Earned', value: '₦${earned.toStringAsFixed(0)}', icon: '💰', color: AppColors.secondary),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF1A3A6B).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 15, color: color,
          )),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ReferralItem extends StatelessWidget {
  final Map<String, dynamic> referral;
  const _ReferralItem({required this.referral});

  @override
  Widget build(BuildContext context) {
    final paid = referral['bonus_paid'] as bool? ?? false;
    final amount = (referral['bonus_amount'] as num?)?.toDouble() ?? 0;
    final name = referral['referred_name'] as String? ?? 'User';
    final date = (referral['created_at'] as String?)?.substring(0, 10) ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF1A3A6B).withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₦${amount.toStringAsFixed(0)}',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 14,
                  color: paid ? AppColors.success : AppColors.warning)),
          Text(paid ? '✅ Paid' : '⏳ Pending',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: paid ? AppColors.success : AppColors.warning)),
        ]),
      ]),
    );
  }
}
