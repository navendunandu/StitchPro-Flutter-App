import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tailor_app/main.dart';

class MyMaterialPage extends StatefulWidget {
  const MyMaterialPage({super.key});

  @override
  _MyMaterialPageState createState() => _MyMaterialPageState();
}

class _MyMaterialPageState extends State<MyMaterialPage> with SingleTickerProviderStateMixin {
  bool _showForm = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  List<Map<String, dynamic>> clothMaterials = [];
  String? selectedClothMaterial;
  List<Map<String, dynamic>> myMaterials = [];
  List<Map<String, String>> selectedColors = [];

  final Map<String, Color> colorMap = {
    'Red': Colors.red,
    'Crimson': const Color(0xFFDC143C),
    'Scarlet': const Color(0xFFFF2400),
    'Maroon': Colors.brown[900]!,
    'Cherry': const Color(0xFFDE3163),
    'Ruby': const Color(0xFFE0115F),
    'Blue': Colors.blue,
    'Navy': Colors.blue[900]!,
    'Sky Blue': Colors.lightBlue,
    'Cyan': Colors.cyan,
    'Turquoise': Colors.teal,
    'Indigo': Colors.indigo,
    'Green': Colors.green,
    'Emerald': const Color(0xFF50C878),
    'Lime': Colors.lime,
    'Olive': Colors.green[800]!,
    'Mint': const Color(0xFF98FF98),
    'Forest Green': const Color(0xFF228B22),
    'Yellow': Colors.yellow,
    'Gold': Colors.yellow[800]!,
    'Amber': Colors.amber,
    'Lemon': const Color(0xFFFFF44F),
    'Mustard': const Color(0xFFFFDB58),
    'Black': Colors.black,
    'Charcoal': Colors.grey[800]!,
    'Slate Gray': Colors.grey[600]!,
    'Silver': Colors.grey[400]!,
    'Ash Gray': Colors.grey,
    'White': Colors.white,
    'Ivory': const Color(0xFFFFFFF0),
    'Cream': const Color(0xFFFFFDD0),
    'Pearl': const Color(0xFFECEFF1),
    'Purple': Colors.purple,
    'Lavender': const Color(0xFFE6E6FA),
    'Violet': Colors.purpleAccent,
    'Plum': const Color(0xFF8E4585),
    'Magenta': Colors.pinkAccent,
    'Orange': Colors.orange,
    'Tangerine': const Color(0xFFF28500),
    'Coral': Colors.orange[300]!,
    'Peach': const Color(0xFFFF9999),
    'Burnt Orange': const Color(0xFFCC5500),
    'Pink': Colors.pink,
    'Rose': const Color(0xFFFF007F),
    'Salmon': Colors.pink[300]!,
    'Fuchsia': const Color(0xFFFF00FF),
    'Blush': const Color(0xFFFFB6C1),
    'Brown': Colors.brown,
    'Chocolate': Colors.brown[700]!,
    'Tan': const Color(0xFFD2B48C),
    'Beige': const Color(0xFFF5F5DC),
    'Taupe': const Color(0xFF483C32),
  };

  List<String> get availableColors => colorMap.keys.toList();

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  Future<void> handleImagePick() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> fetchCloth() async {
    try {
      final response = await supabase.from("tbl_clothtype").select();
      setState(() {
        clothMaterials = response;
      });
    } catch (e) {
      print("Error fetching cloth materials: $e");
    }
  }

  Future<void> fetchMaterials() async {
    try {
      final response = await supabase
          .from("tbl_material")
          .select("*, tbl_clothtype(clothtype_name)");
      setState(() {
        myMaterials = response;
      });
    } catch (e) {
      print("Error fetching materials: $e");
    }
  }

