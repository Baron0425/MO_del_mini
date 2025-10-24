import 'dart:async';
import 'dart:io';
import 'dart:math'; // เพิ่มตรงนี้
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class ShippingPage extends StatefulWidget {
  final String riderId;
  final String riderName;

  const ShippingPage({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<ShippingPage> createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  final _location = Location();
  StreamSubscription<LocationData>? _locationSub;
  LocationData? _currentLocation;
  bool _isLoading = false;
  File? _statusImage;

  Set<String> _acceptedShipments = {}; // เก็บ ID ของงานที่รับแล้ว

  @override
  void initState() {
    super.initState();
    _listenLocation();
  }

  void _listenLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    _locationSub = _location.onLocationChanged.listen((loc) {
      setState(() => _currentLocation = loc);
      FirebaseFirestore.instance.collection('riders').doc(widget.riderId).set({
        'rider_id': widget.riderId,
        'rider_name': widget.riderName,
        'current_lat': loc.latitude,
        'current_lng': loc.longitude,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _statusImage = File(picked.path));
  }

  Future<void> _updateShipmentStatus(
      String shipmentId, String status) async {
    if (_statusImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาถ่ายรูปสถานะ')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('shipment_status/${shipmentId}_${status}.jpg');
      await ref.putFile(_statusImage!);
      final imgUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(shipmentId)
          .update({
        'status': status,
        'status_images.$status': imgUrl,
        'rider_id': widget.riderId,
        'rider_name': widget.riderName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะ: $status เรียบร้อย!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptShipment(String shipmentId) async {
    if (_acceptedShipments.contains(shipmentId)) return;

    await FirebaseFirestore.instance
        .collection('deliveries')
        .doc(shipmentId)
        .update({
      'rider_id': widget.riderId,
      'rider_name': widget.riderName,
      'status': 'accepted',
    });

    setState(() => _acceptedShipments.add(shipmentId));
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371e3;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lng2 - lng1) * pi / 180;

    final a = (sin(dPhi / 2) * sin(dPhi / 2)) +
        (cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการขนส่งสินค้า'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .where('status', isEqualTo: 'waiting')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final shipments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: shipments.length,
            itemBuilder: (context, index) {
              final shipment = shipments[index];
              final data = shipment.data() as Map<String, dynamic>;
              final isAccepted = _acceptedShipments.contains(shipment.id);

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: data['product_image'] != null
                      ? Image.network(data['product_image'], width: 50)
                      : Icon(Icons.inventory),
                  title: Text(data['product_name'] ?? 'ไม่ระบุสินค้า'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้ส่ง: ${data['sender_name'] ?? ''}'),
                      Text('ผู้รับ: ${data['receiver_phone'] ?? ''}'),
                      Text('ที่อยู่: ${data['receiver_address'] ?? ''}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAccepted ? Colors.grey : Colors.green,
                    ),
                    onPressed: isAccepted
                        ? null
                        : () async {
                            await _acceptShipment(shipment.id);
                          },
                    child: Text(isAccepted ? 'รับแล้ว' : 'รับงาน'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _currentLocation == null
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'พิกัดปัจจุบัน: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}')));
              },
              child: Icon(Icons.location_on),
            ),
    );
  }
}
