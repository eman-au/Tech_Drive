import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminWorkerDetailScreen extends StatefulWidget {
  final String workerUid;

  const AdminWorkerDetailScreen({super.key, required this.workerUid});

  @override
  State<AdminWorkerDetailScreen> createState() =>
      _AdminWorkerDetailScreenState();
}

class _AdminWorkerDetailScreenState extends State<AdminWorkerDetailScreen> {
  static const Color brand = Color(0xFFCCFD04);

  bool _loading = true;
  bool _actionLoading = false;

  Map<String, dynamic>? _requestData;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _documentsData;

  String get _currentStatus =>
      _requestData?['status'] as String? ?? 'unknown';

  bool get _canAct =>
      _currentStatus == 'pending' || _currentStatus == 'quiz_completed';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD ALL DATA =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('worker_requests')
            .doc(widget.workerUid)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.workerUid)
            .get(),
        FirebaseFirestore.instance
            .collection('worker_documents')
            .doc(widget.workerUid)
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _requestData = (results[0] as DocumentSnapshot).data()
              as Map<String, dynamic>?;
          _userData = (results[1] as DocumentSnapshot).data()
              as Map<String, dynamic>?;
          _documentsData = (results[2] as DocumentSnapshot).data()
              as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load worker detail error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= APPROVE =================
  Future<void> _approve() async {
    // Prevent duplicate action
    if (!_canAct || _actionLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Worker'),
        content: Text(
          'Approve ${_requestData?['name'] ?? 'this worker'} as a verified worker?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      if (adminUid == null) throw Exception('Admin not authenticated');

      // Re-check current status to prevent duplicate approval
      final freshSnap = await FirebaseFirestore.instance
          .collection('worker_requests')
          .doc(widget.workerUid)
          .get();

      final freshStatus = freshSnap.data()?['status'] as String? ?? '';
      if (freshStatus == 'approved' || freshStatus == 'rejected') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('This application has already been $freshStatus.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _actionLoading = false);
          await _loadData();
        }
        return;
      }

      // WriteBatch — atomic approval
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.workerUid);
      final requestRef = FirebaseFirestore.instance
          .collection('worker_requests')
          .doc(widget.workerUid);

      batch.update(userRef, {
        'userType': 'worker',
        'workerStatus': 'approved',
      });

      batch.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData(); // Refresh to show updated status
      }
    } catch (e) {
      debugPrint('Approval error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // ================= REJECT =================
  Future<void> _reject() async {
    if (!_canAct || _actionLoading) return;

    final reasonController = TextEditingController();
    String? validationError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reject Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reject ${_requestData?['name'] ?? 'this worker'}\'s application?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'Enter reason for rejection...',
                  border: const OutlineInputBorder(),
                  errorText: validationError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  setDialogState(() {
                    validationError = 'Rejection reason is required';
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.isEmpty) return; // Safety check

    setState(() => _actionLoading = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      if (adminUid == null) throw Exception('Admin not authenticated');

      // Re-check current status to prevent duplicate action
      final freshSnap = await FirebaseFirestore.instance
          .collection('worker_requests')
          .doc(widget.workerUid)
          .get();

      final freshStatus = freshSnap.data()?['status'] as String? ?? '';
      if (freshStatus == 'approved' || freshStatus == 'rejected') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('This application has already been $freshStatus.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _actionLoading = false);
          await _loadData();
        }
        return;
      }

      // WriteBatch — atomic rejection
      final batch = FirebaseFirestore.instance.batch();

      final requestRef = FirebaseFirestore.instance
          .collection('worker_requests')
          .doc(widget.workerUid);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.workerUid);

      batch.update(requestRef, {
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      });

      batch.update(userRef, {
        'workerStatus': 'rejected',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker application rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      debugPrint('Rejection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: brand,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Application Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black))
          : _requestData == null
              ? const Center(child: Text('No application data found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Status Banner ----
                      _statusBanner(),
                      const SizedBox(height: 20),

                      // ---- Personal Information ----
                      _sectionTitle("Personal Information"),
                      const SizedBox(height: 10),
                      _infoCard([
                        _infoRow("Name", _requestData?['name']),
                        _infoRow("Email", _userData?['email']),
                        _infoRow("Phone", _requestData?['phone']),
                        _infoRow("UID", widget.workerUid),
                      ]),
                      const SizedBox(height: 20),

                      // ---- Work Information ----
                      _sectionTitle("Work Information"),
                      const SizedBox(height: 10),
                      _infoCard([
                        _infoRow("Work Type", _requestData?['workType']),
                        _infoRow(
                          "Experience",
                          _requestData?['experience'] != null
                              ? '${_requestData!['experience']} years'
                              : null,
                        ),
                        _infoRow("Service Area", _requestData?['area']),
                      ]),
                      const SizedBox(height: 20),

                      // ---- Quiz Results ----
                      if (_requestData?['score'] != null) ...[
                        _sectionTitle("Quiz Results"),
                        const SizedBox(height: 10),
                        _infoCard([
                          _infoRow(
                            "Score",
                            '${_requestData?['score'] ?? 'N/A'} / ${_requestData?['total'] ?? 'N/A'}',
                          ),
                          _infoRow(
                            "Passed",
                            _requestData?['passed'] == true
                                ? 'Yes'
                                : 'No',
                          ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      // ---- Timestamps ----
                      _sectionTitle("Timestamps"),
                      const SizedBox(height: 10),
                      _infoCard([
                        _infoRow(
                          "Submitted",
                          _formatTimestamp(_requestData?['createdAt']),
                        ),
                        _infoRow(
                          "Quiz Completed",
                          _formatTimestamp(_requestData?['completedAt']),
                        ),
                        if (_requestData?['reviewedAt'] != null)
                          _infoRow(
                            "Reviewed At",
                            _formatTimestamp(_requestData?['reviewedAt']),
                          ),
                        if (_requestData?['reviewedBy'] != null)
                          _infoRow(
                            "Reviewed By",
                            _requestData?['reviewedBy'],
                          ),
                        if (_requestData?['rejectionReason'] != null)
                          _infoRow(
                            "Rejection Reason",
                            _requestData?['rejectionReason'],
                          ),
                      ]),
                      const SizedBox(height: 20),

                      // ---- Verification Documents ----
                      _sectionTitle("Verification Documents"),
                      const SizedBox(height: 10),
                      _documentsSection(),
                      const SizedBox(height: 28),

                      // ---- Action Buttons ----
                      if (_canAct) _actionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ================= STATUS BANNER =================
  Widget _statusBanner() {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (_currentStatus.toLowerCase()) {
      case 'pending':
      case 'quiz_completed':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        icon = Icons.hourglass_top;
        label = _currentStatus.toUpperCase();
        break;
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
        label = 'APPROVED';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.cancel;
        label = 'REJECTED';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.info;
        label = _currentStatus.toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Text(
            'Status: $label',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DOCUMENTS SECTION =================
  Widget _documentsSection() {
    final docsMap =
        _documentsData?['documents'] as Map<String, dynamic>? ?? {};

    final docEntries = <MapEntry<String, String>>[
      MapEntry('Profile Picture', docsMap['profile'] as String? ?? ''),
      MapEntry('CNIC Front', docsMap['cnicFront'] as String? ?? ''),
      MapEntry('CNIC Back', docsMap['cnicBack'] as String? ?? ''),
      MapEntry('Selfie with CNIC', docsMap['selfie'] as String? ?? ''),
      MapEntry('Tools Photo', docsMap['tools'] as String? ?? ''),
      MapEntry('Police Verification', docsMap['police'] as String? ?? ''),
    ];

    if (docsMap.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.folder_off, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No documents uploaded yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: docEntries.map((entry) {
        return _documentTile(entry.key, entry.value);
      }).toList(),
    );
  }

  // ================= DOCUMENT TILE =================
  Widget _documentTile(String label, String url) {
    final hasUrl = url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  hasUrl ? Icons.image : Icons.image_not_supported,
                  size: 18,
                  color: hasUrl ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (!hasUrl) ...[
                  const Spacer(),
                  Text(
                    'Not uploaded',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasUrl)
            GestureDetector(
              onTap: () => _showFullImage(context, label, url),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Image.network(
                  url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.grey.shade400, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= FULL IMAGE VIEWER =================
  void _showFullImage(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white54, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _actionButtons() {
    return Row(
      children: [
        // Reject button
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _actionLoading ? null : _reject,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close, color: Colors.red),
              label: const Text(
                'Reject',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Approve button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _approve,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Approve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= HELPERS =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final display = value?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display.isEmpty ? 'N/A' : display,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    }
    return ts.toString();
  }
}
