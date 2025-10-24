import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RiderPage extends StatelessWidget {
  final String uid;
  final String name;
  final String phone;

  const RiderPage({
    super.key,
    required this.uid,
    required this.name,
    required this.phone,
  });

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานจัดส่ง'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .where('status', whereIn: [1, 2]) // ดึงงานว่างและงานที่รับแล้ว
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีงานว่าง'));
          }

          final tasks = snapshot.data!.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isTaskTakenByMe = task['rider_uid'] == uid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(task['product_name'] ?? 'ไม่มีชื่อสินค้า'),
                  subtitle: Text(
                    'ผู้รับ: ${task['receiver_name'] ?? '-'}\nสถานะ: ${task['status'] ?? '-'}',
                  ),
                  trailing: task['status'] == 1
                      ? ElevatedButton(
                          onPressed: () async {
                            Position? pos = await _getCurrentLocation();
                            if (pos == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ไม่สามารถดึงตำแหน่งได้'),
                                ),
                              );
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('deliveries')
                                .doc(task['id'])
                                .update({
                                  'status': 2,
                                  'rider_uid': uid,
                                  'rider_name': name,
                                  'rider_phone': phone,
                                  'rider_lat': pos.latitude,
                                  'rider_lng': pos.longitude,
                                });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('รับงานเรียบร้อยแล้ว'),
                              ),
                            );
                          },
                          child: const Text('รับงาน'),
                        )
                      : isTaskTakenByMe
                      ? ElevatedButton(
                          onPressed: () {
                            // กดดูรายละเอียดงาน
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ยังไม่มีหน้ารายละเอียด'),
                              ),
                            );
                          },
                          child: const Text('ดูรายละเอียดงาน'),
                        )
                      : const Text(
                          'งานถูกรับแล้ว',
                          style: TextStyle(
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
