import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/payout_claim.dart';
import 'package:flutter_application_1/services/rider_earnings_service.dart';

class AdminPayoutVerificationScreen extends StatefulWidget {
  const AdminPayoutVerificationScreen({super.key});

  @override
  State<AdminPayoutVerificationScreen> createState() =>
      _AdminPayoutVerificationScreenState();
}

class _AdminPayoutVerificationScreenState
    extends State<AdminPayoutVerificationScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color cream = Color(0xFFF3E9E1);
  static const Color muted = Color(0xFF8B6F63);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFB3261E);

  final RiderEarningsService _service = RiderEarningsService.instance;

  String _formatPeso(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString()
        .padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Payout Monitoring'),
        backgroundColor: cream,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<PayoutClaim>>(
          valueListenable: _service.payouts,
          builder: (context, claims, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Read-only view. Admins can monitor payout status; only Logistics staff handles rider payments.',
                    style: TextStyle(color: Color(0xFF795C25), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 18),
                if (claims.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'No payout requests to monitor.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    '${claims.length} payout request${claims.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: darkMaroon,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...claims.map(_claimDetails),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _claimDetails(PayoutClaim claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: darkMaroon.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Claim details',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusBadge(claim.status),
            ],
          ),
          const SizedBox(height: 14),
          _detail('Rider', claim.riderName),
          _detail('Rider ID', claim.riderId),
          _detail('Email', claim.riderEmail),
          _detail('Receipt number', claim.referenceId),
          _detail('Claim amount', _formatPeso(claim.amount)),
          _detail('Schedule', claim.schedule.label),
          _detail(
            'Period',
            '${_formatDate(claim.periodStart)} to ${_formatDate(claim.periodEnd)}',
          ),
          _detail('Requested', _formatDate(claim.requestedAt)),
          if (claim.paidAt != null) ...[
            _detail('Paid at', _formatDate(claim.paidAt!)),
            _detail('Staff', claim.staffIdentifier ?? 'Not recorded'),
            _detail('Method', claim.paymentMethod ?? 'Not recorded'),
            if (claim.paymentReference != null)
              _detail('Payment reference', claim.paymentReference!),
          ],
          const SizedBox(height: 12),
          const Text(
            'Covered deliveries',
            style: TextStyle(
              color: darkMaroon,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          ...claim.deliveries.map(
            (delivery) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: success, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${delivery.parcelNumber} • ${delivery.recipient}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    _formatPeso(delivery.amount),
                    style: const TextStyle(
                      color: darkMaroon,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PayoutStatus status) {
    final Color color = switch (status) {
      PayoutStatus.pending => const Color(0xFFB7791F),
      PayoutStatus.paid => success,
      PayoutStatus.rejected => danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: darkMaroon,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
