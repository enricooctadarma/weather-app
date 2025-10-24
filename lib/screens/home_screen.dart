import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/weather_api.dart';
import '../models/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final WeatherApi weatherApi = WeatherApi();
  final TextEditingController _controller = TextEditingController();

  Weather? _weather;
  bool _loading = false;
  String? _errorMessage;

  // Controllers
  late final AnimationController _rotateController;
  late final AnimationController _titleController;

  // Hover states (per widget)
  bool _hoverCard = false;
  bool _hoverCari = false;
  bool _hoverReplay = false;
  bool _hoverVisit = false;
  bool _hoverTextField = false;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://enrico.vercel.app');
    try {
      if (kIsWeb) {
        await launchUrl(uri);
      } else {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) _showSnack('Gagal membuka website');
      }
    } catch (_) {
      _showSnack('Gagal membuka website');
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _searchWeather() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Isi dulu ya bro/sis...');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _weather = null;
    });

    try {
      final result = await weatherApi.getCurrentWeather(query);
      setState(() {
        _weather = result;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _weather = null;
        _errorMessage = 'Negara/Kota tidak ditemukan, coba lagi ya..';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetSearch() {
    _controller.clear();
    setState(() {
      _weather = null;
      _errorMessage = null;
    });
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _buildWeatherIcon(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('cloud')) {
      return const Icon(Icons.cloud, size: 80, color: Colors.white);
    } else if (lower.contains('rain')) {
      return const Icon(Icons.beach_access, size: 80, color: Colors.white);
    } else if (lower.contains('clear')) {
      return AnimatedBuilder(
        animation: _rotateController,
        builder: (_, child) => Transform.rotate(
          angle: _rotateController.value * 2 * pi,
          child: child,
        ),
        child: const Icon(Icons.wb_sunny, size: 80, color: Colors.yellow),
      );
    } else if (lower.contains('snow')) {
      return const Icon(Icons.ac_unit, size: 80, color: Colors.white);
    } else {
      return const Icon(Icons.wb_cloudy, size: 80, color: Colors.white);
    }
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildWeatherCard() {
    if (_weather == null) {
      return const Text(
        'Masukkan nama Negara/Kota untuk mendeteksi cuaca terkini',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.white70),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverCard = true),
      onExit: (_) => setState(() => _hoverCard = false),
      child: AnimatedScale(
        scale: _hoverCard ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          color: Colors.white.withOpacity(0.15),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWeatherIcon(_weather!.description),
                const SizedBox(height: 10),
                Text(
                  _weather!.cityName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_weather!.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _weather!.description,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24),
                _infoRow('💧 Kelembapan', '${_weather!.humidity}%'),
                _infoRow(
                  '🌬️ Angin',
                  '${_weather!.windSpeed} km/j, ${_weather!.windDeg}°',
                ),
                _infoRow('📈 Tekanan', '${_weather!.pressure} hPa'),
                _infoRow('🌅 Terbit', _formatTime(_weather!.sunrise)),
                _infoRow('🌇 Terbenam', _formatTime(_weather!.sunset)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedBackground() => AnimatedBuilder(
    animation: _rotateController,
    builder: (context, _) {
      final t = sin(_rotateController.value * 2 * pi);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(t),
            colors: [
              const Color.fromARGB(255, 237, 147, 255),
              const Color.fromARGB(255, 62, 0, 179),
              const Color.fromARGB(255, 9, 1, 73),
            ],
          ),
        ),
      );
    },
  );

  Widget _pulseTitle() {
    return ScaleTransition(
      scale: Tween(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
      ),
      child: const Text(
        'WEATHER APP BY ENRICO',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainAccent = Colors.deepPurpleAccent;

    return Scaffold(
      body: Stack(
        children: [
          _animatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = min(560.0, constraints.maxWidth * 0.9);
                          return Column(
                            children: [
                              _pulseTitle(),
                              const SizedBox(height: 10),
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoverVisit = true),
                                onExit: (_) =>
                                    setState(() => _hoverVisit = false),
                                child: AnimatedScale(
                                  scale: _hoverVisit ? 1.05 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  child: TextButton(
                                    onPressed: _openWebsite,
                                    style: TextButton.styleFrom(
                                      backgroundColor: mainAccent.withOpacity(
                                        0.15,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Visit my web',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Row(
                          children: [
                            if (_weather != null)
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoverReplay = true),
                                onExit: (_) =>
                                    setState(() => _hoverReplay = false),
                                child: AnimatedScale(
                                  scale: _hoverReplay ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  child: IconButton(
                                    tooltip: 'Reset',
                                    onPressed: _resetSearch,
                                    icon: const Icon(
                                      Icons.replay,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 8),
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoverTextField = true),
                                onExit: (_) =>
                                    setState(() => _hoverTextField = false),
                                child: AnimatedScale(
                                  scale: _hoverTextField ? 1.02 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  child: TextField(
                                    controller: _controller,
                                    onSubmitted: (_) => _searchWeather(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ketik nama Negara atau Kota...',
                                      hintStyle: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.95),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            MouseRegion(
                              onEnter: (_) => setState(() => _hoverCari = true),
                              onExit: (_) => setState(() => _hoverCari = false),
                              child: AnimatedScale(
                                scale: _hoverCari ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                child: ElevatedButton(
                                  onPressed: _searchWeather,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mainAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Cari',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      _buildWeatherCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
