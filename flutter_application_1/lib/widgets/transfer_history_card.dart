import 'package:flutter/material.dart';

import '../models/hub_transfer_model.dart';

class TransferHistoryCard extends StatelessWidget {
  const TransferHistoryCard({super.key, required this.items});

  final List<TransferHistoryItem> items;

  static const darkMaroon = Color(0xFF62191C);
  static const maroon = Color(0xFF873632);
  static const brownBeige = Color(0xFF9E7161);
  static const cream = Color(0xFFE0CFC2);
  static const success = Color(0xFF5B7D51);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cream.withValues(alpha: 0.7)),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No completed transfers yet.',
                  style: TextStyle(color: brownBeige),
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 24, color: cream),
                  _historyItem(items[i]),
                ],
              ],
            ),
    );
  }

  Widget _historyItem(TransferHistoryItem item) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: cream.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_shipping_outlined, color: maroon),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.id,
                style: const TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.origin} → ${item.destination}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: brownBeige, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.completedAt} · ${item.parcelCount} parcels',
                style: const TextStyle(color: brownBeige, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                item.status,
                style: const TextStyle(
                  color: success,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: success, size: 20),
      ],
    );
  }
}
