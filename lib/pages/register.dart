import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/login.dart';
import 'package:flutter_deliveries_1/pages/register_rider.dart';
import 'package:get/get.dart';

class registerPage extends StatefulWidget {
  const registerPage({super.key});

  @override
  State<registerPage> createState() => _registerPageState();
}

class _registerPageState extends State<registerPage> {
  var phoneCtl = TextEditingController();
  var nameCtl = TextEditingController();
  var passwordCtl = TextEditingController();
  var profilePictureCtl = TextEditingController();
  var addressCtl = TextEditingController();
  var locationCtl = TextEditingController();
  var docCtl = TextEditingController();

  var db = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          TextField(
            controller: nameCtl,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: phoneCtl,
            decoration: InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: passwordCtl,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          TextField(
            controller: profilePictureCtl,
            decoration: InputDecoration(labelText: 'Profile Picture'),
          ),
          TextField(
            controller: addressCtl,
            decoration: InputDecoration(labelText: 'Adresss'),
          ),
          TextField(
            controller: locationCtl,
            decoration: InputDecoration(labelText: 'location'),
          ),
          Column(
            children: [
              FilledButton(onPressed: addData, child: Text('Add Data')),
              FilledButton(
                onPressed: () {
                  Get.to(() => const registerRider());
                },
                child: Text('Register Rider'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void addData() async {
    var docRef = db.collection('Users').doc();

    var data = {
      'uid': docRef.id,
      'name': nameCtl.text,
      'password': passwordCtl.text,
      'phone': phoneCtl.text,
      'profilePicture': profilePictureCtl.text,
      'address': addressCtl.text,
      'location': locationCtl.text,
      'status': 'user',
      'createAt': DateTime.timestamp(),
    };

    await docRef.set(data);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Register Success!')));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}

  // void QueryData() async {
  //   var indexref = db.collection('Users');
  //   var query = indexref.where('name', isEqualTo: nameCtl.text);
  //   var result = await query.get();

  //   if (result.docs.isNotEmpty) {
  //     log(result.docs.first.data()['message']);
  //   } else {
  //     log('No data');
  //   }
  // }

  // void readData() async {
  //   DocumentSnapshot result = await db
  //       .collection('Users')
  //       .doc(docCtl.text)
  //       .get();

  //   var data = result.data();
  //   log(data.toString());
  // }
