import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditPRofileScreen extends StatefulWidget {
  final dynamic userData;

  EditPRofileScreen({super.key, required this.userData});

  @override
  State<EditPRofileScreen> createState() => _EditPRofileScreenState();
}

class _EditPRofileScreenState extends State<EditPRofileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();
  String? address;
  Uint8List? _image;
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      setState(() {
        _image = imageData;
      });
    }
  }

  Future<String> _uploadImageToStorage(Uint8List image) async {
    Reference ref = _storage
        .ref()
        .child('profilePics')
        .child(FirebaseAuth.instance.currentUser!.uid);
    UploadTask uploadTask = ref.putData(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  void initState() {
    _fullNameController.text = widget.userData['fullName'];
    _emailController.text = widget.userData['email'];
    _phoneController.text = widget.userData['phoneNumber'] ?? '';
    address = widget.userData['address'] ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 4,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Icon(Icons.star, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade900,
                      backgroundImage: _image != null
                          ? MemoryImage(_image!)
                          : (widget.userData['profileImage'] != null &&
                                  widget.userData['profileImage'].isNotEmpty
                              ? NetworkImage(widget.userData['profileImage'])
                              : null) as ImageProvider<Object>?,
                      child: (_image == null &&
                              (widget.userData['profileImage'] == null ||
                                  widget.userData['profileImage'].isEmpty))
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: Icon(CupertinoIcons.camera_fill,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Enter Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Enter Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Enter Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    initialValue: address,
                    onChanged: (value) {
                      address = value;
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(13.0),
          child: InkWell(
            onTap: () async {
              EasyLoading.show(status: 'UPDATING');
              String? profileImageUrl = widget.userData['profileImage'];
              if (_image != null) {
                profileImageUrl = await _uploadImageToStorage(_image!);
              }
              await _firestore
                  .collection('buyers')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({
                'fullName': _fullNameController.text,
                'email': _emailController.text,
                'phoneNumber': _phoneController.text,
                'address': address,
                'profileImage': profileImageUrl,
              }).whenComplete(() {
                EasyLoading.dismiss();

                Navigator.pop(context);
              });
            },
            child: Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                  child: Text(
                'UPDATE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
