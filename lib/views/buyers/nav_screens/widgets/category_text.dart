import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/category_screen.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/home_products.dart';
import 'package:maclay_multi_store/views/buyers/nav_screens/widgets/mian_products_widget.dart';

class CategoryText extends StatefulWidget {
  @override
  State<CategoryText> createState() => _CategoryTextState();
}

class _CategoryTextState extends State<CategoryText> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _categoryStream =
        FirebaseFirestore.instance.collection('categories').snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoryScreen()));
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade900,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: StreamBuilder<QuerySnapshot>(
            stream: _categoryStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    "Loading categories...",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final categoryData = snapshot.data!.docs[index];
                  final isSelected =
                      _selectedCategory == categoryData['categoryName'];

                  return Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedCategory ==
                              categoryData['categoryName']) {
                            _selectedCategory = null;
                          } else {
                            _selectedCategory = categoryData['categoryName'];
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.shade900,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            categoryData['categoryName'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: _selectedCategory == null
              ? MainProductsWidget()
              : HomeproductWidget(categoryName: _selectedCategory!),
        ),
      ],
    );
  }
}
