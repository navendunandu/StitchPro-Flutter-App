import 'package:flutter/material.dart';
import 'package:project/main.dart';

class AdminTailors extends StatefulWidget {
  const AdminTailors({super.key});

  @override
  State<AdminTailors> createState() => _AdminTailorsState();
}

class _AdminTailorsState extends State<AdminTailors> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  List<Map<String, dynamic>> _newTailors = [];
  List<Map<String, dynamic>> _verifiedTailors = [];
  List<Map<String, dynamic>> _rejectedTailors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTailors();
  }

  Future<void> fetchTailors() async {
    try {
      final response = await supabase
          .from('tbl_tailor')
          .select("*, tbl_place(*,tbl_district(*))");

      setState(() {
        _newTailors = response.where((t) => t['tailor_status'] == 0).toList();
        _verifiedTailors = response.where((t) => t['tailor_status'] == 1).toList();
        _rejectedTailors = response.where((t) => t['tailor_status'] == 2).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching tailors: $e");
      isLoading = false;
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(10),
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  Future<void> verification(String uid, int status) async {
    try {
      String msg = status == 1 ? 'Accepted' : 'Rejected';
      await supabase.from('tbl_tailor').update({
        'tailor_status': status,
      }).eq('tailor_id', uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tailor $msg')),
      );

      fetchTailors(); // Refresh data after update
    } catch (e) {
      print("Verification failed: $e");
    }
  }

  Widget buildTailorList(List<Map<String, dynamic>> tailors, {bool showActions = false}) {
    if (tailors.isEmpty) {
      return Center(child: Text("No tailors found"));
    }
    
    return ListView.builder(
      itemCount: tailors.length,
      itemBuilder: (context, index) {
        var tailor = tailors[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ExpansionTile(
            leading: GestureDetector(
              onTap: () {
                if (tailor['tailor_photo'] != null) {
                  _showImageDialog(tailor['tailor_photo']);
                }
              },
              child: CircleAvatar(
                backgroundImage: tailor['tailor_photo'] == null
                    ? null
                    : NetworkImage(tailor['tailor_photo']),
                child: tailor['tailor_photo'] == null
                    ? Text(tailor['tailor_name'][0])
                    : null,
              ),
            ),
            title: Text(tailor['tailor_name']),
            subtitle: Text(tailor['tailor_contact']),
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email: ${tailor['tailor_email']}"),
                    Text("Address: ${tailor['tailor_address']}"),
                    Text("Place: ${tailor['tbl_place']['place_name']}"),
                    Text("District: ${tailor['tbl_place']['tbl_district']['district_name']}"),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (tailor['tailor_proof'] != null) {
                          _showImageDialog(tailor['tailor_proof']);
                        }
                      },
                      child: Text("View Proof"),
                    ),
                    if (showActions) // Only show accept/reject buttons for new tailors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              verification(tailor['tailor_id'], 1);
                            },
                            label: Text("Accept"),
                            icon: Icon(Icons.check),
                          ),
                          SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              verification(tailor['tailor_id'], 2);
                            },
                            label: Text("Reject"),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Tailors")),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "New Tailors"),
              Tab(text: "Verified Tailors"),
              Tab(text: "Rejected Tailors"),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildTailorList(_newTailors, showActions: true), // New Tailors with Accept/Reject
                      buildTailorList(_verifiedTailors), // Verified Tailors
                      buildTailorList(_rejectedTailors), // Rejected Tailors
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