  Future<String?> uploadPhoto(File? imageFile) async {
    if (imageFile == null) return null;

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

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, String>> tempColors = List.from(selectedColors);
        return AlertDialog(
          title: const Text("Select Colors"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: availableColors.map((colorName) {
                      final hex = _colorToHex(colorMap[colorName]!);
                      return CheckboxListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: colorMap[colorName],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(colorName),
                          ],
                        ),
                        value: tempColors.any((c) => c['name'] == colorName),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              tempColors.add({'name': colorName, 'hex': hex});
                            } else {
                              tempColors.removeWhere((c) => c['name'] == colorName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedColors = tempColors;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitMaterial() async {
    if (selectedClothMaterial == null ||
        descriptionController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    if(_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    String? imageUrl = await uploadPhoto(_selectedImage);
    try {
      await supabase.from('tbl_material').insert({
        'clothtype_id': selectedClothMaterial,
        'material_amount': int.tryParse(amountController.text) ?? 0,
        'material_description': descriptionController.text,
        'material_photo': imageUrl,
        'material_colors': selectedColors,
      });

      setState(() {
        selectedClothMaterial = null;
        descriptionController.clear();
        amountController.clear();
        _selectedImage = null;
        selectedColors.clear();
        _isLoading = false;
      });

      fetchMaterials();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material added successfully!")),
      );
    } catch (e) {
      print("Error inserting material: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await supabase.from('tbl_material').delete().eq('material_id', id);
      fetchMaterials();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Material Deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Material Deleting Failed")));
      print("Deleting Failed: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    fetchCloth();
    fetchMaterials();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _showForm = !_showForm;
      if (_showForm) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // Reset form when hiding
        selectedClothMaterial = null;
        descriptionController.clear();
        amountController.clear();
        _selectedImage = null;
        selectedColors.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materials"),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _toggleForm, label: Text("Add Material"), icon: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _animation)),
          // IconButton(
          //   icon: AnimatedIcon(
          //     semanticLabel: "Add Material",
          //     icon: AnimatedIcons.add_event,
          //     progress: _animation,
          //   ),
          //   onPressed: _toggleForm,
          // ),
          SizedBox(width: 10,)
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Section with animation
              SizeTransition(
                sizeFactor: _animation,
                child: FadeTransition(
                  opacity: _animation,
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add New Material",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: handleImagePick,
                              child: _selectedImage != null
                                  ? Container(
                                      height: 200,
                                      width: 300,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(
                                            image: FileImage(_selectedImage!),
                                            fit: BoxFit.cover),
                                      ),
                                    )
                                  : Container(
                                      height: 200,
                                      width: 300,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.grey[300],
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 40, color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedClothMaterial,
                            hint: const Text("Select Cloth Material"),
                            items: clothMaterials.map((data) {
                              return DropdownMenuItem<String>(
                                value: data['clothtype_id'].toString(),
                                child: Text(data['clothtype_name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedClothMaterial = value;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Description",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Amount",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _showColorPickerDialog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      children: selectedColors.isEmpty
                                          ? [
                                              const Text("Select Colors",
                                                  style: TextStyle(
                                                      color: Colors.grey))
                                            ]
                                          : selectedColors.map((color) {
                                              return Chip(
                                                label: Text(color['name']!),
                                                backgroundColor: _hexToColor(
                                                        color['hex']!)
                                                    .withOpacity(0.2),
                                                avatar: CircleAvatar(
                                                  backgroundColor:
                                                      _hexToColor(color['hex']!),
                                                ),
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: () async {
                                      await _submitMaterial();
                                      if (!_isLoading) {
                                        _toggleForm(); // Hide form after successful submission
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("Submit"),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Materials List Section
              const Text(
                "Materials List",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              myMaterials.isEmpty
                  ? const Center(child: Text("No materials added yet"))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myMaterials.length,
                      itemBuilder: (context, index) {
                        final material = myMaterials[index];
                        final colors = (material['material_colors'] as List?)
                                ?.map((c) => c as Map<String, dynamic>)
                                .toList() ??
                            [];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image Section
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: material['material_photo'] != null
                                      ? Image.network(
                                          material['material_photo'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 40),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image,
                                              size: 40, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Details Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Cloth Type and Amount
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            material["tbl_clothtype"]
                                                ["clothtype_name"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "₹${material["material_amount"]}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Description
                                      Text(
                                        material["material_description"],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Colors
                                      if (colors.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: colors.map((color) {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: _hexToColor(
                                                        color['hex']),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  color['name'],
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                                // Delete Button
                                IconButton(
                                  onPressed: () {
                                    deleteMaterial(material['material_id']);
                                  },
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red[400],
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
      ),
    );
  }
}
