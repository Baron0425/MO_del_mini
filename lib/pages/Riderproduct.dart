import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/rider_delivery_map_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class RiderOrderDetailPage extends StatefulWidget {
  final String deliveryId;

  const RiderOrderDetailPage({super.key, required this.deliveryId});

  @override
  State<RiderOrderDetailPage> createState() => _RiderOrderDetailPageState();
}

class _RiderOrderDetailPageState extends State<RiderOrderDetailPage> {
  bool isUploading = false;
  File? _image;

  Future<void> _pickAndUploadImage(Map<String, dynamic> data) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      isUploading = true;
    });

    try {
      final cloudinary = CloudinaryPublic(
        'dmaxl7c40',
        'picture_mobile_02',
        cache: false,
      );

      final upload = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _image!.path,
          folder: 'deliveries',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final currentStatus = data['status'] ?? 1;
      final updates = <String, dynamic>{};

      if (currentStatus == 2) {
        // ถ่ายตอนรับสินค้า → ไปสถานะ 3
        updates['status'] = 3;
        updates['pickup_image'] = upload.secureUrl;
        updates['pickup_at'] = Timestamp.now();
      } else if (currentStatus == 3) {
        // ถ่ายตอนส่งสินค้า → ไปสถานะ 4
        updates['status'] = 4;
        updates['delivered_image'] = upload.secureUrl;
        updates['delivered_at'] = Timestamp.now();
      }

      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .update(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus == 2
                ? 'รับสินค้าเรียบร้อย! สถานะเปลี่ยนเป็น กำลังจัดส่ง'
                : 'จัดส่งสำเร็จแล้ว ✅',
          ),
        ),
      );

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // แสดงสถานะ
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
        }

        return Scaffold(
          appBar: AppBar(title: const Text('รายละเอียดงานจัดส่ง')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 10),

                // รูปสินค้า
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['product_image'] ?? '',
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
                Text(
                  data['product_name'] ?? 'ไม่ระบุชื่อสินค้า',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                Text('ชื่อผู้รับ: ${data['receiver_name']}'),
                Text('เบอร์โทร: ${data['receiver_phone']}'),
                Text('ที่อยู่: ${data['receiver_address']}'),
                const SizedBox(height: 20),

                // ปุ่มดูแผนที่
                ElevatedButton.icon(
                  onPressed: () async {
                    final deliveryLat = data['receiver_lat'] as double?;
                    final deliveryLng = data['receiver_lng'] as double?;
                    final senderId = data['sender_id'] as String?;
                    final receiverName =
                        data['receiver_name'] ?? 'ผู้รับไม่ระบุ';

                    if (deliveryLat == null ||
                        deliveryLng == null ||
                        senderId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่พบพิกัดสินค้า หรือร้านค้า'),
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
                        const SnackBar(content: Text('ไม่พบข้อมูลร้านค้า')),
                      );
                      return;
                    }

                    final senderData = senderDoc.data()!;
                    final loc = senderData['location'];
                    if (loc == null ||
                        loc['lat'] == null ||
                        loc['lng'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ร้านค้ายังไม่มีพิกัด')),
                      );
                      return;
                    }

                    final senderLat = loc['lat'] as double;
                    final senderLng = loc['lng'] as double;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderDeliveryMapPage(
                          deliveryLocation: LatLng(deliveryLat, deliveryLng),
                          senderLocation: LatLng(senderLat, senderLng),
                          receiverName: receiverName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('ดูแผนที่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 20),

                // ถ่ายรูปตอนรับ / ส่งสินค้า
                if (isUploading)
                  const Center(child: CircularProgressIndicator())
                else if (data['status'] == 2 || data['status'] == 3)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      data['status'] == 2
                          ? 'ถ่ายรูปตอนรับสินค้า'
                          : 'ถ่ายรูปตอนส่งสินค้า (จบงาน)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data['status'] == 2
                          ? Colors.green
                          : Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () => _pickAndUploadImage(data),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
