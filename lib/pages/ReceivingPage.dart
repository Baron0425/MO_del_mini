import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReceivingPage extends StatefulWidget {
  final String uid;
  final String name;
  final String profilePicture;

  const ReceivingPage({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
  });

  @override
  State<ReceivingPage> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text('สินค้าที่จะได้รับ', style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .where('receiver_phone', isEqualTo: widget.uid) // สมมติ UID คือเบอร์ของผู้รับ
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ยังไม่มีสินค้าที่จะได้รับ'));
          }

          final shipments = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: shipments.length,
            itemBuilder: (context, index) {
              final data = shipments[index].data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['product_image'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image),
                    ),
                  ),
                  title: Text(
                    data['product_name'] ?? 'ไม่ระบุชื่อสินค้า',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้ส่ง: ${data['sender_name'] ?? '-'}'),
                      Text('เบอร์ผู้ส่ง: ${data['sender_phone'] ?? '-'}'),
                      Text('ที่อยู่ผู้ส่ง: ${data['sender_address'] ?? '-'}'),
                      Text('สถานะ: ${data['status'] ?? '-'}'),
                      SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: () {
                          final lat = data['sender_lat'] ?? 0.0;
                          final lng = data['sender_lng'] ?? 0.0;
                          if (lat != 0.0 && lng != 0.0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShipmentMapPage(
                                  lat: lat,
                                  lng: lng,
                                  senderName: data['sender_name'] ?? '-',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('ไม่มีพิกัดผู้ส่งในระบบตอนนี้')),
                            );
                          }
                        },
                        icon: Icon(Icons.map, color: Colors.white, size: 18),
                        label: Text('ดูพิกัดบนแผนที่'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ShipmentMapPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String senderName;

  const ShipmentMapPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng senderLocation = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text('พิกัดผู้ส่ง: $senderName'),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: senderLocation,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId('sender'),
            position: senderLocation,
            infoWindow: InfoWindow(title: senderName),
          ),
        },
      ),
    );
  }
}
