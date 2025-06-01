import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:maclay_multi_store/views/buyers/auth/login_screen.dart';
import 'package:maclay_multi_store/views/buyers/inner_screens/order_screen.dart';
import 'package:maclay_multi_store/views/welcome_screen.dart';

import '../inner_screens/edit_profile.dart';

class AccountScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('buyers');
    return _auth.currentUser == null
        ? Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.blue.shade900,
              title: Text(
                'Profile',
                style: TextStyle(
                  letterSpacing: 4,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Icon(Icons.star, color: Colors.white),
                ),
              ],
            ),
            body: Column(
              children: [
                SizedBox(height: 25),
                Center(
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.blue.shade900,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Login Account To Access Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 25),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) {
                      return LoginScreen();
                    }));
                  },
                  child: Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width - 200,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'LOGIN ACCOUNT',
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : FutureBuilder<DocumentSnapshot>(
            future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text("Something went wrong");
              }

              if (snapshot.hasData && !snapshot.data!.exists) {
                return Text("Document does not exist");
              }

              if (snapshot.connectionState == ConnectionState.done) {
                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.blue.shade900,
                    title: Text(
                      'Profile',
                      style: TextStyle(
                        letterSpacing: 4,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Icon(Icons.star, color: Colors.white),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 64,
                                backgroundColor: Colors.blue.shade900,
                                backgroundImage:
                                    NetworkImage(data['profileImage']),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              data['fullName'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              data['email'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 15),
                            InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return EditPRofileScreen(
                                    userData: data,
                                  );
                                }));
                              },
                              child: Container(
                                height: 45,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade900,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.all(15),
                          children: [
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              tileColor: Colors.grey.shade100,
                              leading: Icon(Icons.settings,
                                  color: Colors.blue.shade900),
                              title: Text('Settings'),
                            ),
                            SizedBox(height: 10),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              tileColor: Colors.grey.shade100,
                              leading: Icon(Icons.phone,
                                  color: Colors.blue.shade900),
                              title: Text('Phone'),
                            ),
                            SizedBox(height: 10),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              tileColor: Colors.grey.shade100,
                              leading:
                                  Icon(Icons.shop, color: Colors.blue.shade900),
                              title: Text('Cart'),
                            ),
                            SizedBox(height: 10),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              tileColor: Colors.grey.shade100,
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return CustomerOrderScreen();
                                }));
                              },
                              leading: Icon(CupertinoIcons.shopping_cart,
                                  color: Colors.blue.shade900),
                              title: Text('Order'),
                            ),
                            SizedBox(height: 10),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              tileColor: Colors.grey.shade100,
                              onTap: () async {
                                await _auth.signOut().whenComplete(() {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WelcomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                });
                              },
                              leading: Icon(Icons.logout,
                                  color: Colors.blue.shade900),
                              title: Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Center(child: CircularProgressIndicator());
            },
          );
  }
}
