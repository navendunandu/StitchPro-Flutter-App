import 'package:flutter/material.dart';
import 'package:project/main.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> complaints = [];
  TextEditingController replyController = TextEditingController();
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select('''
            *,
            tailor:tailor_id(tailor_name),
            user:user_id(user_name)
          ''')
          .order('created_at', ascending: false);
      
      setState(() {
        complaints = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching complaints: $e');
      isLoading = false;
    }
  }

  Future<void> updateComplaintStatus(int complaintId) async {
    if (replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply')),
      );
      return;
    }

    try {
      await supabase
          .from('tbl_complaint')
          .update({
            'complaint_status': 1,
            'complaint_reply': replyController.text.trim()
          })
          .eq('id', complaintId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent successfully')),
      );
      replyController.clear();
      fetchComplaints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reply')),
      );
      print('Error updating complaint: $e');
    }
  }

  Widget buildComplaintCard(Map<String, dynamic> complaint, bool isUserComplaint) {
    final bool isPending = complaint['complaint_status'] == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: isUserComplaint 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User: ${complaint['user']['user_name']}'),
                  Text('About Tailor: ${complaint['tailor']['tailor_name']}',
                      style: const TextStyle(fontSize: 14)),
                ],
              )
            : Text('Tailor: ${complaint['tailor']['tailor_name']}'),
        subtitle: Text(
          complaint['complaint_text'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPending ? Colors.orange : Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPending ? 'Pending' : 'Resolved',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complaint: ${complaint['complaint_text']}'),
                const SizedBox(height: 8),
                Text('Date: ${DateTime.parse(complaint['created_at']).toString().split('.')[0]}'),
                if (complaint['reply'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Reply:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(complaint['complaint_reply']),
                      ],
                    ),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: replyController,
                    decoration: const InputDecoration(
                      labelText: 'Enter reply',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => updateComplaintStatus(complaint['id']),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Reply'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userComplaints = complaints.where((c) => c['user_id'] != null).toList();
    final tailorComplaints = complaints.where((c) => c['user_id'] == null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Complaints'),
            Tab(text: 'Tailor Complaints'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // User Complaints Tab
                userComplaints.isEmpty
                    ? const Center(child: Text('No user complaints'))
                    : ListView.builder(
                        itemCount: userComplaints.length,
                        itemBuilder: (context, index) => buildComplaintCard(userComplaints[index], true),
                      ),
                
                // Tailor Complaints Tab
                tailorComplaints.isEmpty
                    ? const Center(child: Text('No tailor complaints'))
                    : ListView.builder(
                        itemCount: tailorComplaints.length,
                        itemBuilder: (context, index) => buildComplaintCard(tailorComplaints[index], false),
                      ),
              ],
            ),
    );
  }
}
