import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/rider_delivery_map_page.dart';
import 'package:latlong2/latlong.dart';

class UserDeliveryDetailPage extends StatelessWidget {
  final String deliveryId;

  const UserDeliveryDetailPage({super.key, required this.deliveryId});

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

        // แปลงสถานะให้อ่านง่าย
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

        // เลือกรูปที่จะโชว์
        String? displayImage =
            data['delivered_image'] ??
            data['pickup_image'] ??
            data['product_image'];

        // ปุ่มดูแผนที่ (กดได้เฉพาะ status ≥ 2)
        final canViewMap = (data['status'] ?? 1) >= 2;

        return Scaffold(
          appBar: AppBar(title: const Text('รายละเอียดงานจัดส่ง')),
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
                Text(
                  data['product_name'] ?? 'ไม่ระบุชื่อสินค้า',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),

                // ข้อมูลผู้รับ
                Text('ชื่อผู้รับ: ${data['receiver_name']}'),
                Text('เบอร์โทร: ${data['receiver_phone']}'),
                Text('ที่อยู่: ${data['receiver_address']}'),
                const SizedBox(height: 20),

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
                          if (loc == null ||
                              loc['lat'] == null ||
                              loc['lng'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ร้านค้ายังไม่มีพิกัด'),
                              ),
                            );
                            return;
                          }

                          final senderLat = loc['lat'] as double;
                          final senderLng = loc['lng'] as double;

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
                      : null, // ปุ่ม Disabled ถ้ายังไม่ถึง status ≥ 2
                  icon: const Icon(Icons.map),
                  label: Text(canViewMap ? 'ดูแผนที่' : 'ไรเดอร์ยังไม่รับงาน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canViewMap ? Colors.blue : Colors.grey,
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
}
