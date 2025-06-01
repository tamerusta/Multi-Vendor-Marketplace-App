import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class DialogflowService {
  Future<dynamic> sendMessage(String text,
      {String? buyerId, String? orderId}) async {
    try {
      var queryInput = text == 'GetAnotherRecommendation'
          ? {
              'event': {
                'name': 'GET_ANOTHER_RECOMMENDATION',
                'parameters': {'buyerId': buyerId}
              }
            }
          : {
              'text': {'text': text, 'languageCode': 'tr'}
            };

      final response = await http.post(
        Uri.parse('${Config.webhookUrl}/dialogflow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'queryInput': queryInput,
          'queryParams': {
            'payload': {
              'buyerId': buyerId,
              'orderId': orderId,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
