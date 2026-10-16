import 'package:flutter/material.dart';

import '../models/hub_transfer_model.dart';

class HubAssignmentCard extends StatelessWidget {
  const HubAssignmentCard({
    super.key,
    required this.transfer,
    required this.hasDeparted,
    required this.hasArrived,
  });

  final HubTransfer transfer;
  final bool hasDeparted;
  final bool hasArrived;

  static const darkMaroon = Color(0xFF62191C);
  static const maroon = Color(0xFF873632);
  static const brownBeige = Color(0xFF9E7161);
  static const cream = Color(0xFFE0CFC2);
  static const background = Color(0xFFF8F2ED);
  static const success = Color(0xFF5B7D51);

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
              const Icon(Icons.alt_route, color: maroon),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Hub Assignment',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _badge(transfer.id),
            ],
          ),
          const SizedBox(height: 20),
          _location(
            label: 'ORIGIN HUB',
            name: transfer.originName,
            address: transfer.originAddress,
            icon: Icons.trip_origin,
            completed: hasDeparted,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(height: 27, width: 2, color: cream),
          ),
          _location(
            label: 'DESTINATION HUB',
            name: transfer.destinationName,
            address: transfer.destinationAddress,
            icon: Icons.location_on_outlined,
            completed: hasArrived,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.route, color: maroon, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.estimatedRoute,
                    style: const TextStyle(color: brownBeige, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sample assignment · Not connected to a server',
            style: TextStyle(color: brownBeige, fontSize: 10),
          ),
        ],
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

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: maroon,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _location({
    required String label,
    required String name,
    required String address,
    required IconData icon,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: completed ? success : maroon, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: brownBeige,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: const TextStyle(color: brownBeige, fontSize: 12),
              ),
            ],
          ),
        ),
        if (completed) const Icon(Icons.check_circle, color: success, size: 19),
      ],
    );
  }
}
