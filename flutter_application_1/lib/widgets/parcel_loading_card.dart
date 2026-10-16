import 'package:flutter/material.dart';

class ParcelLoadingCard extends StatelessWidget {
  const ParcelLoadingCard({
    super.key,
    required this.assignedParcels,
    required this.loadedParcels,
    required this.loadingComplete,
    required this.onAdd,
    required this.onRemove,
    required this.onConfirm,
  });

  final int assignedParcels;
  final int loadedParcels;
  final bool loadingComplete;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onConfirm;

  static const darkMaroon = Color(0xFF62191C);
  static const maroon = Color(0xFF873632);
  static const brownBeige = Color(0xFF9E7161);
  static const cream = Color(0xFFE0CFC2);

  @override
  Widget build(BuildContext context) {
    final progress = assignedParcels == 0
        ? 0.0
        : (loadedParcels / assignedParcels).clamp(0.0, 1.0).toDouble();

    final canEdit = !loadingComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: maroon, size: 25),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Parcel Loading',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$loadedParcels/$assignedParcels',
                style: const TextStyle(
                  color: maroon,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: cream,
              color: maroon,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% loaded',
                style: const TextStyle(
                  color: maroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '${assignedParcels - loadedParcels} remaining',
                style: const TextStyle(color: brownBeige, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canEdit && loadedParcels > 0 ? onRemove : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canEdit && loadedParcels < assignedParcels
                      ? onAdd
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add parcel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loadedParcels == assignedParcels && canEdit
                  ? onConfirm
                  : null,
              icon: Icon(
                loadingComplete ? Icons.check_circle : Icons.inventory,
              ),
              label: Text(
                loadingComplete
                    ? 'Loading Complete'
                    : 'Confirm Loading Complete',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (loadedParcels < assignedParcels && !loadingComplete) ...[
            const SizedBox(height: 8),
            const Text(
              'Load all assigned parcels before confirming.',
              style: TextStyle(color: brownBeige, fontSize: 11),
            ),
          ],
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
}
