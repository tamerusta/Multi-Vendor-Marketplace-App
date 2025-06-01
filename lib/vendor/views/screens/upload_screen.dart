import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:maclay_multi_store/provider/product_provider.dart';
import 'package:maclay_multi_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/upload_tap_screens/attributes_tab_screens.dart';
import 'package:maclay_multi_store/vendor/views/screens/upload_tap_screens/general_screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/upload_tap_screens/images_tab_screen.dart';
import 'package:maclay_multi_store/vendor/views/screens/upload_tap_screens/shipping_screen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class UploadScreen extends StatefulWidget {
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    final ProductProvider _productProvider =
        Provider.of<ProductProvider>(context);
    return DefaultTabController(
      length: 4,
      child: Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.blue.shade900,
            elevation: 0,
            title: const Text(
              'Add Product',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  child: Text('General'),
                ),
                Tab(
                  child: Text('Shipping'),
                ),
                Tab(
                  child: Text('Attributes'),
                ),
                Tab(
                  child: Text('Images'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              GeneralScreen(),
              ShippingScreeen(),
              AttributesTabScreen(),
              ImagesTabScreen(),
            ],
          ),
          bottomSheet: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    EasyLoading.show(status: 'Saving Product...');
                    if (_formKey.currentState!.validate()) {
                      try {
                        final productId = Uuid().v4();
                        await _firestore
                            .collection('products')
                            .doc(productId)
                            .set({
                          'productId': productId,
                          'productName':
                              _productProvider.productData['productName'],
                          'productPrice':
                              _productProvider.productData['productPrice'],
                          'quantity': _productProvider.productData['quantity'],
                          'category': _productProvider.productData['category'],
                          'description':
                              _productProvider.productData['description'],
                          'imageUrl':
                              _productProvider.productData['imageUrlList'],
                          'scheduleDate':
                              _productProvider.productData['scheduleDate'],
                          'chargeShipping':
                              _productProvider.productData['chargeShipping'],
                          'shippingCharge':
                              _productProvider.productData['shippingCharge'],
                          'brandName':
                              _productProvider.productData['brandName'],
                          'sizeList': _productProvider.productData['sizeList'],
                          'vendorId': FirebaseAuth.instance.currentUser!.uid,
                          'approved': false,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        _productProvider.clearData();
                        _formKey.currentState!.reset();
                        EasyLoading.dismiss();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainVendorScreen()),
                        );
                      } catch (e) {
                        EasyLoading.dismiss();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
