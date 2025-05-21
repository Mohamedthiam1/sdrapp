import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  late Timer _timer;
  late DateTime _currentTime;

  int _countdown = 10;
  bool _isLoading = false;

  final List<Map<String, dynamic>> hiveData = [
    {
      "id": "Ruche 1",
      "temperature": "34.6°C",
      "sound": "47.2 dB",
      "spectrum": [0.02, 0.15, 0.43, 0.23],
      "in": "153",
      "out": "147",
      "total": "300",
      "alert": false,
    },
    {
      "id": "Ruche 2",
      "temperature": "38.1°C",
      "sound": "33.5 dB",
      "spectrum": [0.01, 0.03, 0.02, 0.01],
      "in": "132",
      "out": "165",
      "total": "297",
      "alert": true,
    },
    {
      "id": "Ruche 3",
      "temperature": "28.1°C",
      "sound": "24.5 dB",
      "spectrum": [0.11, 0.7, 0.05, 0.11],
      "in": "114",
      "out": "99",
      "total": "213",
      "alert": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    // Timer pour mettre à jour l'heure toutes les secondes
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    // Timer pour gérer le décompte et la simulation de chargement
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isLoading) return;

      if (_countdown == 0) {
        setState(() {
          _isLoading = true;
        });

        // Simuler une opération avec 2 secondes de delay
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _isLoading = false;
          _countdown = 10;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')}/"
        "${time.year} "
        "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(182, 236, 224, 1.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: width * 0.85,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("🐝 Surveillance Ruches"),
                  Text(_formatTime(_currentTime),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.refresh_rounded)),
                const SizedBox(width: 8),
                _isLoading
                    ? const Text(
                  "loading...",
                  style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
                )
                    : Text(
                  '$_countdown s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              runSpacing: 30,
              spacing: 30,
              children: hiveData.map((hive) {
                return _buildHiveCard(hive, width);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiveCard(Map<String, dynamic> hive, double width) {
    List<double> spectrum = _parseSpectrum(hive['spectrum']);

    return Container(
      width: width / 2 - 40,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hive['alert'] ? Colors.red.shade100 : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hive['id'],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDataRow("🌡 Température", hive["temperature"]),
          _buildDataRow("🔊 Niveau sonore", hive["sound"]),
          _buildDataRow("🐝 Entrée", hive["in"]),
          _buildDataRow("🐝 Sortie", hive["out"]),
          _buildDataRow("📊 Activité totale", hive["total"]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎵 Spectre sonore",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                width: 100,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(spectrum.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: spectrum[index],
                            width: 12,
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      );
                    }),
                    gridData: FlGridData(show: false),
                    maxY: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hive["alert"]
                ? "⚠️ Alerte détectée sur cette ruche"
                : "✅ Données normales",
            style: TextStyle(
                color: hive["alert"] ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<double> _parseSpectrum(dynamic spectrum) {
    if (spectrum is List) {
      return spectrum
          .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)
          .toList();
    } else if (spectrum is String) {
      final cleaned = spectrum.replaceAll(RegExp(r'[\[\]\s]'), '');
      return cleaned
          .split(',')
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
    }
    return [];
  }
}
