import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/banner_widget.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/category_text.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/search_input_widget.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/welcome_text_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _setStatusBarStyle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setStatusBarStyle();
  }

  void _setStatusBarStyle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.blue.shade900,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WelcomeText(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchInputWidget(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: BannerWidget(),
              ),
              Flexible(
                child: CategoryText(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }
}
