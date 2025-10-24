import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/login.dart';
import 'package:image_picker/image_picker.dart';

class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  final phoneCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final registrationCtl = TextEditingController();

  final db = FirebaseFirestore.instance;

  File? profileImage;
  File? vehicleImage;

  final cloudinary = CloudinaryPublic(
    'dmaxl7c40', // ใส่ Cloud name ของคุณ
    'picture_mobile_02', // ใส่ upload preset ของคุณ
    cache: false,
  );

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Rider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneCtl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: passwordCtl,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: registrationCtl,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มเลือกรูปโปรไฟล์
            ElevatedButton.icon(
              onPressed: () => pickImage(true),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
            if (profileImage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Image.file(profileImage!, height: 120),
              ),

            const SizedBox(height: 12),

            // ปุ่มเลือกรูปรถ
            ElevatedButton.icon(
              onPressed: () => pickImage(false),
              icon: const Icon(Icons.motorcycle, color: Colors.white),
              label: const Text(
                'เลือกรูปรถ',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
            if (vehicleImage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Image.file(vehicleImage!, height: 120),
              ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: addDataRider,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
              ),
              child: const Text(
                'Register Rider',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันเลือกรูป
  Future<void> pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (isProfile) {
          profileImage = File(picked.path);
        } else {
          vehicleImage = File(picked.path);
        }
      });
    }
  }

  // ฟังก์ชันอัปโหลดรูปขึ้น Cloudinary
  Future<String?> uploadImageToCloudinary(File imageFile, String folder) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, folder: folder),
      );
      return response.secureUrl;
    } catch (e) {
      print('❌ Upload failed: $e');
      return null;
    }
  }

  // ฟังก์ชันเพิ่มข้อมูล Rider
  void addDataRider() async {
    if (profileImage == null || vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปโปรไฟล์และรูปรถ')),
      );
      return;
    }

    // อัปโหลดรูปขึ้น Cloudinary
    String? profileUrl = await uploadImageToCloudinary(
      profileImage!,
      'profile_pictures',
    );
    String? vehicleUrl = await uploadImageToCloudinary(
      vehicleImage!,
      'vehicle_pictures',
    );

    if (profileUrl == null || vehicleUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ')));
      return;
    }

    // เพิ่มข้อมูลใน Firestore
    final docRef = db.collection('Riders').doc();

    final data = {
      'uid': docRef.id,
      'phone': phoneCtl.text,
      'name': nameCtl.text,
      'password': passwordCtl.text,
      'profilePicture': profileUrl,
      'vehicleImage': vehicleUrl,
      'registration': registrationCtl.text,
      'status': 'rider',
      'createdAt': DateTime.now(),
    };

    await docRef.set(data);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Register Rider Success!')));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
