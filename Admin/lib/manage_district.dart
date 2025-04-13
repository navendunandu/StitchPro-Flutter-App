import 'package:flutter/material.dart';
import 'package:project/main.dart';

class ManageDistrict extends StatefulWidget {
  const ManageDistrict({super.key});

  @override
  State<ManageDistrict> createState() => _ManageDistrictState();
}

class _ManageDistrictState extends State<ManageDistrict> {
  final TextEditingController districtController = TextEditingController();
  bool isAdding = false;

  Future<void> insert() async {
    try {
      await supabase.from('tbl_district').insert({
        'district_name': districtController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('District Added'),
      ));
      districtController.clear();
      fetchdistrict();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to add district'),
      ));
      print("Error: $e");
    }
  }

  Future<void> deleteDistrict(int id) async {
    try {
      await supabase.from('tbl_district').delete().match({'id': id});
      fetchdistrict();
    } catch (e) {
      print("Error: $e");
    }
  }

  List<Map<String, dynamic>> district = [];

  Future<void> fetchdistrict() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() {
        district = response;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchdistrict();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 56, 232),
        title: const Text(
          'Manage Districts',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: districtController,
                    decoration: const InputDecoration(
                      labelText: "District Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isAdding) {
                      insert();
                    }
                    setState(() {
                      isAdding = !isAdding;
                    });
                  },
                  child: Text(isAdding ? "Submit" : "Add District"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("S.No")),
                    DataColumn(label: Text("District Name")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: district.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    Map<String, dynamic> data = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
                      DataCell(Text(data['district_name'])),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                districtController.text = data['district_name'];
                                setState(() {
                                  isAdding = true;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteDistrict(data['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}