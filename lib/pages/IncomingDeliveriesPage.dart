import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/UserDeliveryDetailPage.dart';

class IncomingDeliveriesPage extends StatefulWidget {
  final String uid;

  const IncomingDeliveriesPage({super.key, required this.uid});

  @override
  State<IncomingDeliveriesPage> createState() => _IncomingDeliveriesPageState();
}

class _IncomingDeliveriesPageState extends State<IncomingDeliveriesPage> {
  @override
  Widget build(BuildContext context) {
    final String uid = widget.uid.toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้าที่จะได้รับ'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .where('receiver_uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีสินค้าที่ส่งมาหาคุณ'));
          }

          final deliveries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index].data() as Map<String, dynamic>;
              final deliveryId =
                  deliveries[index].id; // ✅ เอา id เอกสารไว้ส่งต่อ

              // ✅ แปลงสถานะเป็นข้อความและสี
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: data['product_image'] != null
                            ? Image.network(
                                data['product_image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.inventory, size: 50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['product_name'] ?? 'ไม่มีชื่อสินค้า',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text('ผู้ส่ง: ${data['sender_name'] ?? 'ไม่ทราบ'}'),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ✅ ปุ่มดูรายละเอียด
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDeliveryDetailPage(
                                deliveryId: deliveryId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ดูรายละเอียด',
                          style: TextStyle(fontSize: 14, color: Colors.white),
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
