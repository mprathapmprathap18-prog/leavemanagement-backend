import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  final String userName;

  const StudentDashboard({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _leaveHistory = [];
  String? _submitMessage;
  bool _submitSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaveHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _leaveTypeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveHistory() async {
    setState(() => _isLoadingHistory = true);
    final apiService = context.read<ApiService>();
    final result = await apiService.getMyLeaves();

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (result['success'] == true) {
          _leaveHistory = List<Map<String, dynamic>>.from(result['leaves'] ?? []);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_leaveTypeController.text.isEmpty ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final apiService = context.read<ApiService>();
    final result = await apiService.submitLeave(
      leaveType: _leaveTypeController.text,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      reason: _reasonController.text,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitSuccess = result['success'] == true;
        _submitMessage = result['message'] ?? result['error'];
      });

      if (_submitSuccess) {
        _leaveTypeController.clear();
        _reasonController.clear();
        _startDate = null;
        _endDate = null;
        await Future.delayed(const Duration(seconds: 2));
        _loadLeaveHistory();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_submitMessage ?? 'Request failed'),
          backgroundColor: _submitSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'MANAGER_APPROVED':
        return 'Approved by Manager';
      case 'MANAGER_REJECTED':
        return 'Rejected by Manager';
      case 'TUTOR_APPROVED':
        return 'Approved by Tutor ✓';
      case 'TUTOR_REJECTED':
        return 'Rejected by Tutor';
      case 'PENDING':
        return 'Pending Approval';
      default:
        return status;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'TUTOR_APPROVED':
        return Colors.green;
      case 'MANAGER_REJECTED':
      case 'TUTOR_REJECTED':
        return Colors.red;
      case 'MANAGER_APPROVED':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
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
            color: const Color(0xFF1976D2),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
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
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Submit Leave'),
              Tab(text: 'Leave History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Submit Leave Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submit a Leave Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _leaveTypeController,
                        decoration: InputDecoration(
                          labelText: 'Leave Type',
                          hintText: 'e.g., Sick, Casual, Medical',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Start Date
                      GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _startDate == null
                                      ? 'Start Date'
                                      : DateFormat('dd/MM/yyyy')
                                      .format(_startDate!),
                                  style: TextStyle(
                                    color: _startDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // End Date
                      GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _endDate == null
                                      ? 'End Date'
                                      : DateFormat('dd/MM/yyyy')
                                      .format(_endDate!),
                                  style: TextStyle(
                                    color: _endDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          hintText: 'Explain why you need this leave',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitLeave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : const Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Leave History Tab
                _isLoadingHistory
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : _leaveHistory.isEmpty
                    ? const Center(
                  child: Text('No leaves submitted yet'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaveHistory.length,
                  itemBuilder: (context, index) {
                    final leave = _leaveHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  leave['leave_type'] ??
                                      'Leave Request',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(
                                      leave['status'] ?? '',
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusColor(
                                      leave['status'] ?? '',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${leave['start_date']} to ${leave['end_date']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              leave['reason'] ?? '',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
