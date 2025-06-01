import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:maclay_multi_store/vendor/views/screens/edit_product_screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/vendor_logout_Screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/vendor_order_screen.dart';

import 'earnings_screen.dart';
import 'upload_screen.dart';

class MainVendorScreen extends StatefulWidget {
  const MainVendorScreen({super.key});

  @override
  State<MainVendorScreen> createState() => _MainVendorScreenState();
}

class _MainVendorScreenState extends State<MainVendorScreen> {
  int _pageIndex = 0;
  List<Widget> _pages = [
    EarningsScreen(),
    UploadScreen(),
    EditProductScreen(),
    VendorOrderScreen(),
    VendorLogoutScreen()
  ];

  Color _getIconColor(int index) {
    return _pageIndex == index ? Colors.blue.shade900 : Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: _pageIndex,
          onTap: (value) {
            setState(() {
              _pageIndex = value;
            });
          },
          selectedFontSize: 13,
          unselectedFontSize: 13,
          selectedItemColor: Colors.blue.shade900,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.money_dollar,
                size: 22,
                color: _getIconColor(0),
              ),
              label: 'EARNINGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.upload,
                size: 22,
                color: _getIconColor(1),
              ),
              label: 'UPLOAD',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.edit,
                size: 22,
                color: _getIconColor(2),
              ),
              label: 'EDIT',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.shopping_bag_outlined,
                size: 22,
                color: _getIconColor(3),
              ),
              label: 'ORDERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.logout,
                size: 22,
                color: _getIconColor(4),
              ),
              label: 'LOGOUT',
            ),
          ],
        ),
      ),
      body: _pages[_pageIndex],
    );
  }
}
