import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/senderdilveriesPage.dart';

class SenderCreatedItemsPage extends StatelessWidget {
  final String uid;
  final String name;
  final String profilePicture;

  const SenderCreatedItemsPage({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("สินค้าที่จัดส่ง"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi $name",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "What do you want to send?",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "สินค้าที่จัดส่ง",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildItemList(context)),
          ],
        ),
      ),
    );
  }

  // 🎯 นี่คือโค้ดในไฟล์ SenderCreatedItemsPage.dart นะครับ

  Widget _buildItemList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .where('sender_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีสินค้าที่สร้าง',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final deliveries = snapshot.data!.docs;

        return ListView.separated(
          itemCount: deliveries.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final d = deliveries[index].data() as Map<String, dynamic>;

            // ----------------------------------------------------
            // 1. ดึง ID ของเอกสาร (นี่คือ productId ที่เราต้องการ)
            // ----------------------------------------------------
            final String productId =
                deliveries[index].id; // 👈 จุดที่ 1: เพิ่มบรรทัดนี้

            final productName = d['product_name'] ?? '-';
            final status = _getStatusText(d['status']);
            final location = d['receiver_address'] ?? '-';

            return ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.green),
              title: Text(
                productName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location),
                  Text(
                    "สถานะ: $status",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SenderShipmentsPage(
                      uid: uid,
                      name: name,
                      profilePicture: profilePicture,
                      // ----------------------------------------------------
                      // 2. ส่ง productId ที่เราดึงมา ไปยังหน้าถัดไป
                      // ----------------------------------------------------
                      productId: productId, // 👈 จุดที่ 2: เพิ่มบรรทัดนี้
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ฟังก์ชัน _getStatusText ไม่ต้องแก้ไข ใช้ของเดิมได้เลย
  String _getStatusText(dynamic status) {
    switch (status) {
      case 1:
        return 'รอไรเดอร์รับสินค้า';
      case 2:
        return 'ไรเดอร์รับงานแล้ว';
      case 3:
        return 'กำลังจัดส่ง';
      case 4:
        return 'ส่งสำเร็จ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
}
