import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class CreateProductPage extends StatefulWidget {
  final String uid;
  final String name;
  final String profilePicture;

  const CreateProductPage({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
  });

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _receiverAddress = TextEditingController();
  final _receiverName = TextEditingController();

  File? _image;
  bool _isLoading = false;
  LatLng? _receiverLocation;
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _receiverList = [];

  @override
  void initState() {
    super.initState();
    _fetchReceivers();
  }

  /// ✅ ดึงลิสต์ผู้รับจาก Firestore
  Future<void> _fetchReceivers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users') // ใช้ collection Users
        .where('status', isEqualTo: 'user') // กรองเฉพาะ user
        .get();

    setState(() {
      _receiverList = snapshot.docs.map((e) {
        final data = e.data();
        return {
          'id': e.id,
          'name': data['name'],
          'phone': data['phone'],
          'address': data['address'],
          'lat': data['lat'],
          'lng': data['lng'],
        };
      }).toList();
    });
  }

  /// ✅ ค้นหาผู้รับจากเบอร์โทรศัพท์
  Future<void> _searchReceiverByPhone(String phone) async {
    final result = await FirebaseFirestore.instance
        .collection('Users') // ใช้ collection Users
        .where('status', isEqualTo: 'user') // กรองเฉพาะ user
        .where('phone', isEqualTo: phone)
        .get();

    if (result.docs.isNotEmpty) {
      final data = result.docs.first.data();
      setState(() {
        _receiverName.text = data['name'];
        _receiverAddress.text = data['address'];
        _receiverLocation = LatLng(data['lat'], data['lng']);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้รับในระบบ')));
    }
  }

  /// ✅ ถ่ายภาพสินค้าหรือเลือกรูป
  Future<void> _pickImage(bool fromCamera) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  /// ✅ บันทึกข้อมูลการส่งสินค้า
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้า')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // อัปโหลดรูปสินค้า
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('products/$fileName');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      // บันทึกข้อมูล Shipment
      await FirebaseFirestore.instance.collection('deliveries').add({
        'sender_id': widget.uid,
        'sender_name': widget.name,
        'receiver_name': _receiverName.text.trim(),
        'receiver_phone': _receiverPhone.text.trim(),
        'receiver_address': _receiverAddress.text.trim(),
        'receiver_lat': _receiverLocation?.latitude,
        'receiver_lng': _receiverLocation?.longitude,
        'product_name': _productName.text.trim(),
        'product_image': imageUrl,
        'status': 'waiting',
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งสินค้าเรียบร้อย!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ เมื่อเลือกผู้รับจากลิสต์
  void _selectReceiver(Map<String, dynamic> receiver) {
    setState(() {
      _receiverName.text = receiver['name'];
      _receiverPhone.text = receiver['phone'];
      _receiverAddress.text = receiver['address'];
      _receiverLocation = LatLng(receiver['lat'], receiver['lng']);
    });
    Navigator.pop(context);
  }

  /// ✅ แสดง Dialog เลือกผู้รับจากลิสต์
  void _showReceiverList() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: _receiverList.length,
          itemBuilder: (context, i) {
            final r = _receiverList[i];
            return ListTile(
              leading: const Icon(Icons.person_pin_circle, color: Colors.green),
              title: Text(r['name']),
              subtitle: Text("${r['phone']} • ${r['address']}"),
              onTap: () => _selectReceiver(r),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างรายการส่งสินค้า'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ผู้ส่ง: ${widget.name}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.profilePicture),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// ปุ่มเลือกผู้รับจากลิสต์
              ElevatedButton.icon(
                onPressed: _showReceiverList,
                icon: const Icon(Icons.list),
                label: const Text("เลือกผู้รับจากลิสต์"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              /// ช่องค้นหาผู้รับจากเบอร์
              TextFormField(
                controller: _receiverPhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'ค้นหาผู้รับจากเบอร์โทร',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        _searchReceiverByPhone(_receiverPhone.text.trim()),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              /// ชื่อผู้รับ
              TextFormField(
                controller: _receiverName,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้รับ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'กรุณากรอกหรือเลือกชื่อผู้รับ' : null,
              ),
              const SizedBox(height: 10),

              /// ที่อยู่ผู้รับ
              TextFormField(
                controller: _receiverAddress,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ที่อยู่ผู้รับ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'กรุณากรอกหรือเลือกที่อยู่ผู้รับ' : null,
              ),
              const SizedBox(height: 15),

              /// แผนที่
              if (_receiverLocation != null)
                Container(
                  height: 250,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _receiverLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('receiver'),
                        position: _receiverLocation!,
                        infoWindow: InfoWindow(title: _receiverName.text),
                      ),
                    },
                    onMapCreated: (controller) => _mapController = controller,
                  ),
                ),

              /// ข้อมูลสินค้า
              TextFormField(
                controller: _productName,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 15),

              /// ถ่ายภาพหรือเลือกรูป
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("ถ่ายภาพสินค้า"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("เลือกรูปจากแกลเลอรี่"),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 25),

              /// ปุ่มส่งสินค้า
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ส่งสินค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
