import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:tailor_app/main.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final primaryColor = const Color(0xFF6A1B9A); // Deep purple from home.dart
  final accentColor = const Color(0xFFE91E63); // Pink accent from home.dart

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  File? pickedImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> districtList = [];
  String? selectedDistrict;
  List<Map<String, dynamic>> placeList = [];
  String? selectedPlace;

  bool isLoading = true;
  String originalPhoto = "";

  @override
  void initState() {
    super.initState();
    fetchDistricts();
    fetchUserProfile();
  }

  /// Fetch Districts from Supabase
  Future<void> fetchDistricts() async {
    try {
      final response = await supabase.from("tbl_district").select();
      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  /// Fetch Places based on selected district
  Future<void> fetchPlaces(String districtId) async {
    try {
      final response =
          await supabase.from("tbl_place").select().eq('district', districtId);
      setState(() {
        placeList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  /// Fetch current user profile
  Future<void> fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('tbl_tailor')
          .select("*,tbl_place(place_name,tbl_district(*))")
          .eq('tailor_id', user)
          .single();

      setState(() {
        nameController.text = response['tailor_name'] ?? "";
        contactController.text = response['tailor_contact'] ?? "";
        addressController.text = response['tailor_address'] ?? "";
        originalPhoto = response['tailor_photo'] ?? "";
        selectedPlace = response['place_id'].toString();
        selectedDistrict =
            response['tbl_place']['tbl_district']['district_id'].toString();
        fetchPlaces(selectedDistrict!);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching user profile: $e");
    }
  }

  /// Handle Profile Image Selection
  Future<void> handleImagePick() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  /// Upload Image to Supabase Storage
  Future<String?> uploadPhoto(File imageFile) async {
    try {
      final bucketName = 'tailor';
      String formattedDate =
          DateFormat('dd-MM-yyyy-HH-mm').format(DateTime.now());
      final filePath = "$formattedDate-${imageFile.path.split('/').last}";

      await supabase.storage.from(bucketName).upload(filePath, imageFile);
      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      print("Error uploading photo: $e");
      return null;
    }
  }

  /// Update Profile
  Future<void> updateProfile() async {
    try {
      final user = supabase.auth.currentUser!.id;

      final String? imageUrl =
          pickedImage != null ? await uploadPhoto(pickedImage!) : originalPhoto;

      await supabase.from('tbl_tailor').update({
        'tailor_name': nameController.text,
        'tailor_contact': contactController.text,
        'tailor_address': addressController.text,
        'tailor_photo': imageUrl ?? '',
        'place_id': selectedPlace,
      }).eq('tailor_id', user);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")));
      Navigator.pop(context, true);
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section with Image Picker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: handleImagePick,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  backgroundImage: pickedImage != null
                                      ? FileImage(pickedImage!)
                                      : (originalPhoto.isNotEmpty
                                          ? NetworkImage(originalPhoto)
                                          : null) as ImageProvider?,
                                  child: (pickedImage == null &&
                                          originalPhoto.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: primaryColor,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Change Profile Photo",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTextField(
                          "Full Name",
                          Icons.person_outline,
                          nameController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Contact Number",
                          Icons.phone_outlined,
                          contactController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Address",
                          Icons.location_on_outlined,
                          addressController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "District",
                          Icons.map_outlined,
                          districtList,
                          selectedDistrict,
                          (String? newValue) {
                            setState(() {
                              selectedDistrict = newValue;
                              selectedPlace = null;
                              fetchPlaces(newValue!);
                            });
                          },
                          "district_id",
                          "district_name",
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Place",
                          Icons.place_outlined,
                          placeList,
                          selectedPlace,
                          (String? newValue) {
                            setState(() {
                              selectedPlace = newValue;
                            });
                          },
                          "place_id",
                          "place_name",
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              "Save Changes",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<Map<String, dynamic>> items,
    String? selectedValue,
    void Function(String?) onChanged,
    String valueKey,
    String labelKey,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item[valueKey].toString(),
            child: Text(item[labelKey].toString()),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
