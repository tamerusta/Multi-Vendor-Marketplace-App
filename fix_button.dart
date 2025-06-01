// Yeni ve iyileştirilmiş chat button işleme fonksiyonu
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Bu kod parçasını _ChatScreenState sınıfının içine kopyala ve _processMessageWithButton fonksiyonunu değiştir.
void _processMessageWithButton(String response) {
  print('Processing button message: $response');

  // Basit bir yaklaşım - RECOMMENDATION_BUTTON öncesini mesaj, sonrasını JSON olarak kabul et
  final int buttonIndex = response.indexOf('RECOMMENDATION_BUTTON');
  if (buttonIndex != -1) {
    final String message = response.substring(0, buttonIndex).trim();
    final String jsonStr =
        response.substring(buttonIndex + 'RECOMMENDATION_BUTTON'.length).trim();

    print('Message part: $message');
    print('JSON part: $jsonStr');

    // Önce mesajı ekle
    setState(() {
      _messages.add({'bot': message});
    });

    try {
      // JSON'ı parse et
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
    // Eğer RECOMMENDATION_BUTTON içermiyorsa normal mesaj olarak ekle
    _addMessage(response, false);
  }

  _scrollToBottom();
}
