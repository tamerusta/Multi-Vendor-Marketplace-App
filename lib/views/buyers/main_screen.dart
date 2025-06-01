import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/account_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/cart_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/category_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/home_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/search_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/store_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;

  List<Widget> _pages = [
    HomeScreen(),
    CategoryScreen(),
    StoreScreen(),
    CartScreen(),
    SearchScreen(),
    AccountScreen(),
  ];
  Color _getIconColor(int index) {
    return _pageIndex == index ? Colors.blue.shade900 : Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          unselectedItemColor: Colors.grey.shade600,
          selectedItemColor: Colors.blue.shade900,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          items: [
            BottomNavigationBarItem(
              icon:
                  Icon(CupertinoIcons.home, size: 22, color: _getIconColor(0)),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.rectangle_grid_2x2,
                  size: 22, color: _getIconColor(1)),
              label: 'CATEGORY',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/shop.svg',
                width: 22,
                height: 22,
                color: _getIconColor(2),
              ),
              label: 'STORE',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/cart.svg',
                width: 22,
                height: 22,
                color: _getIconColor(3),
              ),
              label: 'CART',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 22,
                height: 22,
                color: _getIconColor(4),
              ),
              label: 'SEARCH',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/account.svg',
                width: 22,
                height: 22,
                color: _getIconColor(5),
              ),
              label: 'ACCOUNT',
            ),
          ],
        ),
      ),
      body: _pages[_pageIndex],
    );
  }
}
