import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_colors.dart';
import 'legal_documents.dart';
import 'legal_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _row(BuildContext context, String title, VoidCallback onTap) {
    final c = context.colors;

    return Column(
      children: [
        Divider(height: 1, color: c.border),
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 15, color: c.ink),
                  ),
                ),
                Icon(Icons.chevron_right, size: 22, color: c.subtle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'About',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            AppInfo.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version ${AppInfo.version}',
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
          const SizedBox(height: 16),
          Text(
            'A practice shopping app built with Flutter, Dio and Provider. Products come '
            'from a public test service, and carts, addresses and orders are saved on '
            'this phone. Nothing is real: nothing is charged and nothing is delivered.',
            style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
          ),
          const SizedBox(height: 24),
          _row(
            context,
            'Terms of use',
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalScreen(document: termsOfUse),
              ),
            ),
          ),
          _row(
            context,
            'Privacy policy',
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalScreen(document: privacyPolicy),
              ),
            ),
          ),
          
          _row(
            context,
            'Open-source licenses',
            () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: AppInfo.version,
            ),
          ),
          _row(context, 'Copy the source code link', () {
            Clipboard.setData(const ClipboardData(text: AppInfo.sourceUrl));
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(const SnackBar(content: Text('Link copied.')));
          }),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }
}
