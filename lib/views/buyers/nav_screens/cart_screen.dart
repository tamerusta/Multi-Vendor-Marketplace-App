import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:maclay_multi_store/provider/cart_provider.dart';
import 'package:maclay_multi_store/views/buyers/inner_screens/checkout_screen.dart';
import 'package:provider/provider.dart';

import '../main_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartProvider _cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        title: Text(
          'Cart Screen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _cartProvider.removeAllItem();
            },
            icon: Icon(
              CupertinoIcons.delete,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _cartProvider.getCartItem.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 60,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cartProvider.getCartItem.length,
                itemBuilder: (context, index) {
                  final cartData =
                      _cartProvider.getCartItem.values.toList()[index];
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: Image.network(cartData.imageUrl[0]),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width - 180,
                                  child: Text(
                                    cartData.productName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '\$' +
                                      " " +
                                      cartData.price.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: null,
                                  child: Text(
                                    cartData.productSize,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 115,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade900,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: cartData.quantity == 1
                                                ? null
                                                : () {
                                                    _cartProvider
                                                        .decreaMent(cartData);
                                                  },
                                            icon: Icon(
                                              CupertinoIcons.minus,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            cartData.quantity.toString(),
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          IconButton(
                                            onPressed: cartData
                                                        .productQuantity ==
                                                    cartData.quantity
                                                ? null
                                                : () {
                                                    _cartProvider
                                                        .increament(cartData);
                                                  },
                                            icon: Icon(
                                              CupertinoIcons.plus,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _cartProvider.removeItem(
                                          cartData.productId,
                                        );
                                      },
                                      icon: Icon(
                                        CupertinoIcons.cart_badge_minus,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Shopping Cart is Empty',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) {
                        return MainScreen();
                      }));
                    },
                    child: Container(
                      height: 40,
                      width: MediaQuery.of(context).size.width - 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          'CONTINUE SHOPPING',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: _cartProvider.totalPrice == 0.00
              ? null
              : () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CheckoutScreen();
                  }));
                },
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _cartProvider.totalPrice == 0.00
                  ? Colors.grey.shade400
                  : Colors.blue.shade900,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                "\$" +
                    _cartProvider.totalPrice.toStringAsFixed(2) +
                    " " +
                    'CHECKOUT',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 8,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
