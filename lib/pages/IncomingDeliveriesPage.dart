import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingDeliveriesPage extends StatefulWidget {
  final String uid;

  const IncomingDeliveriesPage({super.key, required this.uid});

  @override
  State<IncomingDeliveriesPage> createState() => _IncomingDeliveriesPageState();
}

class _IncomingDeliveriesPageState extends State<IncomingDeliveriesPage> {
  @override
  Widget build(BuildContext context) {
    // แปลง uid ให้ชัวร์เป็น string และ trim
    final String uid = widget.uid.toString().trim();
    print('Querying deliveries for UID: $uid');

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
          // กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ถ้าเกิด error
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          // ถ้าไม่มีข้อมูล
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('จำนวนเอกสารที่ได้: ${snapshot.data?.docs.length ?? 0}');
            return const Center(child: Text('ยังไม่มีสินค้าที่ส่งมาหาคุณ'));
          }

          final deliveries = snapshot.data!.docs;
          print('จำนวนเอกสารที่ได้: ${deliveries.length}');

          return ListView.builder(
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: data['product_image'] != null
                      ? Image.network(
                          data['product_image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.inventory),
                  title: Text(data['product_name'] ?? 'ไม่มีชื่อสินค้า'),
                  subtitle: Text('ผู้ส่ง: ${data['sender_name'] ?? 'ไม่ทราบ'}'),
                  trailing: Text(
                    data['status'] == 1
                        ? 'รอไรเดอร์รับสินค้า'
                        : 'ไรเดอร์รับแล้ว',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
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
