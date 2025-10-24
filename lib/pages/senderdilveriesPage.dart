import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
      ),
      body: _buildListView(),
    );
  }

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
            return _buildDeliveryCard(d, status, i);
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> d, int status, int index) {
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
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (productImage != null && productImage.isNotEmpty) {
                      _showFullImage(context, productImage);
                    }
                  },
                  child: ClipRRect(
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
            _buildDetailRow(
              Icons.location_on,
              "พิกัด",
              "$receiverLat, $receiverLng",
            ),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (receiverLat != '-' && receiverLng != '-') {
                  final lat = double.tryParse(receiverLat);
                  final lng = double.tryParse(receiverLng);
                  if (lat != null && lng != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryMapPage(
                          deliveryLocation: LatLng(lat, lng),
                          riderLocation:
                              d['rider_lat'] != null && d['rider_lng'] != null
                              ? LatLng(
                                  double.parse(d['rider_lat'].toString()),
                                  double.parse(d['rider_lng'].toString()),
                                )
                              : null,
                          receiverName: d['receiver_name'] ?? 'ผู้รับ',
                          riderName: d['rider_name'],
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.map),
              label: const Text('ดูแผนที่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

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
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Text('ไม่สามารถโหลดรูปภาพได้'),
                  );
                },
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

// ---------- หน้าแผนที่ (แก้ไขแล้ว) ----------
class DeliveryMapPage extends StatefulWidget {
  final LatLng deliveryLocation;
  final LatLng? riderLocation;
  final String receiverName;
  final String? riderName;

  const DeliveryMapPage({
    super.key,
    required this.deliveryLocation,
    this.riderLocation,
    required this.receiverName,
    this.riderName,
  });

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  List<LatLng> polylinePoints = [];
  List<Marker> markers = [];
  bool isLoading = true;
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    _setupMarkers();
    if (widget.riderLocation != null) {
      await _getRoute();
    }
    setState(() {
      isLoading = false;
    });
  }

  void _setupMarkers() {
    print('🎯 Delivery Location: ${widget.deliveryLocation}');
    print('🏍️ Rider Location: ${widget.riderLocation}');

    // Marker จุดส่ง (สีเขียว)
    markers.add(
      Marker(
        point: widget.deliveryLocation,
        width: 100,
        height: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.location_on, color: Colors.green, size: 50),
          ],
        ),
      ),
    );

    // Marker ไรเดอร์ (สีน้ำเงิน)
    if (widget.riderLocation != null) {
      markers.add(
        Marker(
          point: widget.riderLocation!,
          width: 100,
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.riderName ?? 'ไรเดอร์',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(Icons.motorcycle, color: Colors.blue, size: 50),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _getRoute() async {
    if (widget.riderLocation == null) return;
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${widget.riderLocation!.longitude},${widget.riderLocation!.latitude};${widget.deliveryLocation.longitude},${widget.deliveryLocation.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          polylinePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
        });
      }
    } catch (e) {
      print('❌ Error getting route: $e');
    }
  }

  // คำนวณระยะทางและ zoom level ที่เหมาะสม
  double _calculateZoom() {
    if (widget.riderLocation == null) return 15.0;

    final distance = const Distance().as(
      LengthUnit.Kilometer,
      widget.riderLocation!,
      widget.deliveryLocation,
    );

    if (distance > 50) return 10.0;
    if (distance > 20) return 11.0;
    if (distance > 10) return 12.0;
    if (distance > 5) return 13.0;
    if (distance > 2) return 14.0;
    return 15.0;
  }

  LatLng _calculateCenter() {
    if (widget.riderLocation == null) {
      return widget.deliveryLocation;
    }

    return LatLng(
      (widget.riderLocation!.latitude + widget.deliveryLocation.latitude) / 2,
      (widget.riderLocation!.longitude + widget.deliveryLocation.longitude) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final center = _calculateCenter();
    final zoom = _calculateZoom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('พิกัดสินค้า'),
        backgroundColor: Colors.green,
        actions: [
          // ปุ่มแสดงข้อมูล
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ข้อมูลพิกัด'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 จุดส่ง: ${widget.receiverName}'),
                      Text(
                        '   ${widget.deliveryLocation.latitude.toStringAsFixed(6)}, ${widget.deliveryLocation.longitude.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 8),
                      if (widget.riderLocation != null) ...[
                        Text('🏍️ ไรเดอร์: ${widget.riderName ?? "ไรเดอร์"}'),
                        Text(
                          '   ${widget.riderLocation!.latitude.toStringAsFixed(6)}, ${widget.riderLocation!.longitude.toStringAsFixed(6)}',
                        ),
                      ] else
                        const Text('🏍️ ยังไม่มีไรเดอร์รับงาน'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=79ac29ccd24941cd84fa305b8da14ae1',
                userAgentPackageName: 'com.example.app',
              ),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // ปุ่มควบคุมแผนที่
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // ปุ่มโฟกัสจุดส่ง
                FloatingActionButton(
                  heroTag: 'delivery',
                  mini: true,
                  backgroundColor: Colors.green,
                  onPressed: () {
                    mapController.move(widget.deliveryLocation, 16);
                  },
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(height: 8),
                // ปุ่มโฟกัสไรเดอร์
                if (widget.riderLocation != null)
                  FloatingActionButton(
                    heroTag: 'rider',
                    mini: true,
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      mapController.move(widget.riderLocation!, 16);
                    },
                    child: const Icon(Icons.motorcycle, color: Colors.white),
                  ),
                const SizedBox(height: 8),
                // ปุ่มดูภาพรวม
                FloatingActionButton(
                  heroTag: 'overview',
                  mini: true,
                  backgroundColor: Colors.grey.shade700,
                  onPressed: () {
                    mapController.move(center, zoom);
                  },
                  child: const Icon(Icons.zoom_out_map, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
