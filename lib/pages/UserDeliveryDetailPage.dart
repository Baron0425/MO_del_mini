import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/rider_delivery_map_page.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class UserDeliveryDetailPage extends StatelessWidget {
  final String deliveryId;

  const UserDeliveryDetailPage({super.key, required this.deliveryId});

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.name ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}';
      }
      return '-';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('ไม่พบข้อมูลการจัดส่ง')),
          );
        }

        String statusText = '';
        Color statusColor = Colors.black;
        switch (data['status']) {
          case 1:
            statusText = 'รอไรเดอร์รับสินค้า';
            statusColor = Colors.orange;
            break;
          case 2:
            statusText = 'ไรเดอร์กำลังไปรับสินค้า';
            statusColor = Colors.blue;
            break;
          case 3:
            statusText = 'กำลังจัดส่ง';
            statusColor = Colors.green;
            break;
          case 4:
            statusText = 'จัดส่งสำเร็จ';
            statusColor = Colors.grey;
            break;
          default:
            statusText = 'ไม่ทราบสถานะ';
        }

        String? displayImage =
            data['delivered_image'] ??
            data['pickup_image'] ??
            data['product_image'];

        final canViewMap = (data['status'] ?? 1) >= 2;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('รายละเอียดงานจัดส่ง'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // สถานะ
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 10),

                // รูปภาพสินค้า
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    displayImage ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ชื่อสินค้า
                _buildDetailRow(
                  Icons.shopping_bag,
                  'สินค้า',
                  data['product_name'] ?? 'ไม่ระบุ',
                ),

                const Divider(height: 24),

                // ข้อมูลผู้จัดส่ง
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(data['sender_id'])
                      .get(),
                  builder: (context, senderSnapshot) {
                    if (senderSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!senderSnapshot.hasData ||
                        !senderSnapshot.data!.exists) {
                      return const Text('ไม่พบข้อมูลผู้จัดส่ง');
                    }

                    final senderData =
                        senderSnapshot.data!.data() as Map<String, dynamic>;
                    final loc = senderData['location'];
                    final senderLat = loc?['lat'] as double?;
                    final senderLng = loc?['lng'] as double?;

                    return FutureBuilder<String>(
                      future: senderLat != null && senderLng != null
                          ? _getAddressFromLatLng(senderLat, senderLng)
                          : Future.value('ไม่ทราบที่อยู่'),
                      builder: (context, addrSnapshot) {
                        final senderAddress =
                            addrSnapshot.data ?? 'กำลังโหลดที่อยู่...';

                        return Column(
                          children: [
                            _buildInfoCard('ข้อมูลผู้จัดส่ง', {
                              'name': senderData['name'],
                              'phone': senderData['phone'],
                              'address': senderAddress,
                            }),
                            const SizedBox(height: 16),
                            // ข้อมูลไรเดอร์
                            _buildInfoCard('ข้อมูลไรเดอร์', {
                              'name': data['rider_name'],
                              'phone': data['rider_phone'],
                              'address': data['rider_address'] ?? 'ไม่ระบุ',
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ปุ่มดูแผนที่
                ElevatedButton.icon(
                  onPressed: canViewMap
                      ? () async {
                          final deliveryLat = data['receiver_lat'] as double?;
                          final deliveryLng = data['receiver_lng'] as double?;
                          final senderId = data['sender_id'] as String?;

                          if (deliveryLat == null ||
                              deliveryLng == null ||
                              senderId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่พบพิกัดผู้ส่งหรือผู้รับ'),
                              ),
                            );
                            return;
                          }

                          final senderDoc = await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(senderId)
                              .get();

                          if (!senderDoc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่พบข้อมูลร้านค้า'),
                              ),
                            );
                            return;
                          }

                          final senderData = senderDoc.data()!;
                          final loc = senderData['location'];
                          final senderLat = loc?['lat'] as double?;
                          final senderLng = loc?['lng'] as double?;

                          if (senderLat == null || senderLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ร้านค้ายังไม่มีพิกัด'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiderDeliveryMapPage(
                                deliveryLocation: LatLng(
                                  deliveryLat,
                                  deliveryLng,
                                ),
                                senderLocation: LatLng(senderLat, senderLng),
                                receiverName: data['receiver_name'] ?? '',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.map),
                  label: Text(canViewMap ? 'ดูแผนที่' : 'ไรเดอร์ยังไม่รับงาน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canViewMap
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Map<String, dynamic> info) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            if (info['name'] != null)
              _buildDetailRow(Icons.person, 'ชื่อ', info['name']),
            if (info['phone'] != null)
              _buildDetailRow(Icons.phone, 'เบอร์โทร', info['phone']),
            if (info['address'] != null)
              _buildDetailRow(Icons.home, 'ที่อยู่', info['address']),
          ],
        ),
      ),
    );
  }
}
