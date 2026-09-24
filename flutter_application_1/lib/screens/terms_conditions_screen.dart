import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color cream = Color(0xFFE0CFC2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: darkMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Lumear Rider Terms & Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please read these terms carefully before creating and using your Lumear Rider account.',
              style: TextStyle(fontSize: 14, color: brownBeige, height: 1.5),
            ),

            const SizedBox(height: 25),

            _buildSection(
              title: '1. Account Responsibility',
              content: 'Riders are responsible for providing accurate information when registering an account. Account details must not be shared with other people.',
            ),

            _buildSection(
              title: '2. Delivery Responsibility',
              content: 'Riders must handle assigned deliveries properly and update the delivery status accurately throughout the delivery process.',
            ),

            _buildSection(
              title: '3. Parcel Handling',
              content: 'Riders are expected to take reasonable care of parcels while they are in their possession and follow the proper pickup and delivery procedures.',
            ),

            _buildSection(
              title: '4. Cash on Delivery',
              content: 'For Cash on Delivery orders, riders must collect the correct amount shown in the application and follow Lumear procedures for handling collected payments.',
            ),

            _buildSection(
              title: '5. Proof of Delivery',
              content: 'Riders may be required to provide proof of delivery, such as delivery confirmation or a photo, before a parcel can be marked as completed.',
            ),

            _buildSection(
              title: '6. Location Information',
              content: 'The application may use the rider\'s location to support delivery tracking, route guidance, and delivery-related features.',
            ),

            _buildSection(
              title: '7. Proper Use of the Application',
              content: 'Riders must use the Lumear Rider application only for legitimate delivery activities and must not intentionally provide false delivery information.',
            ),

            _buildSection(
              title: '8. Account Suspension',
              content: 'Lumear may restrict or suspend an account when there is misuse of the application, repeated delivery violations, or inaccurate information.',
            ),

            _buildSection(
              title: '9. Updates to the Terms',
              content: 'Lumear may update these Terms & Conditions when necessary. Riders should review updated terms when they are made available in the application.',
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(15),
              ),

              child: const Text(
                'By creating a Lumear Rider account, you confirm that you have read and agreed to these Terms & Conditions.',
                style: TextStyle(
                  fontSize: 13,
                  color: darkMaroon,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: maroon,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
