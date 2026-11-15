import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _loading = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _nameCtrl = TextEditingController(text: user?.name);
    _phoneCtrl = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _saved = false; });
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/profile', data: {'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()});
      setState(() => _saved = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(children: [
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.error))),
          if (_saved) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: const Text('Saved!', style: TextStyle(color: AppColors.success))),
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loading ? null : _save,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes')),
        ])),
      ),
    );
  }
}
