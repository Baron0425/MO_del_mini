import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/login.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? pickedLocation;
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    LatLng? loc = await _getCurrentLocation();
    if (loc != null) {
      setState(() {
        currentLocation = loc;
        pickedLocation = loc;
      });
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตำแหน่ง')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation!,
              initialZoom: 15,
              onTap: (tapPos, latlng) {
                setState(() {
                  pickedLocation = latlng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=79ac29ccd24941cd84fa305b8da14ae1',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: pickedLocation != null
                    ? [
                        Marker(
                          point: pickedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ]
                    : [],
              ),
            ],
          ),
          if (pickedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, pickedLocation);
                },
                child: const Text('ยืนยันตำแหน่ง'),
              ),
            ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final phoneCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final passwordCtl = TextEditingController();

  double? latitude;
  double? longitude;
  double? latitudeSecondary;
  double? longitudeSecondary;

  File? selectedImage;
  String? displayImage;
  final db = FirebaseFirestore.instance;

  final cloudinary = CloudinaryPublic(
    'dmaxl7c40', // เปลี่ยนเป็นของคุณ
    'picture_mobile_02', // เปลี่ยนเป็นของคุณ
    cache: false,
  );

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        displayImage = selectedImage!.path;
      });
    }
  }

  Future<String?> uploadImageToCloudinary() async {
    if (selectedImage == null) return null;
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          selectedImage!.path,
          folder: 'profile_pictures',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  void registerUser() async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งหลักก่อน')),
      );
      return;
    }

    String? imageUrl = await uploadImageToCloudinary();

    final docRef = db.collection('Users').doc();

    final data = {
      'uid': docRef.id,
      'name': nameCtl.text,
      'phone': phoneCtl.text,
      'password': passwordCtl.text,
      'profilePicture': imageUrl ?? '',
      'location': {'lat': latitude, 'lng': longitude},
      'secondaryLocation': latitudeSecondary != null
          ? {'lat': latitudeSecondary, 'lng': longitudeSecondary}
          : null,
      'status': 'user',
      'createAt': Timestamp.now(),
    };

    await docRef.set(data);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Register Success!')));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildTextField(
    TextEditingController ctl,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: ctl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create an account',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Connect with your friends today!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildTextField(nameCtl, 'Username', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(phoneCtl, 'Phone Number', Icons.phone),
            const SizedBox(height: 12),
            _buildTextField(passwordCtl, 'Password', Icons.lock, obscure: true),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Add Profile Image'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
            if (displayImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: displayImage!.startsWith('http')
                    ? Image.network(displayImage!, height: 120)
                    : Image.file(File(displayImage!), height: 120),
              ),
            const SizedBox(height: 12),

            // ปุ่มเลือกที่อยู่หลัก
            ElevatedButton.icon(
              onPressed: () async {
                LatLng? loc = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                );
                if (loc != null) {
                  setState(() {
                    latitude = loc.latitude;
                    longitude = loc.longitude;
                  });
                }
              },
              icon: const Icon(Icons.location_on),
              label: Text(
                latitude != null && longitude != null
                    ? 'ที่อยู่หลักเลือกแล้ว'
                    : 'เลือกที่อยู่หลัก',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
            const SizedBox(height: 12),

            // ปุ่มเลือกที่อยู่สำรอง
            ElevatedButton.icon(
              onPressed: () async {
                LatLng? loc = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                );
                if (loc != null) {
                  setState(() {
                    latitudeSecondary = loc.latitude;
                    longitudeSecondary = loc.longitude;
                  });
                }
              },
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                latitudeSecondary != null && longitudeSecondary != null
                    ? 'ที่อยู่สำรองเลือกแล้ว'
                    : 'เลือกที่อยู่สำรอง',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
            const SizedBox(height: 12),

            FilledButton(
              onPressed: registerUser,
              child: const Text('Sign Up'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => const LoginPage());
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
