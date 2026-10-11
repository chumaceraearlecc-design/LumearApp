import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/payout_claim.dart';
import 'package:flutter_application_1/services/rider_earnings_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color cream = Color(0xFFF3E9E1);
  static const Color muted = Color(0xFF8B6F63);
  static const Color success = Color(0xFF2E7D32);

  final RiderEarningsService _service = RiderEarningsService.instance;
  PayoutSchedule _schedule = PayoutSchedule.daily;
  bool _isRequestingPayout = false;

  @override
  void initState() {
    super.initState();
    _schedule = _service.selectedSchedule.value;
  }

  String _formatPeso(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ValueListenableBuilder<List<EarningTransaction>>(
          valueListenable: _service.transactions,
          builder: (context, transactions, _) {
            return ValueListenableBuilder<List<PayoutClaim>>(
              valueListenable: _service.payouts,
              builder: (context, claims, _) {
                final double eligibleAmount = _service.eligibleAmount(
                  _schedule,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 125),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earnings',
                        style: TextStyle(
                          color: darkMaroon,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Track your earnings from completed deliveries.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 22),

                      // TOTAL EARNINGS CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [darkMaroon, maroon],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: darkMaroon.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Total Earnings',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _formatPeso(_service.totalEarnings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.greenAccent,
                                    size: 17,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    '₱50 per successful delivery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SUMMARY
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              icon: Icons.local_shipping_rounded,
                              label: 'Successful Deliveries',
                              value: '${_service.successfulDeliveryCount}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              icon: Icons.payments_rounded,
                              label: 'Rate per Parcel',
                              value: _formatPeso(
                                RiderEarningsService.earningPerDelivery,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      _buildPayoutSection(context, claims, eligibleAmount),

                      const SizedBox(height: 28),

                      const Text(
                        'Earnings History',
                        style: TextStyle(
                          color: darkMaroon,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (transactions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 34,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 44,
                                color: Color(0xFFCAAE9F),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No earnings yet',
                                style: TextStyle(
                                  color: darkMaroon,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Complete a delivery successfully to earn ₱50.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...transactions.map(
                          (transaction) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: darkMaroon.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: success.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: success,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.trackingNumber,
                                        style: const TextStyle(
                                          color: darkMaroon,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction.recipient,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Delivery completed successfully',
                                        style: TextStyle(
                                          color: success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${_formatPeso(transaction.amount)}',
                                  style: TextStyle(
                                    color: success,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPayoutSection(
    BuildContext context,
    List<PayoutClaim> claims,
    double eligibleAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payouts',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4DB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Local prototype: payout records are stored in memory and reset when the app restarts. Show the QR to Logistics after requesting a payout.',
            style: TextStyle(
              color: Color(0xFF795C25),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _balanceCard('Available', _service.availableEarnings),
            _balanceCard('Pending payout', _service.pendingPayout),
            _balanceCard('Already paid', _service.paidPayout),
            _balanceCard('Today', _service.todaysEarnings),
          ],
        ),
        const SizedBox(height: 14),
        SegmentedButton<PayoutSchedule>(
          segments: const [
            ButtonSegment(value: PayoutSchedule.daily, label: Text('Daily')),
            ButtonSegment(value: PayoutSchedule.weekly, label: Text('Weekly')),
            ButtonSegment(
              value: PayoutSchedule.monthly,
              label: Text('Monthly'),
            ),
          ],
          selected: {_schedule},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            setState(() {
              _schedule = selection.first;
              _service.selectedSchedule.value = selection.first;
            });
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: darkMaroon.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Eligible for ${_schedule.label.toLowerCase()} payout',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatPeso(eligibleAmount),
                style: const TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: eligibleAmount <= 0 || _isRequestingPayout
                ? null
                : _requestPayout,
            icon: _isRequestingPayout
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.qr_code_2_rounded),
            label: Text(
              _isRequestingPayout
                  ? 'Preparing receipt...'
                  : 'Generate Payout QR Code',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkMaroon,
              foregroundColor: Colors.white,
              disabledBackgroundColor: darkMaroon.withValues(alpha: 0.35),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Payout History',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (claims.isEmpty)
          _emptyHistory('No payout requests yet.')
        else
          ...claims.map(_payoutHistoryCard),
      ],
    );
  }

  Widget _balanceCard(String label, double amount) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            _formatPeso(amount),
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    );
  }

  Widget _payoutHistoryCard(PayoutClaim claim) {
    final Color statusColor = switch (claim.status) {
      PayoutStatus.pending => const Color(0xFFB7791F),
      PayoutStatus.paid => success,
      PayoutStatus.rejected => const Color(0xFFB3261E),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.referenceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                claim.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatPeso(claim.amount)} • ${claim.deliveries.length} deliveries • ${claim.schedule.label}',
            style: const TextStyle(color: muted, fontSize: 11.5),
          ),
          const SizedBox(height: 3),
          Text(
            'Requested ${_formatDate(claim.requestedAt)}${claim.paidAt == null ? '' : ' • Paid ${_formatDate(claim.paidAt!)}'}',
            style: const TextStyle(color: muted, fontSize: 10.5),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showReceipt(claim),
              icon: const Icon(Icons.qr_code_2_rounded, size: 17),
              label: const Text('View receipt'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPayout() async {
    if (_isRequestingPayout) return;
    setState(() => _isRequestingPayout = true);

    try {
      final double amount = _service.eligibleAmount(_schedule);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There are no eligible earnings yet.')),
        );
        return;
      }

      bool confirmationSubmitted = false;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cream,
          title: const Text('Request payout'),
          content: Text(
            'Create a ${_schedule.label.toLowerCase()} payout QR for ${_formatPeso(amount)}? These deliveries will be reserved until Logistics confirms or rejects the request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmationSubmitted) return;
                confirmationSubmitted = true;
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm request'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final PayoutClaim? claim = await _service.requestPayout(_schedule);
      if (!mounted) return;
      if (claim == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No eligible deliveries remain for this payout.'),
          ),
        );
        return;
      }

      await _showReceipt(claim);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create payout request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingPayout = false);
    }
  }

  Future<void> _showReceipt(PayoutClaim claim) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: cream,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: darkMaroon,
                size: 30,
              ),
              const SizedBox(height: 8),
              const Text(
                'Payout Receipt',
                style: TextStyle(
                  color: darkMaroon,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(claim.status.label, style: const TextStyle(color: muted)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: claim.referenceId,
                  size: 190,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Payout claim QR code',
                  eyeStyle: const QrEyeStyle(color: darkMaroon),
                  dataModuleStyle: const QrDataModuleStyle(color: darkMaroon),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatPeso(claim.amount),
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _receiptDetail('Reference', claim.referenceId),
              _receiptDetail('Rider', claim.riderName),
              _receiptDetail('Rider ID', claim.riderId),
              _receiptDetail('Schedule', claim.schedule.label),
              _receiptDetail(
                'Covered period',
                '${_formatDate(claim.periodStart)} to ${_formatDate(claim.periodEnd)}',
              ),
              _receiptDetail('Deliveries', '${claim.deliveries.length}'),
              _receiptDetail('Requested', _formatDate(claim.requestedAt)),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Included deliveries',
                  style: TextStyle(
                    color: darkMaroon,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ...claim.deliveries.map(
                (delivery) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${delivery.parcelNumber} • ${delivery.trackingNumber}',
                    style: const TextStyle(color: muted, fontSize: 10.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Show this QR to Logistics. It contains only this claim reference; scanning does not mark the payout as paid.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMaroon,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: maroon, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}
