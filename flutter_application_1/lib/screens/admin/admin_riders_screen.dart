import 'package:flutter/material.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color cream = Color(0xFFE0CFC2);
  static const Color background = Color(0xFFF7F3F1);

  static const Color success = Color(0xFF3F7D58);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFB3261E);

  String _searchText = '';
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> riders = [
    {
      'name': 'Earl Chumacera',
      'id': 'RID-001',
      'email': 'earl@lumear.com',
      'phone': '0912 345 6789',
      'status': 'Active',
      'device': 'Samsung Galaxy A55',
      'ip': '192.168.1.24',
      'lastLogin': 'Sep 14, 2026 • 10:42 AM',
      'flagged': false,
      'risk': 'Normal',
      'logs': [
        'Logged in successfully',
        'Accepted delivery LMR-10231',
        'Updated delivery to In Transit',
        'Opened Help & Support',
      ],
    },
    {
      'name': 'Juan Dela Cruz',
      'id': 'RID-002',
      'email': 'juan@lumear.com',
      'phone': '0917 555 2011',
      'status': 'Active',
      'device': 'Redmi Note 13',
      'ip': '203.177.45.81',
      'lastLogin': 'Sep 14, 2026 • 9:10 AM',
      'flagged': true,
      'risk': 'Suspicious',
      'logs': [
        'Login from new device',
        'Multiple login locations detected',
        'Accepted delivery LMR-10232',
        'Security alert generated',
      ],
    },
    {
      'name': 'Pedro Santos',
      'id': 'RID-003',
      'email': 'pedro@lumear.com',
      'phone': '0998 332 2211',
      'status': 'Suspended',
      'device': 'OPPO Reno 12',
      'ip': '112.198.70.19',
      'lastLogin': 'Sep 13, 2026 • 7:22 PM',
      'flagged': true,
      'risk': 'High Risk',
      'logs': [
        'Repeated failed login attempts',
        'Suspicious account activity detected',
        'Admin warning sent',
        'Account suspended',
      ],
    },
    {
      'name': 'Mark Reyes',
      'id': 'RID-004',
      'email': 'mark@lumear.com',
      'phone': '0922 111 2233',
      'status': 'Terminated',
      'device': 'Realme 12 Pro',
      'ip': '49.145.100.77',
      'lastLogin': 'Sep 10, 2026 • 2:30 PM',
      'flagged': true,
      'risk': 'Terminated',
      'logs': [
        'Policy violation reported',
        'Account investigation opened',
        'Account suspended',
        'Account terminated',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredRiders = riders.where((rider) {
      final String search = _searchText.toLowerCase();

      final bool matchesSearch =
          rider['name'].toString().toLowerCase().contains(search) ||
          rider['id'].toString().toLowerCase().contains(search) ||
          rider['email'].toString().toLowerCase().contains(search);

      bool matchesFilter = true;

      switch (_selectedFilter) {
        case 'Active':
          matchesFilter = rider['status'] == 'Active';
          break;

        case 'Flagged':
          matchesFilter = rider['flagged'] == true;
          break;

        case 'Suspended':
          matchesFilter = rider['status'] == 'Suspended';
          break;

        case 'Terminated':
          matchesFilter = rider['status'] == 'Terminated';
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Container(
      color: background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Monitoring',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Monitor rider accounts, device activity and security alerts.',
                  style: TextStyle(color: brownBeige, fontSize: 12),
                ),

                const SizedBox(height: 18),

                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search rider, ID or email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All'),
                      _filterChip('Active'),
                      _filterChip('Flagged'),
                      _filterChip('Suspended'),
                      _filterChip('Terminated'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filteredRiders.isEmpty
                ? const Center(
                    child: Text(
                      'No riders found.',
                      style: TextStyle(color: brownBeige),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
                    itemCount: filteredRiders.length,
                    itemBuilder: (context, index) {
                      return _riderCard(filteredRiders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text) {
    final bool selected = _selectedFilter == text;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(text),
        selectedColor: cream,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? darkMaroon : brownBeige,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = text;
          });
        },
      ),
    );
  }

  Widget _riderCard(Map<String, dynamic> rider) {
    final bool flagged = rider['flagged'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: flagged
            ? Border.all(color: warning.withValues(alpha: 0.40))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _showRiderDetails(rider);
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cream,
                    child: Text(
                      rider['name'].toString().substring(0, 1),
                      style: const TextStyle(
                        color: darkMaroon,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  if (flagged)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rider['name'],
                            style: const TextStyle(
                              color: darkMaroon,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (flagged) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'FLAGGED',
                              style: TextStyle(
                                color: warning,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      rider['id'],
                      style: const TextStyle(color: brownBeige, fontSize: 10.5),
                    ),

                    const SizedBox(height: 4),

                    _statusText(rider['status']),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: brownBeige),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusText(String status) {
    Color color = success;

    if (status == 'Suspended') {
      color = warning;
    }

    if (status == 'Terminated') {
      color = danger;
    }

    return Text(
      status,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _showRiderDetails(Map<String, dynamic> rider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.92,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: brownBeige.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: cream,
                              child: Text(
                                rider['name'].toString().substring(0, 1),
                                style: const TextStyle(
                                  color: darkMaroon,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rider['name'],
                                    style: const TextStyle(
                                      color: darkMaroon,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    rider['id'],
                                    style: const TextStyle(color: brownBeige),
                                  ),
                                  const SizedBox(height: 3),
                                  _statusText(rider['status']),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _sectionHeading('Account Information'),

                        _infoCard(
                          children: [
                            _infoRow(
                              Icons.email_outlined,
                              'Email',
                              rider['email'],
                            ),
                            _divider(),
                            _infoRow(
                              Icons.phone_outlined,
                              'Phone',
                              rider['phone'],
                            ),
                            _divider(),
                            _infoRow(
                              Icons.badge_outlined,
                              'Rider ID',
                              rider['id'],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _sectionHeading('Security Information'),

                        _infoCard(
                          children: [
                            _infoRow(
                              Icons.smartphone_rounded,
                              'Device',
                              rider['device'],
                            ),
                            _divider(),
                            _infoRow(
                              Icons.language_rounded,
                              'IP Address',
                              rider['ip'],
                            ),
                            _divider(),
                            _infoRow(
                              Icons.schedule_rounded,
                              'Last Login',
                              rider['lastLogin'],
                            ),
                            _divider(),
                            _infoRow(
                              Icons.security_rounded,
                              'Risk Level',
                              rider['risk'],
                            ),
                          ],
                        ),

                        if (rider['flagged'] == true) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: warning.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: warning.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: warning,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Suspicious activity has been detected on this account. Review activity logs before taking action.',
                                    style: TextStyle(
                                      color: darkMaroon,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        _sectionHeading('Recent Activity'),

                        const SizedBox(height: 8),

                        ...List<String>.from(rider['logs'])
                            .map((log) => _activityLog(log)),

                        const SizedBox(height: 24),

                        _sectionHeading('Account Actions'),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () {
                            _showNotificationDialog(rider);
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Send Notification'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkMaroon,
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: darkMaroon),
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (rider['status'] == 'Active')
                          ElevatedButton.icon(
                            onPressed: () {
                              _confirmAccountAction(
                                rider: rider,
                                action: 'Suspend',
                                newStatus: 'Suspended',
                                setModalState: setModalState,
                              );
                            },
                            icon: const Icon(
                              Icons.pause_circle_outline_rounded,
                            ),
                            label: const Text('Suspend Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: warning,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),

                        if (rider['status'] == 'Suspended')
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                rider['status'] = 'Active';
                                rider['logs'].insert(
                                  0,
                                  'Account reactivated by administrator',
                                );
                              });

                              setModalState(() {});
                            },
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: const Text('Reactivate Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: success,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),

                        if (rider['status'] != 'Terminated') ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              _confirmAccountAction(
                                rider: rider,
                                action: 'Terminate',
                                newStatus: 'Terminated',
                                setModalState: setModalState,
                              );
                            },
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('Terminate Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: danger,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkMaroon,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: darkMaroon, size: 19),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: brownBeige, fontSize: 9.5),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Divider(height: 20, color: Color(0xFFF0E8E4));
  }

  Widget _activityLog(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: brownBeige, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: darkMaroon, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(Map<String, dynamic> rider) {
    final titleController = TextEditingController(text: 'Account Notice');

    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send message to ${rider['name']}',
                  style: const TextStyle(color: brownBeige, fontSize: 12),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Example: Your account has been flagged for suspicious activity.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  rider['logs'].insert(
                    0,
                    'Admin notification sent: ${titleController.text.trim()}',
                  );
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Notification sent to ${rider['name']}.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      messageController.dispose();
    });
  }

  Future<void> _confirmAccountAction({
    required Map<String, dynamic> rider,
    required String action,
    required String newStatus,
    required StateSetter setModalState,
  }) async {
    final reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$action ${rider['name']}?'),

              const SizedBox(height: 15),

              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter the reason for this action...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'Terminate' ? danger : warning,
                foregroundColor: Colors.white,
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        rider['status'] = newStatus;

        rider['logs'].insert(
          0,
          'Account ${newStatus.toLowerCase()} by administrator. Reason: ${reasonController.text.trim()}',
        );
      });

      setModalState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('${rider['name']} is now $newStatus.'),
          ),
        );
      }
    }

    reasonController.dispose();
  }
}
