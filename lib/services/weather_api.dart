import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather.dart';

class WeatherApi {
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String? apiKey = dotenv.env['OPENWEATHER_API_KEY'];

  Future<Weather> getCurrentWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=id'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Weather.fromJson(data);
    } else {
      throw Exception('Gagal memuat data cuaca');
    }
  }
}
