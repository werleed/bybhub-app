import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Floating WhatsApp support button — appears on all main screens.
class SupportButton extends StatelessWidget {
  const SupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'whatsapp',
      backgroundColor: const Color(0xFF25D366),
      onPressed: () => _openWhatsApp(),
      tooltip: 'WhatsApp Support',
      child: const Icon(Icons.chat_outlined, color: Colors.white, size: 20),
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(AppConstants.whatsappSupportUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
