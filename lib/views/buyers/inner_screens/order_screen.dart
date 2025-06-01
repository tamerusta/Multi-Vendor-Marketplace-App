import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class CustomerOrderScreen extends StatelessWidget {
  String formatedDate(date) {
    final outPutDateFormate = DateFormat('dd/MM/yyyy');

    final outPutDate = outPutDateFormate.format(date);

    return outPutDate;
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue.shade900,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            'My Orders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _ordersStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Something went wrong. Please try again later.',
                      style: TextStyle(color: Colors.red.shade700)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blue.shade900),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'You have no orders yet.',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = snapshot.data!.docs[index];
                bool isAccepted = document['accepted'] == true;
                return Card(
                  elevation: 3,
                  color: Colors.grey.shade100,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundColor: isAccepted
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              radius: 20,
                              child: Icon(
                                isAccepted
                                    ? Icons.check_circle_outline
                                    : Icons.hourglass_empty,
                                color: isAccepted
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                size: 24,
                              )),
                          title: Text(
                            isAccepted ? 'Order Accepted' : 'Order Pending',
                            style: TextStyle(
                              color: isAccepted
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Amount: \$${document['productPrice'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formatedDate(document['orderDate'].toDate()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(),
                        ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(horizontal: 8.0),
                          title: Text(
                            'Order Details',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text('View products and delivery info',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700)),
                          childrenPadding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          children: [
                            _buildOrderDetailItem(
                                'Product:', document['productName']),
                            SizedBox(height: 4),
                            _buildOrderDetailItem(
                                'Quantity:', document['quantity'].toString()),
                            SizedBox(height: 8),
                            if (document['productImage'] != null &&
                                document['productImage'].isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    document['productImage'][0],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.image_not_supported,
                                            size: 60,
                                            color: Colors.grey.shade400),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                          child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.blue.shade900)));
                                    },
                                  ),
                                ),
                              ),
                            Divider(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Buyer Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _buildOrderDetailItem(
                                'Name:', document['fullName']),
                            _buildOrderDetailItem('Email:', document['email']),
                            _buildOrderDetailItem(
                                'Address:', document['address']),
                            SizedBox(height: 8),
                            if (isAccepted && document['scheduleDate'] != null)
                              _buildOrderDetailItem(
                                'Scheduled Delivery:',
                                formatedDate(document['scheduleDate'].toDate()),
                                valueColor: Colors.green.shade700,
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ));
  }

  Widget _buildOrderDetailItem(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey.shade700,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
