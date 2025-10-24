class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final int pressure;
  final DateTime sunrise;
  final DateTime sunset;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] ?? 'Tidak diketahui',
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'] != null && json['weather'].isNotEmpty
          ? json['weather'][0]['description'] ?? 'Tidak ada deskripsi'
          : 'Tidak ada deskripsi',
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      windDeg: json['wind']?['deg'] ?? 0,
      pressure: json['main']?['pressure'] ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        ((json['sys']?['sunrise'] ?? 0) as int) * 1000,
        isUtc: true,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        ((json['sys']?['sunset'] ?? 0) as int) * 1000,
        isUtc: true,
      ),
    );
  }
}
