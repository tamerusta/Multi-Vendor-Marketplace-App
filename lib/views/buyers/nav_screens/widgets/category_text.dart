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
    final Stream<QuerySnapshot> _catgoryStream =
        FirebaseFirestore.instance.collection('categories').snapshots();
    return Padding(
      padding: const EdgeInsets.all(9.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 19,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _catgoryStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Loading categories"),
                );
              }

              return Container(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final categoryData = snapshot.data!.docs[index];
                          final isSelected =
                              _selectedCategory == categoryData['categoryName'];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ActionChip(
                              backgroundColor: Colors.yellow.shade900,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors
                                          .transparent, // Seçiliyse mavi şerit
                                  width: 2.0,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_selectedCategory ==
                                      categoryData['categoryName']) {
                                    _selectedCategory =
                                        null; // Aynı kategoriye tıklanırsa seçim kaldırılır
                                  } else {
                                    _selectedCategory =
                                        categoryData['categoryName'];
                                  }
                                });

                                print(_selectedCategory);
                              },
                              label: Center(
                                child: Transform.translate(
                                  offset: Offset(0,
                                      -20), // Yazıyı yukarı kaydırmak için offset
                                  child: Text(
                                    categoryData['categoryName'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14, // Yazı boyutunu büyüttüm
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    20.0, // Turuncu alanın boyunu biraz daha büyüttüm
                                horizontal: 16.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CategoryScreen();
                        }));
                      },
                      icon: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_selectedCategory == null) MainProductsWidget(),
          if (_selectedCategory != null)
            HomeproductWidget(categoryName: _selectedCategory!),
        ],
      ),
    );
  }
}
