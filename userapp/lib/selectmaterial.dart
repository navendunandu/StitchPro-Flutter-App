import 'package:flutter/material.dart';
import 'package:userapp/form_validation.dart';
import 'package:userapp/main.dart';

class SelectMaterial extends StatefulWidget {
  final String tailor;
  final Map<String, dynamic>? dress; // Optional dress data for editing
  const SelectMaterial({super.key, required this.tailor, this.dress});

  @override
  State<SelectMaterial> createState() => _SelectMaterialState();
}

class _SelectMaterialState extends State<SelectMaterial> {
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> category = [];
  Map<String, dynamic> selectedMaterial = {};
  List<Map<String, dynamic>> attribute = [];
  List<Map<String, dynamic>> selectedAttribute = [];
  String? selectedCategory;
  final TextEditingController _remarkController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final primaryColor = const Color(0xFF6A1B9A);
  final accentColor = const Color(0xFFE91E63);

  Future<void> fetchMaterial() async {
    try {
      final response = await supabase
          .from("tbl_material")
          .select("*, tbl_clothtype(*)")
          .eq('tailor_id', widget.tailor);
      setState(() {
        materials = response;
        if (widget.dress != null && selectedMaterial.isEmpty) {
          selectedMaterial = materials.firstWhere(
            (m) => m['material_id'] == widget.dress!['material_id'],
            orElse: () => {},
          );
        }
      });
    } catch (e) {
      print("Error fetching materials: $e");
    }
  }

  Future<void> fetchCategory() async {
    try {
      final response = await supabase.from("tbl_category").select();
      setState(() {
        category = response;
        if (widget.dress != null && selectedCategory == null) {
          selectedCategory = widget.dress!['category_id'].toString();
          getAttribute(selectedCategory!);
        }
      });
    } catch (e) {
      print("Error fetching category: $e");
    }
  }

