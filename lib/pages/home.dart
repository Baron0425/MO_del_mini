import 'package:flutter/material.dart';
import 'package:flutter_deliveries_1/pages/createProductPage.dart';

class MainPage extends StatefulWidget {
  final String name;
  final String status; // "user" หรือ "rider"
  final String uid;
  final String profilePicture;

  const MainPage({
    super.key,
    required this.name,
    required this.status,
    required this.uid,
    required this.profilePicture,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.status == 'user';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- Header ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi ${widget.name}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUser
                              ? "What do you want to send?"
                              : "Are you ready to ship your\ncustomer's package?",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(
                        isUser
                            ? 'assets/images/dog.png'
                            : 'assets/image/logo.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ---------------- Logo ----------------
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Slow Delivery',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ---------------- Body (แตกต่างตามสถานะ) ----------------
                isUser ? _buildUserButtons() : _buildRiderButtons(),
              ],
            ),
          ),
        ),
      ),

      // ---------------- Bottom Navigation ----------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: isUser
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'หน้าแรก',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'สินค้าที่จะได้รับ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping),
                  label: 'จัดส่งสินค้า',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'โปรไฟล์',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'หน้าแรก',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping),
                  label: 'งานจัดส่ง',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'โปรไฟล์',
                ),
              ],
      ),
    );
  }

  // ---------- ปุ่มของ USER ----------
  Widget _buildUserButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.directions_car, size: 30),
          label: const Text(
            'สินค้าที่จะได้รับ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: _mainButtonStyle(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallButton(
              icon: Icons.eco,
              text: "พิกัดสินค้า",
              onTap: () {},
            ),
            _buildSmallButton(
              icon: Icons.local_shipping,
              text: "จัดส่งสินค้า",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProductPage(
                      uid: widget.uid,
                      name: widget.name,
                      profilePicture: widget.profilePicture,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ---------- ปุ่มของ RIDER ----------
  Widget _buildRiderButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.local_shipping, size: 30),
          label: const Text(
            'งานจัดส่ง',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: _mainButtonStyle(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallButton(
              icon: Icons.people_alt_rounded,
              text: "พิกัดลูกค้า",
              onTap: () {},
            ),
            _buildSmallButton(
              icon: Icons.location_pin,
              text: "พิกัดสินค้า",
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // ---------- ปุ่มเล็ก ----------
  Widget _buildSmallButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 30),
          label: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- สไตล์ปุ่มหลัก ----------
  ButtonStyle _mainButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    );
  }
}
