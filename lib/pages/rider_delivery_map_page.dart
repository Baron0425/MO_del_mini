import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RiderDeliveryMapPage extends StatefulWidget {
  final LatLng deliveryLocation;
  final LatLng senderLocation;
  final String receiverName;

  const RiderDeliveryMapPage({
    super.key,
    required this.deliveryLocation,
    required this.senderLocation,
    required this.receiverName,
  });

  @override
  State<RiderDeliveryMapPage> createState() => _RiderDeliveryMapPageState();
}

class _RiderDeliveryMapPageState extends State<RiderDeliveryMapPage> {
  final mapController = MapController();
  LatLng? riderPosition;

  @override
  void initState() {
    super.initState();
    _startRiderTracking();
  }

  void _startRiderTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // ดึงตำแหน่งปัจจุบันทันที
    try {
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        riderPosition = LatLng(currentPos.latitude, currentPos.longitude);
      });
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }

    // Listen stream ตำแหน่งต่อเนื่อง
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        riderPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: widget.senderLocation,
        width: 60,
        height: 60,
        child: const Icon(Icons.store, color: Colors.orange, size: 40),
      ),
      Marker(
        point: widget.deliveryLocation,
        width: 60,
        height: 60,
        child: const Icon(Icons.home, color: Colors.red, size: 40),
      ),
    ];

    if (riderPosition != null) {
      markers.add(
        Marker(
          point: riderPosition!,
          width: 60,
          height: 60,
          child: const Icon(Icons.local_shipping, color: Colors.blue, size: 40),
        ),
      );
    }

    final centerLat =
        (widget.senderLocation.latitude + widget.deliveryLocation.latitude) / 2;
    final centerLng =
        (widget.senderLocation.longitude + widget.deliveryLocation.longitude) /
        2;
    final mapCenter = riderPosition ?? LatLng(centerLat, centerLng);

    return Scaffold(
      appBar: AppBar(
        title: Text('แผนที่: ${widget.receiverName}'),
        backgroundColor: Colors.green,
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: mapCenter,
          initialZoom: 13.0,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=79ac29ccd24941cd84fa305b8da14ae1',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
