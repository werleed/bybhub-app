import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person_outlined, color: AppColors.primary)),
          title: Text(user?.name ?? 'Guest'),
          subtitle: Text(user?.email ?? ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/profile'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: const Text('Language'),
          trailing: Text(user?.language == 'fr' ? 'Français' : 'English'),
          onTap: () => _showLanguagePicker(context, ref, user?.language ?? 'en'),
        ),
        ListTile(
          leading: const Icon(Icons.currency_exchange_outlined),
          title: const Text('Display Currency'),
          trailing: Text('${AppConstants.currencySymbols[user?.currency ?? 'NGN']} ${user?.currency ?? 'NGN'}'),
          onTap: () => _showCurrencyPicker(context, ref, user?.currency ?? 'NGN'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: const Text('My Orders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/orders'),
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: const Text('Wallet'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/wallet'),
        ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Referral Program'),
          subtitle: const Text('Earn ₦500 per referral'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/referrals'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            await ref.read(authNotifierProvider.notifier).logout();
            if (context.mounted) context.go('/auth/login');
          },
        ),
      ]),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('Select Language', style: TextStyle(fontWeight: FontWeight.w700))),
      ListTile(leading: current == 'en' ? const Icon(Icons.check, color: AppColors.primary) : const SizedBox(width: 24),
          title: const Text('English'), onTap: () async {
            Navigator.pop(context);
            await ref.read(dioProvider).post('/settings/language', data: {'language': 'en'});
          }),
      ListTile(leading: current == 'fr' ? const Icon(Icons.check, color: AppColors.primary) : const SizedBox(width: 24),
          title: const Text('Français'), onTap: () async {
            Navigator.pop(context);
            await ref.read(dioProvider).post('/settings/language', data: {'language': 'fr'});
          }),
    ]));
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('Display Currency', style: TextStyle(fontWeight: FontWeight.w700))),
      ...AppConstants.displayCurrencies.map((c) => ListTile(
        leading: current == c ? const Icon(Icons.check, color: AppColors.primary) : const SizedBox(width: 24),
        title: Text('${AppConstants.currencySymbols[c]} $c'),
        onTap: () async {
          Navigator.pop(context);
          await ref.read(dioProvider).post('/settings/currency', data: {'currency': c});
        },
      )),
    ]));
  }
}
