import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:tailor_app/login.dart';
import 'package:tailor_app/main.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController proofController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();

  File? pickedImage;
  File? pickedProof;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _currentStep = 0;

  List<Map<String, dynamic>> districtList = [];
  String? selectedDistrict;
  List<Map<String, dynamic>> placeList = [];
  String? selectedPlace;
  
  // List of specializations for tailors
  final List<String> specializations = [
    "Men's Wear",
    "Women's Wear",
    "Alterations",
    "Custom Design",
    "Wedding Attire",
    "Ethnic Wear",
    "Western Wear",
    "Children's Clothing"
  ];
  List<String> selectedSpecializations = [];

  /// Fetch Districts from Supabase
  Future<void> fetchDistricts() async {
    try {
      final response = await supabase.from("tbl_district").select();
      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching districts: $e");
      _showErrorSnackBar("Failed to load districts. Please try again.");
    }
  }

  /// Fetch Places based on selected district
  Future<void> fetchPlaces(String districtId) async {
    try {
      final response = await supabase.from("tbl_place").select().eq('district', districtId);
      setState(() {
        placeList = List<Map<String, dynamic>>.from(response);
        selectedPlace = null; // Reset place selection
      });
    } catch (e) {
      print("Error fetching places: $e");
      _showErrorSnackBar("Failed to load places. Please try again.");
    }
  }

  /// Handle Profile Image Selection
  Future<void> handleImagePick() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  /// Handle Proof File Selection
  Future<void> handleProofPick() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        pickedProof = File(image.path);
        proofController.text = image.name; // Show filename in text field
      });
    }
  }

  /// Upload Image to Supabase Storage
  Future<String?> uploadPhoto(File imageFile, String bucketName) async {
    try {
      String formattedDate = DateFormat('dd-MM-yyyy-HH-mm-ss').format(DateTime.now());
      final filePath = "$formattedDate-${imageFile.path.split('/').last}";

      await supabase.storage.from(bucketName).upload(filePath, imageFile);

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      print("Error uploading photo: $e");
      return null;
    }
  }

  /// Validate form fields
  bool validateForm() {
    if (_formKey.currentState?.validate() != true) {
      return false;
    }
    
    if (selectedDistrict == null) {
      _showErrorSnackBar("Please select a district");
      return false;
    }
    
    if (selectedPlace == null) {
      _showErrorSnackBar("Please select a place");
      return false;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorSnackBar("Passwords do not match");
      return false;
    }
    
    if (pickedImage == null) {
      _showErrorSnackBar("Please upload your profile photo");
      return false;
    }
    
    if (pickedProof == null) {
      _showErrorSnackBar("Please upload your ID proof");
      return false;
    }
    return true;
  }

  /// Register User
  Future<void> register() async {
    if (!validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String? imageUrl = pickedImage != null ? await uploadPhoto(pickedImage!, 'tailor') : null;
      final String? proofUrl = pickedProof != null ? await uploadPhoto(pickedProof!, 'tailor') : null;

      await supabase.auth.signUp(
        email: emailController.text, 
        password: passwordController.text
      );
      await supabase.from('tbl_tailor').insert({
        'tailor_name': nameController.text,
        'tailor_email': emailController.text,
        'tailor_contact': contactController.text,
        'tailor_address': addressController.text,
        'tailor_password': passwordController.text,
        'tailor_photo': imageUrl ?? '',
        'tailor_proof': proofUrl ?? '',
        'place_id': selectedPlace,
        'tailor_status': 0, 
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration successful! Your account is pending approval."),
          backgroundColor: Colors.green,
        )
      );
      
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => Login())
      );
    } catch (e) {
      if (!mounted) return;
      
      _showErrorSnackBar("Registration failed: ${e.toString()}");
      print("Registration Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }

  @override
  void initState() {
    super.initState();
    fetchDistricts();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    proofController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6A1B9A); // Deep purple for fashion theme
    final accentColor = Color(0xFFE91E63); // Pink accent
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                register();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentStep == 2 ? (_isLoading ? "Registering..." : "Register") : "Continue"
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("Back"),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Basic Information
              Step(
                title: Text("Profile"),
                content: _buildBasicInfoStep(primaryColor, accentColor),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              // Step 2: Location & Specialization
              Step(
                title: Text("Details"),
                content: _buildLocationStep(primaryColor, accentColor),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              // Step 3: Account Security
              Step(
                title: Text("Security"),
                content: _buildSecurityStep(primaryColor, accentColor),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBasicInfoStep(Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Text(
                "Create Your Tailor Profile",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Let's start with your basic information",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // Profile Image Picker
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 3,
                  ),
                  image: pickedImage != null
                      ? DecorationImage(
                          image: FileImage(pickedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pickedImage == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: handleImagePick,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // Name Field
        _buildFormField(
          controller: nameController,
          label: "Full Name",
          hint: "Enter your full name",
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your name";
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
        SizedBox(height: 16),
        
        // Email Field
        _buildFormField(
          controller: emailController,
          label: "Email Address",
          hint: "Enter your email address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your email";
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return "Please enter a valid email";
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
        SizedBox(height: 16),
        
        // Contact Field
        _buildFormField(
          controller: contactController,
          label: "Phone Number",
          hint: "Enter your phone number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your phone number";
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildLocationStep(Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Address Information", primaryColor, accentColor),
        SizedBox(height: 16),
        
        // Address Field
        _buildFormField(
          controller: addressController,
          label: "Address",
          hint: "Enter your shop/business address",
          icon: Icons.home_outlined,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your address";
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
        SizedBox(height: 16),
        
        // District Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedDistrict,
            hint: Text("Select District"),
            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city, color: primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: districtList.map((data) {
              return DropdownMenuItem<String>(
                value: data['district_id'].toString(),
                child: Text(data['district_name']),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedDistrict = newValue;
                selectedPlace = null;
                placeList.clear();
              });
              fetchPlaces(newValue!);
            },
            isExpanded: true,
            dropdownColor: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        
        // Place Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedPlace,
            hint: Text("Select Place"),
            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.place, color: primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: placeList.map((data) {
              return DropdownMenuItem<String>(
                value: data['place_id'].toString(),
                child: Text(data['place_name']),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedPlace = newValue;
              });
            },
            isExpanded: true,
            dropdownColor: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        
        
        // Proof Document
        Text(
          "Upload ID Proof",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        
        GestureDetector(
          onTap: handleProofPick,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pickedProof != null ? primaryColor : Colors.grey.shade300,
                width: pickedProof != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    pickedProof != null ? Icons.check_circle : Icons.upload_file,
                    color: pickedProof != null ? Colors.green : primaryColor,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickedProof != null ? "Document Uploaded" : "Upload ID Proof",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        pickedProof != null
                            ? proofController.text
                            : "Tap to upload your ID proof (Aadhar, PAN, etc.)",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStep(Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Account Security", primaryColor, accentColor),
        SizedBox(height: 16),
        
        // Password Field
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a password";
            }
            if (value.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: "Password",
            hintText: "Create a secure password",
            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        SizedBox(height: 16),
        
        // Confirm Password Field
        TextFormField(
          controller: confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please confirm your password";
            }
            if (value != passwordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: "Confirm Password",
            hintText: "Confirm your password",
            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        SizedBox(height: 24),
        
        // Terms and Conditions
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    "Important Information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "By registering, you agree to our Terms of Service and Privacy Policy. Your account will be reviewed by our team before approval.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Your profile will be visible to customers after approval",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                "• You'll be notified via email once your account is approved",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Color primaryColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}