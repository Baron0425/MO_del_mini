import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RiderDeliveryMapPage extends StatefulWidget {
  final String riderUid; // ไรเดอร์ปัจจุบัน
  const RiderDeliveryMapPage({super.key, required this.riderUid});

  @override
  State<RiderDeliveryMapPage> createState() => _RiderDeliveryMapPageState();
}

class _RiderDeliveryMapPageState extends State<RiderDeliveryMapPage> {
  LatLng? riderLocation;
  LatLng? deliveryLocation;
  List<Marker> markers = [];
  List<LatLng> polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _initRiderAndDelivery();
  }

  Future<void> _initRiderAndDelivery() async {
    // ดึงตำแหน่งไรเดอร์ปัจจุบัน
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng riderPos = LatLng(pos.latitude, pos.longitude);

    // ดึงงานที่รับโดยไรเดอร์นี้ (status = 2)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('deliveries')
        .where('status', isEqualTo: 2)
        .where('rider_uid', isEqualTo: widget.riderUid)
        .get();

    if (snapshot.docs.isEmpty) {
      // ไม่มีงานรับแล้ว
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยังไม่มีงานที่คุณรับ')));
      return;
    }

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    LatLng deliveryPos = LatLng(data['receiver_lat'], data['receiver_lng']);

    setState(() {
      riderLocation = riderPos;
      deliveryLocation = deliveryPos;
      markers = [
        Marker(
          point: riderPos,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 50,
          ),
        ),
        Marker(
          point: deliveryPos,
          width: 50,
          height: 50,
          child: const Icon(Icons.location_on, color: Colors.red, size: 50),
        ),
      ];

      polylinePoints = [riderPos, deliveryPos];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (riderLocation == null || deliveryLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('พิกัดสินค้า')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: riderLocation!, // กำหนดจุดเริ่มต้น
          initialZoom: 15, // กำหนด zoom
          maxZoom: 18,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=79ac29ccd24941cd84fa305b8da14ae1',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: markers),
          if (polylinePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints,
                  color: Colors.green,
                  strokeWidth: 4,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
