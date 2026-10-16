enum HubTransferStatus { loading, readyToDepart, inTransit, arrived, completed }

class HubTransfer {
  final String id;
  final String originName;
  final String originAddress;
  final String destinationName;
  final String destinationAddress;
  final int assignedParcels;
  final int initialLoadedParcels;
  final String estimatedRoute;

  const HubTransfer({
    required this.id,
    required this.originName,
    required this.originAddress,
    required this.destinationName,
    required this.destinationAddress,
    required this.assignedParcels,
    required this.initialLoadedParcels,
    required this.estimatedRoute,
  });
}

const HubTransfer demoHubTransfer = HubTransfer(
  id: 'HT-2048',
  originName: 'Lumear North Sorting Center',
  originAddress: 'Quezon City',
  destinationName: 'Lumear South Distribution Hub',
  destinationAddress: 'Muntinlupa City',
  assignedParcels: 24,
  initialLoadedParcels: 18,
  estimatedRoute: '32 km · Estimated 1 hr 20 min',
);

class TransferHistoryItem {
  final String id;
  final String origin;
  final String destination;
  final String status;
  final String completedAt;
  final int parcelCount;

  const TransferHistoryItem({
    required this.id,
    required this.origin,
    required this.destination,
    required this.status,
    this.completedAt = 'Sample record',
    this.parcelCount = 0,
  });
}

const List<TransferHistoryItem> demoTransferHistory = [
  TransferHistoryItem(
    id: 'HT-2041',
    origin: 'Caloocan Hub',
    destination: 'Marikina Hub',
    status: 'Completed',
    completedAt: 'Oct 12, 2026',
    parcelCount: 32,
  ),
  TransferHistoryItem(
    id: 'HT-2036',
    origin: 'Pasig Sorting Center',
    destination: 'Quezon City Hub',
    status: 'Completed',
    completedAt: 'Oct 10, 2026',
    parcelCount: 27,
  ),
];
