import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.get(Uri.parse('http://ip-api.com/json'));
  if (response.statusCode == 200) {
    print(jsonDecode(response.body));
  }
}
