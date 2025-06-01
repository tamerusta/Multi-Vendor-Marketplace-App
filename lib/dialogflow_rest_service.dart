import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class DialogflowRestService {
  final String _projectId = 'multi-vendor-store-df606';
  final String _sessionId = 'unique-session-id';
  AccessCredentials? _credentials;
  bool _isInitializing = false;

  DialogflowRestService() {
    _initializeAuthToken();
  }

  Future<void> _initializeAuthToken() async {
    if (_credentials != null || _isInitializing) return;

    try {
      _isInitializing = true;
      final jsonString = await rootBundle
          .loadString('assets/multi-vendor-store-df606-f64c0b32b7e6.json');
      final jsonData = jsonDecode(jsonString);

      final serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(jsonData);
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

      final client =
          await clientViaServiceAccount(serviceAccountCredentials, scopes);
      _credentials = client.credentials;
    } catch (e) {
      print('Error initializing auth token: $e');
      _isInitializing = false;
      rethrow;
    }
    _isInitializing = false;
  }

  Future<String> sendMessage(String message, {String? buyerId}) async {
    try {
      if (_credentials == null) {
        await _initializeAuthToken();
      }

      if (_credentials == null) {
        throw Exception('Failed to initialize credentials');
      }

      final url = Uri.parse(
        'https://dialogflow.googleapis.com/v2/projects/$_projectId/agent/sessions/$_sessionId:detectIntent',
      );

      final headers = {
        'Authorization': 'Bearer ${_credentials!.accessToken.data}',
        'Content-Type': 'application/json',
      };
      final queryInput = message.toLowerCase() == 'give another recommendation'
          ? {
              'event': {
                'name': 'GET_ANOTHER_RECOMMENDATION',
                'parameters': {'buyerId': buyerId}
              },
              'languageCode': 'en',
            }
          : {
              'text': {
                'text': message,
                'languageCode': 'en',
              }
            };
      final contexts = buyerId != null
          ? [
              {
                'name':
                    'projects/$_projectId/agent/sessions/$_sessionId/contexts/user-context',
                'lifespanCount': 5,
                'parameters': {'buyerId': buyerId}
              },
              {
                'name':
                    'projects/$_projectId/agent/sessions/$_sessionId/contexts/buyer-context',
                'lifespanCount': 5,
                'parameters': {'buyerId': buyerId}
              }
            ]
          : [];

      final body = jsonEncode({
        'queryInput': queryInput,
        'queryParams': {
          'contexts': contexts,
          'payload': buyerId != null ? {'buyerId': buyerId} : null
        }
      });

      print('User ID being sent: ${buyerId ?? "Not logged in"}');
      print('Sending request to Dialogflow: $body');

      final response = await http
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Dialogflow response: ${response.body}');
        final fulfillmentText = data['queryResult']['fulfillmentText'] ??
            'No response from Dialogflow';
        print('Fulfillment text: $fulfillmentText');
        return fulfillmentText;
      } else {
        print('Dialogflow error: ${response.body}');
        throw Exception('Failed to connect to Dialogflow: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      if (e.toString().contains('ENETUNREACH') ||
          e.toString().contains('Network is unreachable')) {
        return 'Sorry, I\'m having trouble connecting to the network. Please check your internet connection and try again.';
      }
      return 'Sorry, there was an error processing your message. Please try again.';
    }
  }
}
