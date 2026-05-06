import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class TutorDashboard extends StatefulWidget {
  final String userName;

  const TutorDashboard({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingLeaves = [];
  Map<int, String> _commentsMap = {};
  Map<int, bool> _processingMap = {};

  @override
  void initState() {
    super.initState();
    _loadPendingLeaves();
  }

  Future<void> _loadPendingLeaves() async {
    setState(() => _isLoading = true);
    final apiService = context.read<ApiService>();
    final result = await apiService.getTutorPendingLeaves();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _pendingLeaves = List<Map<String, dynamic>>.from(result['leaves'] ?? []);
        }
      });
    }
  }

  Future<void> _approveLeave(
      int leaveId,
      bool approve, {
        String? comments,
      }) async {
    setState(() => _processingMap[leaveId] = true);

    final apiService = context.read<ApiService>();
    final result = await apiService.approveLeaveByTutor(
      leaveId: leaveId,
      status: approve ? 'APPROVED' : 'REJECTED',
        comments: _commentsMap[leaveId] ??"",
    );

    if (mounted) {
      setState(() => _processingMap[leaveId] = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? result['error']),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (result['success'] == true) {
        _loadPendingLeaves();
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> leave) {
    final commentController =
    TextEditingController(text: _commentsMap[leave['id']] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Approval - Leave Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${leave['student_name'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Student ID: ${leave['student_id'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Leave Type: ${leave['leave_type'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Duration: ${leave['start_date']} to ${leave['end_date']}',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Approved by Manager',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(leave['reason'] ?? 'No reason provided'),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Your Comments (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Add final approval comments...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _commentsMap[leave['id']] = commentController.text;
              Navigator.pop(ctx);
              _approveLeave(leave['id'], false);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _commentsMap[leave['id']] = commentController.text;
              Navigator.pop(ctx);
              _approveLeave(leave['id'], true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Final Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingLeaves,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthService>().logout();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Card
          Container(
            color: Colors.deepPurple,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tutor,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Info Section
          Container(
            color: Colors.deepPurple.shade50,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Pending Final Approvals: ${_pendingLeaves.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          // Leave Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingLeaves.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending approvals',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadPendingLeaves,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingLeaves.length,
                itemBuilder: (context, index) {
                  final leave = _pendingLeaves[index];
                  final isProcessing = _processingMap[leave['id']] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      leave['student_name'] ??
                                          'Unknown Student',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${leave['student_id'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Final Approval',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Manager Status Badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Manager Approved',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leave Type: ${leave['leave_type'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Duration: ${leave['start_date']} to ${leave['end_date']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            leave['reason'] ?? 'No reason provided',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () =>
                                      _approveLeave(leave['id'], false),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () =>
                                      _showApprovalDialog(leave),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Review'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isProcessing)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(),
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
}
