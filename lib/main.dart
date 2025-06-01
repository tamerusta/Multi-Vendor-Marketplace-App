import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:maclay_multi_store/chat_screen.dart';
import 'package:maclay_multi_store/provider/cart_provider.dart';
import 'package:maclay_multi_store/provider/product_provider.dart';
import 'package:maclay_multi_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:maclay_multi_store/views/buyers/main_screen.dart';
import 'package:maclay_multi_store/views/welcome_screen.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Multi Vendor Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Brand-Bold',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, vendorSnapshot) {
                if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
                  return MainVendorScreen();
                } else {
                  return MainScreen();
                }
              },
            );
          }
          return const WelcomeScreen();
        },
      ),
      builder: EasyLoading.init(),
      routes: {
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}
