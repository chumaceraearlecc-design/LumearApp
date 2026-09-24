import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/bug_report.dart';
import '../../services/bug_report_service.dart';

class AdminBugReportsScreen extends StatefulWidget {
  const AdminBugReportsScreen({super.key});

  @override
  State<AdminBugReportsScreen> createState() => _AdminBugReportsScreenState();
}

class _AdminBugReportsScreenState extends State<AdminBugReportsScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color cream = Color(0xFFE0CFC2);
  static const Color background = Color(0xFFF7F3F1);
  static const Color borderColor = Color(0xFFE8DDDA);
  static const Color darkText = Color(0xFF3F2927);

  final BugReportService _service = BugReportService.instance;

  String _filter = 'All';

  final List<String> _filters = const [
    'All',
    'Pending',
    'Under Review',
    'Resolved',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final List<BugReport> reports = _service.reports.where((report) {
          if (_filter == 'All') {
            return true;
          }

          return report.status == _filter;
        }).toList();

        return Container(
          color: background,
          child: Column(
            children: [
              _buildFilters(),

              Expanded(
                child: reports.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _reportCard(reports[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: _filters.map((filter) {
            final bool selected = _filter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected,
                selectedColor: cream,
                side: BorderSide(color: selected ? darkMaroon : borderColor),
                labelStyle: TextStyle(
                  color: selected ? darkMaroon : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) {
                  setState(() {
                    _filter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bug_report_outlined,
                color: darkMaroon,
                size: 36,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Bug Reports',
              style: TextStyle(
                color: darkMaroon,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Bug reports submitted by riders '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(BugReport report) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _openReport(report);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bug_report_rounded,
                      color: darkMaroon,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.id,
                          style: const TextStyle(
                            color: darkMaroon,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          report.riderName,
                          style: const TextStyle(color: darkText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  _statusBadge(report.status),
                ],
              ),

              const SizedBox(height: 13),

              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.phone_android, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      report.affectedScreen,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.reportedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Resolved':
        color = Colors.green.shade700;
        break;

      case 'Under Review':
        color = Colors.orange.shade800;
        break;

      default:
        color = maroon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _openReport(BugReport report) {
    final TextEditingController responseController = TextEditingController(
      text: report.adminResponse,
    );

    String selectedStatus = report.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.90,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 10, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report_rounded, color: darkMaroon),

                        const SizedBox(width: 9),

                        Expanded(
                          child: Text(
                            report.id,
                            style: const TextStyle(
                              color: darkMaroon,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
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
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        _detailsSection('Rider Information', [
                          _detailRow('Rider ID', report.riderId),
                          _detailRow('Name', report.riderName),
                          _detailRow('Email', report.riderEmail),
                        ]),

                        const SizedBox(height: 18),

                        _detailsSection('System Information', [
                          _detailRow('Screen', report.affectedScreen),
                          _detailRow('App Version', report.appVersion),
                          _detailRow('Device', report.deviceInfo),
                          _detailRow(
                            'Reported',
                            _formatDateTime(report.reportedAt),
                          ),
                        ]),

                        const SizedBox(height: 18),

                        _textSection(
                          title: 'What happened?',
                          text: report.description,
                        ),

                        const SizedBox(height: 14),

                        _textSection(
                          title: 'Expected result',
                          text: report.expectedResult,
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Evidence',
                          style: TextStyle(
                            color: darkMaroon,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 9),

                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: report.evidencePaths.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(report.evidencePaths[index]),
                                  width: 180,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Report Status',
                          style: TextStyle(
                            color: darkMaroon,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'Under Review',
                              child: Text('Under Review'),
                            ),
                            DropdownMenuItem(
                              value: 'Resolved',
                              child: Text('Resolved'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setModalState(() {
                              selectedStatus = value;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Admin Response',
                          style: TextStyle(
                            color: darkMaroon,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: responseController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Add notes or a response for the rider...',
                            hintStyle: const TextStyle(fontSize: 11),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              _service.updateStatus(
                                reportId: report.id,
                                status: selectedStatus,
                              );

                              _service.updateAdminResponse(
                                reportId: report.id,
                                response: responseController.text,
                              );

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '${report.id} updated successfully.',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkMaroon,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Update Report',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(responseController.dispose);
  }

  Widget _detailsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkMaroon,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10.5),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: darkText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textSection({required String title, required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkMaroon,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            text,
            style: const TextStyle(color: darkText, fontSize: 12, height: 1.45),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    int hour = date.hour;

    final String period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final String minute = date.minute.toString().padLeft(2, '0');

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute $period';
  }
}