  Future<void> getAttribute(String id) async {
    try {
      final response =
          await supabase.from("tbl_attribute").select().eq('category_id', id);
      setState(() {
        attribute = response;
        if (widget.dress != null && selectedAttribute.isEmpty) {
          final measurements =
              widget.dress!['tbl_measurement'] as List<dynamic>;
          selectedAttribute = measurements.map((m) {
            return {
              'attribute_id': m['attribute_id'],
              'value': m['measurement_value'].toString(),
            };
          }).toList();
        }
      });
    } catch (e) {
      print("Error fetching attribute: $e");
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  void showMaterials() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Select Material",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: materials.map((material) {
                  final colors = (material['material_colors'] as List?)
                          ?.map((c) => c as Map<String, dynamic>)
                          .toList() ??
                      [];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedMaterial = material;
                        });
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: material['material_photo'] != null
                                  ? Image.network(
                                      material['material_photo'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image,
                                            size: 30, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image,
                                          size: 30, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material['tbl_clothtype']['clothtype_name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (colors.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: colors.map((color) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    _hexToColor(color['hex']),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              color['name'],
                                              style:
                                                  const TextStyle(fontSize: 12),
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
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchMaterial();
    fetchCategory();
    if (widget.dress != null) {
      _remarkController.text = widget.dress!['dress_remark'] ?? "";
    }
  }

  Future<void> booking() async {
    try {
      int? bookingId = await getBooking();
      if (bookingId != null) {
        if (widget.dress != null) {
          await supabase.from('tbl_dress').update({
            'material_id': selectedMaterial['material_id'],
            'dress_remark': _remarkController.text,
            'category_id': selectedCategory,
          }).eq('dress_id', widget.dress!['dress_id']);

          await supabase
              .from('tbl_measurement')
              .delete()
              .eq('dress_id', widget.dress!['dress_id']);

          for (var attr in selectedAttribute) {
            await supabase.from('tbl_measurement').insert({
              'dress_id': widget.dress!['dress_id'],
              'attribute_id': attr['attribute_id'],
              'measurement_value': double.parse(attr['value']),
            });
          }
          print("Dress updated successfully.");
        } else {
          final response = await supabase
              .from('tbl_dress')
              .insert({
                'material_id': selectedMaterial['material_id'],
                'booking_id': bookingId,
                'dress_remark': _remarkController.text,
                'category_id': selectedCategory,
              })
              .select()
              .single();

          for (var attr in selectedAttribute) {
            await supabase.from('tbl_measurement').insert({
              'dress_id': response['dress_id'],
              'attribute_id': attr['attribute_id'],
              'measurement_value': double.parse(attr['value']),
            });
          }
          print("Dress added successfully: $response");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.dress != null
                ? "Dress updated successfully."
                : "Dress added successfully."),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        print("No booking found to update.");
      }
    } catch (e) {
      print("Error booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save dress."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<int?> getBooking() async {
    try {
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('tailor_id', widget.tailor)
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('status', 0)
          .maybeSingle()
          .limit(1);
      if (booking != null) {
        print("Booking exists: $booking");
        return booking['id'];
      } else {
        final response = await supabase
            .from('tbl_booking')
            .insert({'tailor_id': widget.tailor})
            .select()
            .single();
        print("Booking created: $response");
        return response['id'];
      }
    } catch (e) {
      print("Error getting booking: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dress != null ? "Edit Dress" : "Select Material"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              validator: (value) => FormValidation.validateDropdown(value),
              hint: const Text('Select Category'),
              items: category.map((categoryItem) {
                return DropdownMenuItem<String>(
                  value: categoryItem['category_id'].toString(),
                  child: Text(categoryItem['category_name']),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedCategory = newValue;
                  selectedAttribute = [];
                });
                getAttribute(newValue!);
              },
              decoration: InputDecoration(
                labelText: "Category",
                labelStyle: TextStyle(color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: showMaterials,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Select Material",
                style:
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            if (selectedMaterial.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Material",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: selectedMaterial['material_photo'] != null
                                ? Image.network(
                                    selectedMaterial['material_photo'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image,
                                          size: 30, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image,
                                        size: 30, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedMaterial['tbl_clothtype']
                                      ['clothtype_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (selectedMaterial['material_colors'] !=
                                        null &&
                                    (selectedMaterial['material_colors']
                                            as List)
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children:
                                        (selectedMaterial['material_colors']
                                                as List)
                                            .map((color) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _hexToColor(color['hex']),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.grey,
                                                  width: 0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            color['name'],
                                            style:
                                                const TextStyle(fontSize: 12),
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
                    ],
                  ),
                ),
              ),
            ],
            buildAttribute(),
            const SizedBox(height: 10),
            TextFormField(
              validator: (value) => FormValidation.validateField(value),
              controller: _remarkController,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: "Remarks",
                labelStyle: TextStyle(color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (selectedMaterial.isNotEmpty) {
                    booking();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Please select a material."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save",
                style:
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAttribute() {
    if (attribute.isEmpty) {
      return const Center(
        child: Text("No attributes available for this category."),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: attribute.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final attributeId = attribute[index]['attribute_id'];
        final attributeName = attribute[index]['attribute_name'];
        String initialValue = '';
        if (widget.dress != null) {
          final existing =
              (widget.dress!['tbl_measurement'] as List<dynamic>).firstWhere(
            (m) => m['attribute_id'] == attributeId,
            orElse: () => {'measurement_value': ''},
          );
          initialValue = existing['measurement_value'].toString();
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: TextFormField(
            initialValue: initialValue,
            validator: (value) => FormValidation.validateField(value),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffix: Text(
                'CM',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              labelText: attributeName,
              labelStyle: TextStyle(color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() {
                final existingIndex = selectedAttribute.indexWhere(
                  (item) => item['attribute_id'] == attributeId,
                );
                if (existingIndex != -1) {
                  selectedAttribute[existingIndex]['value'] = value;
                } else {
                  selectedAttribute.add({
                    'attribute_id': attributeId,
                    'value': value,
                  });
                }
              });
            },
          ),
        );
      },
    );
  }
}
