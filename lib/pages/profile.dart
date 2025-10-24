import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/login.dart'; // ปรับ path ตามโปรเจกต์
import 'package:get/get.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final String status; // 'user' หรือ 'rider'

  const ProfilePage({super.key, required this.uid, required this.status});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  String phone = '';
  String profilePicture = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    String collection = widget.status == 'rider' ? 'Riders' : 'Users';
    final doc = await _firestore.collection(collection).doc(widget.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        name = data['name'] ?? '';
        phone = data['phone'] ?? '';
        profilePicture = data['profilePicture'] ?? '';
        isLoading = false;
      });
    }
  }

  void _logout() {
    // ออกระบบ → กลับไปหน้า Login
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(phone, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'ออกระบบ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
