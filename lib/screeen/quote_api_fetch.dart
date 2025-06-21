import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/quotes_model.dart';

Future<QuotesModel> fetchQuotes() async {
  final response = await http.get(Uri.parse('https://dummyjson.com/quotes'));

  if (response.statusCode == 200) {
    return QuotesModel.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load quotes');
  }
}
