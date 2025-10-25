import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'rider_delivery_map_page.dart'; // หน้าแผนที่

class SenderShipmentsPage extends StatelessWidget {
  final String uid;
  final String name;
  final String profilePicture;
  final String? productId;

  const SenderShipmentsPage({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
    this.productId,
  });

  Stream<QuerySnapshot> getDeliveryStream() {
    final query = FirebaseFirestore.instance
        .collection('deliveries')
        .where('sender_id', isEqualTo: uid);

    if (productId != null) {
      return query
          .where(FieldPath.documentId, isEqualTo: productId)
          .snapshots();
    }
    return query.snapshots();
  }

  Future<LatLng?> _getSenderLocation(String senderId) async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(senderId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['location'] == null) return null;
    final loc = data['location'];
    return LatLng(loc['lat'], loc['lng']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานจัดส่ง'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getDeliveryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีงานจัดส่ง',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final deliveries = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, i) {
              final doc = deliveries[i];
              final d = doc.data() as Map<String, dynamic>;
              final status = d['status'] ?? 1;
              return _buildDeliveryCard(context, d, status, i);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    Map<String, dynamic> d,
    int status,
    int index,
  ) {
    String? displayImage =
        d['delivered_image'] ?? d['pickup_image'] ?? d['product_image'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (displayImage != null && displayImage.isNotEmpty) {
                      _showFullImage(context, displayImage);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: displayImage != null && displayImage.isNotEmpty
                        ? Image.network(
                            displayImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "งานที่ ${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['product_name'] ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusIndicator(status),
            const Divider(height: 24),

            const Text(
              "📍 ข้อมูลผู้รับ",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.person, "ชื่อ", d['receiver_name'] ?? '-'),
            _buildDetailRow(Icons.phone, "เบอร์", d['receiver_phone'] ?? '-'),
            _buildDetailRow(
              Icons.home,
              "ที่อยู่",
              d['receiver_address'] ?? '-',
            ),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: status != 1
                  ? () async {
                      final deliveryLat = d['receiver_lat'];
                      final deliveryLng = d['receiver_lng'];
                      if (deliveryLat == null || deliveryLng == null) return;

                      final senderLocation = await _getSenderLocation(
                        d['sender_id'],
                      );
                      if (senderLocation == null) return;

                      final riderLat = d['rider_lat'];
                      final riderLng = d['rider_lng'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderDeliveryMapPage(
                            deliveryLocation: LatLng(deliveryLat, deliveryLng),
                            senderLocation: senderLocation,
                            receiverName: d['receiver_name'] ?? 'ผู้รับ',
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.map),
              label: const Text('ดูแผนที่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: const Text('ไม่สามารถโหลดรูปภาพได้'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('ปิด'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.shopping_bag, size: 30, color: Colors.grey),
  );

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusIndicator(int status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo['icon'], color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            statusInfo['text'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(int status) {
    switch (status) {
      case 1:
        return {
          'text': 'รอไรเดอร์รับงาน',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
      case 2:
        return {
          'text': 'ไรเดอร์รับงานแล้ว',
          'color': Colors.blue,
          'icon': Icons.motorcycle,
        };
      case 3:
        return {
          'text': 'ไรเดอร์กำลังจัดส่ง',
          'color': Colors.green,
          'icon': Icons.delivery_dining,
        };
      case 4:
        return {
          'text': 'ส่งสำเร็จ',
          'color': Colors.grey,
          'icon': Icons.check_circle,
        };
      default:
        return {
          'text': 'ไม่ทราบสถานะ',
          'color': Colors.black45,
          'icon': Icons.help_outline,
        };
    }
  }
}
