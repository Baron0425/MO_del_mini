import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

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
  final _productDescription =
      TextEditingController(); // ✅ เพิ่มช่องรายละเอียดสินค้า
  final _receiverPhone = TextEditingController();

  File? _image;
  bool _isLoading = false;

  List<Map<String, dynamic>> _receiverList = [];
  Map<String, dynamic>? _selectedReceiverData;
  String? _selectedAddressType;
  Map<String, dynamic>? _selectedAddressGeo;
  String? _address1Text;
  String? _address2Text;

  final cloudinary = CloudinaryPublic(
    'dmaxl7c40',
    'picture_mobile_02',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _fetchReceivers();
  }

  Future<void> _fetchReceivers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('status', isEqualTo: 'user')
        .get();

    setState(() {
      _receiverList = snapshot.docs.where((doc) => doc.id != widget.uid).map((
        e,
      ) {
        final data = e.data();
        return {
          'id': e.id,
          'name': data['name'],
          'phone': data['phone'],
          'profilePicture': data['profilePicture'],
          'location': data['location'],
          'secondaryLocation': data['secondaryLocation'],
        };
      }).toList();
    });
  }

  Future<String> _getReadableAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address =
            "${p.street ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}"
                .trim();
        return address.isEmpty ? "ไม่พบที่อยู่" : address;
      } else {
        return "ไม่พบที่อยู่";
      }
    } catch (e) {
      print("❌ Reverse geocode error: $e");
      return "ไม่พบที่อยู่";
    }
  }

  Future<void> _loadReceiverAddresses() async {
    if (_selectedReceiverData == null) return;

    setState(() {
      _address1Text = "กำลังโหลด...";
      _address2Text = "กำลังโหลด...";
    });

    final loc1 = _selectedReceiverData!['location'];
    final loc2 = _selectedReceiverData!['secondaryLocation'];

    _address1Text = loc1 != null
        ? await _getReadableAddress(loc1['lat'], loc1['lng'])
        : "ไม่มีที่อยู่หลัก";
    _address2Text = loc2 != null
        ? await _getReadableAddress(loc2['lat'], loc2['lng'])
        : "ไม่มีที่อยู่สำรอง";

    setState(() {});
  }

  Future<void> _searchReceiverByPhone(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกเบอร์โทร')));
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('Users')
        .where('status', isEqualTo: 'user')
        .where('phone', isEqualTo: phone)
        .get();

    if (result.docs.isNotEmpty) {
      final doc = result.docs.first;

      if (doc.id == widget.uid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้รับในระบบ')));
        return;
      }

      final data = doc.data();
      data['id'] = doc.id;
      setState(() {
        _selectedReceiverData = data;
        _selectedAddressType = null;
      });
      await _loadReceiverAddresses();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้รับในระบบ')));
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้า')));
      return;
    }
    if (_selectedReceiverData == null || _selectedAddressGeo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกผู้รับและที่อยู่จัดส่ง')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final upload = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_image!.path, folder: "products"),
      );

      await FirebaseFirestore.instance.collection('deliveries').add({
        'sender_id': widget.uid,
        'sender_name': widget.name,
        'receiver_uid': _selectedReceiverData!['id'],
        'receiver_name': _selectedReceiverData!['name'],
        'receiver_phone': _selectedReceiverData!['phone'],
        'receiver_address': _selectedAddressType == 'main'
            ? _address1Text
            : _address2Text,
        'receiver_lat': _selectedAddressGeo!['lat'],
        'receiver_lng': _selectedAddressGeo!['lng'],
        'product_name': _productName.text.trim(),
        'product_description': _productDescription.text
            .trim(), // ✅ เพิ่มบันทึกรายละเอียด
        'product_image': upload.secureUrl,
        'status': 1,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งสินค้าเรียบร้อย ✅')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectReceiver(Map<String, dynamic> r) {
    setState(() {
      _selectedReceiverData = r;
      _receiverPhone.text = r['phone'];
      _selectedAddressType = null;
    });
    Navigator.pop(context);
    _loadReceiverAddresses();
  }

  void _showReceiverList() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: _receiverList.length,
          itemBuilder: (context, i) {
            final r = _receiverList[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    r['profilePicture'] != null && r['profilePicture'] != ""
                    ? NetworkImage(r['profilePicture'])
                    : null,
                child:
                    (r['profilePicture'] == null || r['profilePicture'] == "")
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(r['name']),
              subtitle: Text(r['phone']),
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
        title: const Text("สร้างรายการส่งสินค้า"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              ElevatedButton.icon(
                onPressed: _showReceiverList,
                icon: const Icon(Icons.list),
                label: const Text("เลือกผู้รับจากลิสต์"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

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

              if (_selectedReceiverData != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          _selectedReceiverData!['profilePicture'] != null &&
                              _selectedReceiverData!['profilePicture'] != ""
                          ? NetworkImage(
                              _selectedReceiverData!['profilePicture'],
                            )
                          : null,
                      child:
                          (_selectedReceiverData!['profilePicture'] == null ||
                              _selectedReceiverData!['profilePicture'] == "")
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(_selectedReceiverData!['name']),
                    subtitle: Text(_selectedReceiverData!['phone']),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "เลือกที่อยู่จัดส่ง:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: Text("ที่อยู่หลัก (${_address1Text ?? '...'})"),
                  value: 'main',
                  groupValue: _selectedAddressType,
                  onChanged: (v) {
                    final loc = _selectedReceiverData!['location'];
                    if (loc == null) return;
                    setState(() {
                      _selectedAddressType = v;
                      _selectedAddressGeo = {
                        'lat': loc['lat'],
                        'lng': loc['lng'],
                      };
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text("ที่อยู่สำรอง (${_address2Text ?? '...'})"),
                  value: 'alt',
                  groupValue: _selectedAddressType,
                  onChanged: (v) {
                    final loc = _selectedReceiverData!['secondaryLocation'];
                    if (loc == null) return;
                    setState(() {
                      _selectedAddressType = v;
                      _selectedAddressGeo = {
                        'lat': loc['lat'],
                        'lng': loc['lng'],
                      };
                    });
                  },
                ),
              ],

              const SizedBox(height: 20),
              TextFormField(
                controller: _productName,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 15),

              // ✅ ช่องรายละเอียดสินค้า
              TextFormField(
                controller: _productDescription,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'กรุณากรอกรายละเอียดสินค้า' : null,
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("ถ่ายภาพ"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("เลือกรูป"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_image!, height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),

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
                        "ส่งสินค้า",
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
