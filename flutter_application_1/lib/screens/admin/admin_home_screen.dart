import 'package:flutter/material.dart';

import 'admin_payout_verification_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color cream = Color(0xFFE0CFC2);
  static const Color background = Color(0xFFF7F3F1);

  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB7791F);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: RefreshIndicator(
        color: darkMaroon,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 700));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            _welcomeCard(),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: darkMaroon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payout Monitoring',
                          style: TextStyle(
                            color: darkMaroon,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'View payout requests and payment status',
                          style: TextStyle(color: brownBeige, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open payout monitoring',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPayoutVerificationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: darkMaroon,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('System Overview'),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _summaryCard(
                  icon: Icons.groups_rounded,
                  value: '24',
                  title: 'Total Riders',
                ),
                _summaryCard(
                  icon: Icons.local_shipping_rounded,
                  value: '18',
                  title: 'Active Deliveries',
                ),
                _summaryCard(
                  icon: Icons.security_rounded,
                  value: '3',
                  title: 'Flagged Accounts',
                ),
                _summaryCard(
                  icon: Icons.bug_report_rounded,
                  value: '5',
                  title: 'Bug Reports',
                ),
              ],
            ),

            const SizedBox(height: 26),

            _sectionTitle('Security Alerts'),

            const SizedBox(height: 12),

            _alertCard(
              icon: Icons.warning_amber_rounded,
              iconColor: warning,
              title: 'Suspicious login detected',
              subtitle: 'RID-002 logged in from an unusual device.',
              time: '8 min ago',
            ),

            _alertCard(
              icon: Icons.lock_person_rounded,
              iconColor: danger,
              title: 'Multiple failed login attempts',
              subtitle: 'RID-006 had 5 unsuccessful login attempts.',
              time: '18 min ago',
            ),

            _alertCard(
              icon: Icons.devices_rounded,
              iconColor: warning,
              title: 'New device detected',
              subtitle: 'RID-003 signed in using a new Android device.',
              time: '35 min ago',
            ),

            const SizedBox(height: 26),

            _sectionTitle('Needs Attention'),

            const SizedBox(height: 12),

            _attentionCard(
              icon: Icons.security_rounded,
              title: '3 flagged rider accounts',
              subtitle: 'Review suspicious account activity.',
            ),

            _attentionCard(
              icon: Icons.bug_report_rounded,
              title: '5 rider bug reports',
              subtitle: 'Some reports are still pending review.',
            ),

            _attentionCard(
              icon: Icons.warning_amber_rounded,
              title: '2 failed deliveries',
              subtitle: 'Review delivery incidents.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [darkMaroon, Color(0xFF471114)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkMaroon.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cream,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: darkMaroon,
              size: 31,
            ),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Monitor Lumear activity, rider accounts, deliveries and system security.',
                  style: TextStyle(color: cream, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkMaroon,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: darkMaroon, size: 21),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            title,
            style: const TextStyle(
              color: brownBeige,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: brownBeige, fontSize: 10.5),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: maroon),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: brownBeige, fontSize: 11),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: brownBeige),
        ],
      ),
    );
  }
}
