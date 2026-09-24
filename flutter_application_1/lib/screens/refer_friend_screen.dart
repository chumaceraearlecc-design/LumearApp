import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferFriendScreen extends StatelessWidget {
  const ReferFriendScreen({super.key});

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  static const String referralCode = 'RIDER2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: darkMaroon),
        ),

        title: const Text(
          'Refer a Friend',
          style: TextStyle(fontWeight: FontWeight.bold, color: darkMaroon),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: darkMaroon,
                borderRadius: BorderRadius.circular(24),
              ),

              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: lightBeige,
                    child: Icon(
                      Icons.group_add_outlined,
                      size: 46,
                      color: darkMaroon,
                    ),
                  ),

                  SizedBox(height: 14),

                  Text(
                    'Invite Friends. Earn Rewards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Invite your friends to become riders and earn rewards when they complete the referral requirements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: lightBeige,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Your Referral Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  const Text(
                    'Share this code with your friend',
                    style: TextStyle(fontSize: 12, color: brownBeige),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    referralCode,
                    style: TextStyle(
                      fontSize: 28,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      color: darkMaroon,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: referralCode),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied!'),
                              ),
                            );
                          },

                          icon: const Icon(Icons.copy_outlined),

                          label: const Text('Copy Code'),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkMaroon,
                            side: const BorderSide(color: darkMaroon),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon.'),
                              ),
                            );
                          },

                          icon: const Icon(Icons.share_outlined),

                          label: const Text('Share'),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkMaroon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Referral Rewards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: lightBeige,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: darkMaroon,
                    child: Icon(Icons.card_giftcard, color: Colors.white),
                  ),

                  SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earn ₱100',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkMaroon,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Get a referral bonus when your invited rider completes the required number of deliveries.',
                          style: TextStyle(fontSize: 12, color: maroon),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'How It Works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),

            const SizedBox(height: 12),

            _stepCard(
              number: '1',
              title: 'Share Your Code',
              subtitle: 'Send your referral code to a friend who wants to become a rider.',
            ),

            _stepCard(
              number: '2',
              title: 'Friend Registers',
              subtitle: 'Your friend creates a rider account using your referral code.',
            ),

            _stepCard(
              number: '3',
              title: 'Complete Requirements',
              subtitle: 'Your friend gets verified and completes the required deliveries.',
            ),

            _stepCard(
              number: '4',
              title: 'Receive Reward',
              subtitle: 'Once qualified, the referral bonus will be added to your earnings.',
            ),

            const SizedBox(height: 24),

            const Text(
              'My Referrals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),

            const SizedBox(height: 12),

            _referralCard(
              name: 'Mark Santos',
              status: 'Completed',
              deliveries: '10/10 deliveries',
              reward: '₱100',
              isCompleted: true,
            ),

            _referralCard(
              name: 'Carlo Reyes',
              status: 'In Progress',
              deliveries: '6/10 deliveries',
              reward: 'Pending',
              isCompleted: false,
            ),

            _referralCard(
              name: 'James Cruz',
              status: 'Pending Verification',
              deliveries: '0/10 deliveries',
              reward: 'Pending',
              isCompleted: false,
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: darkMaroon),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Referral rewards and requirements shown here are sample values for the app demo.',
                      style: TextStyle(fontSize: 12, color: brownBeige),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _stepCard({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: darkMaroon,

            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkMaroon,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: brownBeige),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _referralCard({
    required String name,
    required String status,
    required String deliveries,
    required String reward,
    required bool isCompleted,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: lightBeige,
            child: Icon(Icons.person_outline, color: darkMaroon),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkMaroon,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  deliveries,
                  style: const TextStyle(fontSize: 11, color: brownBeige),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      size: 15,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Reward',
                style: TextStyle(fontSize: 10, color: brownBeige),
              ),

              const SizedBox(height: 3),

              Text(
                reward,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkMaroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
