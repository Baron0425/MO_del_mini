import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SenderShipmentsPage extends StatefulWidget {
  final String uid;
  final String name;
  final String profilePicture;

  const SenderShipmentsPage({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
  });

  @override
  State<SenderShipmentsPage> createState() => _SenderShipmentsPageState();
}

class _SenderShipmentsPageState extends State<SenderShipmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานจัดส่ง'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _showAllShipmentsMap,
            tooltip: 'แสดงแผนที่ทั้งหมด',
          ),
        ],
      ),
      body: _buildListView(),
    );
  }

  // แสดงรายการทั้งหมด
  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .where('sender_id', isEqualTo: widget.uid)
          .snapshots(),
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

            return _buildDeliveryCard(d, status, i, doc.id);
          },
        );
      },
    );
  }

  // Card แสดงรายละเอียด Shipment
  Widget _buildDeliveryCard(
    Map<String, dynamic> d,
    int status,
    int index,
    String docId,
  ) {
    final receiverLat = d['receiver_lat']?.toString() ?? '-';
    final receiverLng = d['receiver_lng']?.toString() ?? '-';
    final productImage = d['product_image'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: รูปสินค้า + ชื่องาน + สถานะ
            Row(
              children: [
                // รูปสินค้า
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: productImage != null && productImage.isNotEmpty
                      ? Image.network(
                          productImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 12),
                // ชื่องาน
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

            // สถานะ
            _buildStatusIndicator(status),
            const Divider(height: 24),

            // รายละเอียดผู้รับ
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
            _buildDetailRow(
              Icons.location_on,
              "พิกัด",
              "$receiverLat, $receiverLng",
            ),

            // รายละเอียดไรเดอร์ (ถ้ามี)
            if (d['rider_name'] != null) ...[
              const Divider(height: 24),
              const Text(
                "🚴 ข้อมูลไรเดอร์",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.motorcycle, "ชื่อไรเดอร์", d['rider_name']),
              _buildDetailRow(
                Icons.location_searching,
                "พิกัดไรเดอร์",
                "${d['rider_lat']?.toString() ?? '-'}, ${d['rider_lng']?.toString() ?? '-'}",
              ),
            ],

            const SizedBox(height: 12),

            // ปุ่มดูแผนที่
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openSingleShipmentMap(d),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('ดูแผนที่งานนี้'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openNavigationToReceiver(d),
                  icon: const Icon(Icons.navigation, color: Colors.blue),
                  tooltip: 'นำทางไปผู้รับ',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder สำหรับรูปที่โหลดไม่ได้
  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag, size: 30, color: Colors.grey),
    );
  }

  // แถวรายละเอียด
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
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
  }

  // แสดงสถานะพร้อมไอคอน (2.2.3)
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

  // ข้อมูลสถานะ
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
          'icon': Icons.check_circle,
        };
      default:
        return {
          'text': 'ไรเดอร์ส่งสำเร็จ ',
          'color': Colors.grey,
          'icon': Icons.help,
        };
    }
  }

  // เปิดแผนที่แบบแยก Shipment (2.2.4 ทางเลือก 2)
  Future<void> _openSingleShipmentMap(Map<String, dynamic> d) async {
    final receiverLat = d['receiver_lat'] as num?;
    final receiverLng = d['receiver_lng'] as num?;
    final riderLat = d['rider_lat'] as num?;
    final riderLng = d['rider_lng'] as num?;

    if (receiverLat == null || receiverLng == null) {
      _showSnackBar('ไม่พบพิกัดผู้รับ');
      return;
    }

    // สร้าง URL สำหรับแสดงแผนที่
    String url;
    if (riderLat != null && riderLng != null) {
      // แสดงทั้งผู้รับและไรเดอร์
      url =
          'https://www.google.com/maps/dir/?api=1&origin=$riderLat,$riderLng&destination=$receiverLat,$receiverLng';
    } else {
      // แสดงเฉพาะผู้รับ
      url =
          'https://www.google.com/maps/search/?api=1&query=$receiverLat,$receiverLng';
    }

    await _launchURL(url);
  }

  // นำทางไปยังผู้รับ
  Future<void> _openNavigationToReceiver(Map<String, dynamic> d) async {
    final receiverLat = d['receiver_lat'] as num?;
    final receiverLng = d['receiver_lng'] as num?;

    if (receiverLat == null || receiverLng == null) {
      _showSnackBar('ไม่พบพิกัดผู้รับ');
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$receiverLat,$receiverLng&travelmode=driving';
    await _launchURL(url);
  }

  // แสดงแผนที่ทั้งหมด (2.2.4 ทางเลือก 1)
  Future<void> _showAllShipmentsMap() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('deliveries')
        .where('sender_id', isEqualTo: widget.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      _showSnackBar('ยังไม่มีงานจัดส่ง');
      return;
    }

    final deliveries = snapshot.docs;
    final List<String> markers = [];

    for (var doc in deliveries) {
      final d = doc.data();
      final receiverLat = d['receiver_lat'] as num?;
      final receiverLng = d['receiver_lng'] as num?;

      if (receiverLat != null && receiverLng != null) {
        markers.add('$receiverLat,$receiverLng');
      }
    }

    if (markers.isEmpty) {
      _showSnackBar('ไม่พบพิกัดในงานจัดส่ง');
      return;
    }

    // เปิด Google Maps แสดงหลายจุด
    final firstMarker = markers.first;
    final url = 'https://www.google.com/maps/search/?api=1&query=$firstMarker';
    await _launchURL(url);
  }

  // เปิด URL
  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('ไม่สามารถเปิดแผนที่ได้');
    }
  }

  // แสดง SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
