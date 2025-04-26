import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:maclay_multi_store/chat_screen.dart';
import 'package:maclay_multi_store/provider/cart_provider.dart';
import 'package:maclay_multi_store/provider/product_provider.dart';
import 'package:maclay_multi_store/vendor/views/screens/landing_screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:maclay_multi_store/views/buyers/auth/login_screen.dart';
import 'package:maclay_multi_store/views/buyers/auth/register_screen.dart';
import 'package:maclay_multi_store/views/buyers/main_screen.dart';
import 'package:maclay_multi_store/vendor/views/auth/vendor_auth_screen.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    Platform.isAndroid
        ? await Firebase.initializeApp(
            name: 'multivendor-store',
            options: const FirebaseOptions(
                apiKey: "AIzaSyBYqGpq6DldGc_OqW_nQnLMTeONsiEVgww",
                appId: '1:1009070463313:android:efa2a61d85245ec9bf9b70',
                messagingSenderId: '1009070463313',
                projectId: 'multi-vendor-store-df606',
                storageBucket:
                    'gs://multi-vendor-store-df606.firebasestorage.app'),
          )
        : await Firebase.initializeApp();
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) {
      return ProductProvider();
    }),
    ChangeNotifierProvider(create: (_) {
      return CartProvider();
    })
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Brand-Bold',
      ),
      home: VendorAuthScreen(),
      builder: EasyLoading.init(),
      routes: {
        '/chat': (context) => ChatScreen(), // Chatbot rotası
      },
    );
  }
}
