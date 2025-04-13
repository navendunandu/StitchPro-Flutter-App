import 'package:flutter/material.dart';
import 'package:project/main.dart';

class Manageclothtype extends StatefulWidget {
  const Manageclothtype({super.key});

  @override
  State<Manageclothtype> createState() => _ManageclothtypeState();
}

class _ManageclothtypeState extends State<Manageclothtype> {
  final TextEditingController clothtypeController = TextEditingController();

  Future<void> insert() async {
    try {
      await supabase.from('tbl_clothtype').insert({
        'clothtype_name': clothtypeController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('clothtype Type Added'),
      ));
      clothtypeController.clear();
      fetchclothtype();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed'),
      ));
      print("Error: $e");
    }
  }

  List<Map<String, dynamic>> clothtype = [];

  Future<void> fetchclothtype() async {
    try {
      final response = await supabase.from('tbl_clothtype').select();
     setState(() {
       clothtype = response;
     });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> delete(int id) async {
    try {
      await supabase.from('tbl_clothtype').delete().eq('clothtype_id',id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted")));
                fetchclothtype();
    } catch (e) {
      print("Error: $e");

    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchclothtype();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 56, 232),
        title:  Text('Manage clothtype Type',
        style: TextStyle(color:Colors.red),
        )
     ),
     body: ListView(
      padding: EdgeInsets.all(20),
      children: [
        TextFormField(
          controller: clothtypeController,
          decoration: InputDecoration(
            labelText: "clothtype Type",
            border: OutlineInputBorder()
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Center(child: ElevatedButton(onPressed: (){
          insert();
        }, child: Text("Submit"))),
        SizedBox(
          height: 20,
        ),
        ListView.builder(
          itemCount: clothtype.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final data = clothtype[index];
          return ListTile(
            leading: Text((index + 1).toString()),
            title: Text(data['clothtype_name']),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: ()  {
                delete(data['clothtype_id']);
              },
            ),
          );
        },)
      ],
     ),
    );
  }
}