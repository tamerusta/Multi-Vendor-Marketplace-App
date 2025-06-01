import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dialogflow_rest_service.dart';
import 'views/buyers/nav_screens/store_detail_screen.dart';
import 'views/buyers/inner_screens/all_products_screen.dart';

class FloatingChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.blue.shade900,
      child: Icon(Icons.chat, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final DialogflowRestService dialogflowService = DialogflowRestService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _initializeChat() {
    _messages.add({
      'bot':
          'Hello! I\'m your shopping assistant. I can help you with product recommendations, order tracking, and more. How can I assist you today?'
    });
    setState(() {});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addMessage(String text, bool isUserMessage) {
    setState(() {
      if (isUserMessage) {
        _messages.add({'user': text});
      } else {
        _messages.add({'bot': text});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _addMessage(message, true);
    _messageController.clear();

    try {
      // Get current user ID if logged in
      String? buyerId;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        buyerId = user.uid;
        print('User is logged in with ID: $buyerId');
      } else {
        print('No user is currently logged in');
      }

      // Log the current auth state
      print('Current auth state - isLoggedIn: ${user != null}');

      final response = await dialogflowService.sendMessage(
        message,
        buyerId: buyerId,
      );

      print('Raw response from Dialogflow: $response');

      // Handle recommendation buttons if present
      if (response.contains('RECOMMENDATION_BUTTON')) {
        _processMessageWithButton(response);
      } else {
        _addMessage(response, false);
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.add({'bot': 'An error occurred. Please try again.'});
      });
      _scrollToBottom();
    }
  }

  void _processMessageWithButton(String response) {
    print('Processing button message: $response');

    final int buttonIndex = response.indexOf('RECOMMENDATION_BUTTON');
    if (buttonIndex != -1) {
      final String message = response.substring(0, buttonIndex).trim();
      final String jsonStr = response
          .substring(buttonIndex + 'RECOMMENDATION_BUTTON'.length)
          .trim();
      print('Message part: $message');
      print('JSON part: $jsonStr');

      setState(() {
        _messages.add({'bot': message});
      });

      try {
        final Map<String, dynamic> buttonData = jsonDecode(jsonStr);
        print('Parsed JSON: $buttonData');

        setState(() {
          _messages.add({
            'bot': '',
            'button': buttonData,
          });
        });
      } catch (e) {
        print('JSON parse error: $e');
        _addMessage('Could not process recommendation data', false);
      }
    } else {
      _addMessage(response, false);
    }

    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ClipRRect(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Shopping Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.containsKey('user');

                      String messageText = '';
                      if (isUser && message['user'] != null) {
                        messageText = message['user'].toString();
                      } else if (!isUser && message['bot'] != null) {
                        messageText = message['bot'].toString();
                      }

                      Widget? button;
                      if (!isUser && message['button'] is Map) {
                        final buttonData = message['button'] as Map;

                        if (buttonData['data'] is Map) {
                          button = FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('vendors')
                                .doc(buttonData['data']['vendorId'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                );
                              }

                              final vendorData = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              final storeImage =
                                  vendorData?['storeImage'] as String?;
                              final storeName =
                                  vendorData?['bussinessName'] as String?;

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 2,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                        color: Colors.blue.shade900
                                            .withOpacity(0.5)),
                                  ),
                                ),
                                onPressed: () async {
                                  final data = buttonData['data'] as Map;
                                  final action = data['action']?.toString();

                                  if (action == 'openVendor') {
                                    final vendorId =
                                        data['vendorId']?.toString();
                                    if (vendorId != null &&
                                        snapshot.data != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StoreDetailScreen(
                                            storeData: snapshot.data!,
                                          ),
                                        ),
                                      );
                                    }
                                  } else if (action == 'openCategory') {
                                    final categoryName =
                                        data['categoryName']?.toString();
                                    if (categoryName != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AllProductScreen(
                                            categoryData: {
                                              'categoryName': categoryName,
                                              'image': data['categoryImage'],
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: storeImage != null
                                          ? NetworkImage(storeImage)
                                          : null,
                                      child: storeImage == null
                                          ? Icon(Icons.store,
                                              size: 15, color: Colors.white)
                                          : null,
                                      backgroundColor: Colors.blue.shade900,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        storeName ?? 'Visit Store',
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.blue.shade900,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      }

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 10,
                            left: isUser ? 50 : 0,
                            right: isUser ? 0 : 50,
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                messageText,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              if (button != null) ...[
                                SizedBox(height: 8),
                                button,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
