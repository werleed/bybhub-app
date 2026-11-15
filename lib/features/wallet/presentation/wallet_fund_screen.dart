import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class WalletFundScreen extends ConsumerStatefulWidget {
  const WalletFundScreen({super.key});
  @override
  ConsumerState<WalletFundScreen> createState() => _WalletFundScreenState();
}

class _WalletFundScreenState extends ConsumerState<WalletFundScreen> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _paystackUrl;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _initPaystack() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount < 100) {
      setState(() => _error = 'Minimum amount is ₦100');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/wallet/fund/paystack', data: {'amount': amount});
      final body = response.data as Map<String, dynamic>;
      final url = body['data']?['authorization_url'] as String?;
      if (url != null) {
        setState(() => _paystackUrl = url);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paystackUrl != null) {
      return _PaystackWebView(
        url: _paystackUrl!,
        onSuccess: (ref_) => _verifyPayment(ref_),
        onCancel: () => setState(() => _paystackUrl = null),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Fund via Paystack', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Pay with debit/credit card. Minimum ₦100.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (NGN)', prefixText: '₦'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _initPaystack,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Pay with Card'),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _verifyPayment(String reference) async {
    setState(() { _loading = true; _paystackUrl = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/wallet/fund/paystack/verify', data: {'reference': reference});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet funded successfully!'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PaystackWebView extends StatefulWidget {
  final String url;
  final ValueChanged<String> onSuccess;
  final VoidCallback onCancel;

  const _PaystackWebView({required this.url, required this.onSuccess, required this.onCancel});

  @override
  State<_PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<_PaystackWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final url = req.url;
          // Paystack callback URL contains the reference
          if (url.contains('/api/v1/wallet/paystack/callback') || url.contains('trxref=')) {
            final uri = Uri.parse(url);
            final reference = uri.queryParameters['reference'] ?? uri.queryParameters['trxref'] ?? '';
            if (reference.isNotEmpty) {
              widget.onSuccess(reference);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
