import 'package:flutter/material.dart';
import 'package:userapp/booktailor.dart';
import 'package:userapp/main.dart';

class TailorProfile extends StatefulWidget {
  final String tailor;
  const TailorProfile({super.key, required this.tailor});

  @override
  State<TailorProfile> createState() => _TailorProfileState();
}

class _TailorProfileState extends State<TailorProfile> {
  String name = "";
  String email = "";
  String contact = "";
  String address = "";
  String photo = "";
  String place = "";
  String district = "";
  bool isLoading = true;

  final primaryColor = const Color(0xFF6A1B9A); // Deep purple from Login
  final accentColor = const Color(0xFFE91E63); // Pink accent from Login

  /// Fetch user data from `tbl_user`
  Future<void> fetchUserProfile() async {
    try {
      String user = widget.tailor;

      final response = await supabase
          .from('tbl_tailor')
          .select("*,tbl_place(place_name,tbl_district(district_name))")
          .eq('tailor_id', user)
          .single();
      setState(() {
        name = response['tailor_name'] ?? "No Name";
        email = response['tailor_email'] ?? "No Email";
        contact = response['tailor_contact'] ?? "No Contact";
        address = response['tailor_address'] ?? "No Address";
        photo = response['tailor_photo'] ?? "";
        place = response['tbl_place']['place_name'] ?? "No Place";
        district = response['tbl_place']['tbl_district']['district_name'] ??
            "No District";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching user profile: $e");
    }
  }

  List<Map<String, dynamic>> myMaterials = [];

  Future<void> fetchMaterials() async {
    try {
      final response = await supabase
          .from("tbl_material")
          .select("*, tbl_clothtype(clothtype_name)")
          .eq('tailor_id', widget.tailor);
      setState(() {
        myMaterials = response;
      });
    } catch (e) {
      print("Error fetching materials: $e");
    }
  }

  // Convert Hex String to Color
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchMaterials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Tailor Profile"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: photo.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0] : "T",
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : ClipOval(
                                  child: Image.network(
                                    photo,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 60,
                                            color: primaryColor),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$place, $district",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile Details Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(Icons.email, "Email", email),
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.phone, "Contact", contact),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                                Icons.location_on, "Address", address),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Book Tailor Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookTailor(id: widget.tailor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Book Tailor",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Materials Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Available Materials",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        myMaterials.isEmpty
                            ? Center(
                                child: Text(
                                  "No materials added yet",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: myMaterials.length,
                                itemBuilder: (context, index) {
                                  final material = myMaterials[index];
                                  final colors = (material['material_colors']
                                              as List?)
                                          ?.map(
                                              (c) => c as Map<String, dynamic>)
                                          .toList() ??
                                      [];
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(12)),
                                          child: material['material_photo'] !=
                                                  null
                                              ? Image.network(
                                                  material['material_photo'],
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                        Icons.image,
                                                        size: 50,
                                                        color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  height: 120,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image,
                                                      size: 50,
                                                      color: Colors.grey),
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                material['tbl_clothtype']
                                                    ['clothtype_name'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                material[
                                                    'material_description'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "₹${material['material_amount']}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                              if (colors.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: colors.map((color) {
                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 12,
                                                          height: 12,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _hexToColor(
                                                                color['hex']),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color:
                                                                    Colors.grey,
                                                                width: 0.5),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          color['name'],
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
