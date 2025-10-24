import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/login.dart';

class registerRider extends StatefulWidget {
  const registerRider({super.key});

  @override
  State<registerRider> createState() => _registerRiderState();
}

class _registerRiderState extends State<registerRider> {
  var phoneCtl = TextEditingController();
  var nameCtl = TextEditingController();
  var passwordCtl = TextEditingController();
  var profilePictureCtl = TextEditingController();
  var vehicleCtl = TextEditingController();
  var registrotionCtl = TextEditingController();
  var db = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Rider')),
      body: Column(
        children: [
          TextField(
            controller: phoneCtl,
            decoration: InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: nameCtl,
            decoration: InputDecoration(labelText: 'Name'),
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
            controller: vehicleCtl,
            decoration: InputDecoration(labelText: 'vehicle'),
          ),
          TextField(
            controller: registrotionCtl,
            decoration: InputDecoration(labelText: 'Registrotion Number'),
          ),
          Column(
            children: [
              FilledButton(onPressed: addDataRider, child: Text('Add Data')),
              FilledButton(onPressed: () {}, child: Text('Register Rider')),
            ],
          ),
        ],
      ),
    );
  }

  void addDataRider() async {
    var docRef = db.collection('Riders').doc();

    var data = {
      'uid': docRef.id,
      'phone': phoneCtl.text,
      'name': nameCtl.text,
      'password': passwordCtl.text,
      'profilePicture': profilePictureCtl.text,
      'vehicle': vehicleCtl.text,
      'registration': registrotionCtl.text,
      'status': 'rider',
      'createAt': DateTime.timestamp(),
    };

    await docRef.set(data);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Register Rider Success!')));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
