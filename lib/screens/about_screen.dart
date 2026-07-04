import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      appBar: AppBar(title: const Text('About MOgas MOmoney')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App overview ────────────────────────────────────────────────
          _InfoCard(
            icon: Icons.local_gas_station,
            title: 'What is MOgas MOmoney?',
            body:
                'MOgas MOmoney helps Missouri drivers track fuel receipts and '
                'generate Form 4923-H to claim a refund on the Missouri motor '
                'fuel tax increase under SB 262 (Section 142.822 RSMo).\n\n'
                'The refund rate is \$0.125 per gallon for fuel purchased in '
                'eligible vehicles with a gross weight of 26,000 lbs or less.',
          ),
          const SizedBox(height: 12),

          // ── How it works ────────────────────────────────────────────────
          _InfoCard(
            icon: Icons.checklist_outlined,
            title: 'How it works',
            body:
                '1. Add your vehicle info (VIN, year, make, fuel type).\n'
                '2. Scan or manually enter each fuel receipt.\n'
                '3. Export Form 4923-H as a PDF — sign it and mail it to the '
                'Missouri Department of Revenue with your original receipts attached.\n\n'
                'The filing window is open July 1 – September 30 each year for '
                'fuel purchased July 1 – June 30 of the prior fiscal year.',
          ),
          const SizedBox(height: 12),

          // ── Privacy ─────────────────────────────────────────────────────
          _InfoCard(
            icon: Icons.lock_outline,
            title: 'Your data stays on your device',
            body:
                'All receipts, vehicle info, and personal details are stored '
                'locally on your device only. Nothing is transmitted to any '
                'server, shared with third parties, or collected by the developer. '
                'There is no account, no cloud sync, and no backend.',
          ),
          const SizedBox(height: 12),

          // ── Links ───────────────────────────────────────────────────────
          _SectionHeader(label: 'Missouri Department of Revenue'),
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.open_in_new,
            label: 'Motor Fuel Tax Refund Program',
            sublabel: 'dor.mo.gov',
            onTap: () => _launch('https://dor.mo.gov/taxation/business/tax-types/motor-fuel/'),
          ),
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.download_outlined,
            label: 'Download Blank Form 4923-H',
            sublabel: 'Official PDF from dor.mo.gov',
            onTap: () => _launch('https://dor.mo.gov/forms/4923-H.pdf'),
          ),
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            sublabel: 'apps.reqs.tech/mogas/privacy',
            onTap: () => _launch('https://apps.reqs.tech/mogas/privacy'),
          ),
          const SizedBox(height: 24),

          // ── Disclaimer ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: col.subtleFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: col.subtleBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: col.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MOgas MOmoney is a personal record-keeping tool. '
                    'The developer is not a licensed tax professional. '
                    'You are responsible for verifying the accuracy of your '
                    'submission to the Missouri Department of Revenue. '
                    'For questions about your specific tax situation, consult '
                    'the Missouri DOR or a qualified tax professional.',
                    style: TextStyle(fontSize: 12, color: col.labelText, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Support ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Support'),
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.email_outlined,
            label: 'Contact the developer',
            sublabel: 'singularity@reqs.tech',
            onTap: () => _launch('mailto:singularity@reqs.tech'),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'MOgas MOmoney · REQS TECH',
              style: TextStyle(fontSize: 12, color: col.mutedText),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: col.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: col.primary)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(body,
                style: TextStyle(
                    fontSize: 13, color: col.labelText, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: context.col.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5));
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: col.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.subtleBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: col.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: col.onSurface)),
                  Text(sublabel,
                      style: TextStyle(fontSize: 12, color: col.mutedText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: col.mutedText),
          ],
        ),
      ),
    );
  }
}
