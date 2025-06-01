import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:maclay_multi_store/utils/show_snackBar.dart';

class VendorProductDetailScreen extends StatefulWidget {
  final dynamic productData;

  const VendorProductDetailScreen({super.key, required this.productData});

  @override
  State<VendorProductDetailScreen> createState() =>
      _VendorProductDetailScreenState();
}

class _VendorProductDetailScreenState extends State<VendorProductDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _branNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    setState(() {
      _productNameController.text = widget.productData['productName'];
      _branNameController.text = widget.productData['brandName'];
      _quantityController.text = widget.productData['quantity'].toString();
      _productPriceController.text =
          widget.productData['productPrice'].toString();

      _productDescriptionController.text = widget.productData['description'];
      _categoryNameController.text = widget.productData['category'];
    });
    super.initState();
  }

  double? productPrice;

  int? productQuantity;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          widget.productData['productName'],
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _branNameController,
                      decoration: InputDecoration(
                        labelText: 'Brand Name',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      onChanged: (value) {
                        productQuantity = int.parse(value);
                      },
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      onChanged: (value) {
                        productPrice = double.parse(value);
                      },
                      controller: _productPriceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixText: '\$',
                        prefixStyle: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      maxLength: 800,
                      maxLines: 3,
                      controller: _productDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      enabled: false,
                      controller: _categoryNameController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon:
                            Icon(Icons.lock, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            if (productPrice != null && productQuantity != null) {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: Colors.blue.shade700),
                  );
                },
              );

              try {
                await _firestore
                    .collection('products')
                    .doc(widget.productData['productId'])
                    .update({
                  'productName': _productNameController.text,
                  'brandName': _branNameController.text,
                  'quantity': productQuantity,
                  'productPrice': productPrice,
                  'description': _productDescriptionController.text,
                  'category': _categoryNameController.text,
                });

                Navigator.pop(context); // Close loading dialog
                showSnack(context, 'Product updated successfully!');
                Navigator.pop(context); // Return to previous screen
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                showSnack(context, 'Error updating product');
              }
            } else {
              showSnack(context, 'Please update quantity and price');
            }
          },
          child: Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.update,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "UPDATE PRODUCT",
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
