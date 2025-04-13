import 'package:flutter/material.dart';
import 'package:project/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String tailor_name= "";
  String tailor_email = "";
  String tailor_contact = "";
  String tailor_address = "";
  String tailor_photo = "";
  /// Fetch user data from `tbl_user`
  Future<void> fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser!.id;

      final response = await supabase.from('tbl_tailor').select().eq('tailor_id', user).single();

      setState(() {
        tailor_name = response['tailor_name'] ?? "No Name";
        tailor_email = response['tailor_email'] ?? "No Email";
        tailor_contact = response['tailor_contact'] ?? "No Contact";
        tailor_address = response['tailor_address'] ?? "No Address";
        tailor_photo = response['tailor_photo'] ??
            "https://cdn-icons-png.flaticon.com/512/149/149071.png"; // Default avatar
      });

    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.blue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Profile Details Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(tailor_photo),
                    radius: 75,
                  ),
                  const SizedBox(height: 10),
                  Text(tailor_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(tailor_email, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  Text(tailor_contact, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  Text(tailor_address, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Profile Options
            ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit Profile"),
                  onTap: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text("Change Password"),
                  onTap: () {
                    // Navigate to Change Password Screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  onTap: () async {
                    await supabase.auth.signOut();
                    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
