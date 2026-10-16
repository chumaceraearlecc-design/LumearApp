import 'package:flutter/material.dart';

class TransferProgressCard extends StatelessWidget {
  const TransferProgressCard({
    super.key,
    required this.loadingComplete,
    required this.hasDeparted,
    required this.hasArrived,
    required this.unloadingComplete,
    required this.onConfirmDeparture,
    required this.onConfirmArrival,
    required this.onConfirmUnloading,
  });

  final bool loadingComplete;
  final bool hasDeparted;
  final bool hasArrived;
  final bool unloadingComplete;

  final VoidCallback onConfirmDeparture;
  final VoidCallback onConfirmArrival;
  final VoidCallback onConfirmUnloading;

  static const darkMaroon = Color(0xFF62191C);
  static const maroon = Color(0xFF873632);
  static const brownBeige = Color(0xFF9E7161);
  static const cream = Color(0xFFE0CFC2);
  static const background = Color(0xFFF8F2ED);
  static const success = Color(0xFF5B7D51);

  String get status {
    if (unloadingComplete) return 'COMPLETED';
    if (hasArrived) return 'ARRIVED';
    if (hasDeparted) return 'IN TRANSIT';
    if (loadingComplete) return 'READY TO DEPART';
    return 'LOADING';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transfer HT-2048',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _badge(status),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _step('Loaded', loadingComplete),
              const _Connector(),
              _step('Departed', hasDeparted),
              const _Connector(),
              _step('Arrived', hasArrived),
              const _Connector(),
              _step('Unloaded', unloadingComplete),
            ],
          ),
          const SizedBox(height: 22),
          _action(
            icon: Icons.departure_board_outlined,
            title: 'Departure Confirmation',
            subtitle: hasDeparted
                ? 'Departure confirmed'
                : 'Confirm when leaving the origin hub',
            complete: hasDeparted,
            enabled: loadingComplete && !hasDeparted && !hasArrived,
            onTap: onConfirmDeparture,
          ),
          const SizedBox(height: 10),
          _action(
            icon: Icons.flag_outlined,
            title: 'Arrival Confirmation',
            subtitle: hasArrived
                ? 'Arrival confirmed'
                : 'Confirm when you reach the destination',
            complete: hasArrived,
            enabled: hasDeparted && !hasArrived,
            onTap: onConfirmArrival,
          ),
          const SizedBox(height: 10),
          _action(
            icon: Icons.inventory_2_outlined,
            title: 'Unloading Confirmation',
            subtitle: unloadingComplete
                ? 'Transfer completed'
                : 'Confirm handover of parcels at destination',
            complete: unloadingComplete,
            enabled: hasArrived && !unloadingComplete,
            onTap: onConfirmUnloading,
          ),
          const SizedBox(height: 12),
          const Text(
            'Prototype only: confirmations are stored in screen memory.',
            style: TextStyle(color: brownBeige, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _step(String label, bool complete) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          complete ? Icons.check_circle : Icons.circle_outlined,
          color: complete ? success : cream,
          size: 22,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: complete ? darkMaroon : brownBeige,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool complete,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: complete ? success.withValues(alpha: 0.08) : background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: complete ? success.withValues(alpha: 0.3) : cream,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: complete ? success : maroon,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                complete ? Icons.check : icon,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkMaroon,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: brownBeige, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              complete ? Icons.check_circle : Icons.chevron_right,
              color: complete ? success : brownBeige,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: maroon,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  BoxDecoration _decoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cream.withValues(alpha: 0.7)),
    boxShadow: [
      BoxShadow(
        color: darkMaroon.withValues(alpha: 0.035),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 3, right: 3, bottom: 19),
        color: TransferProgressCard.cream.withValues(alpha: 0.6),
      ),
    );
  }
}
