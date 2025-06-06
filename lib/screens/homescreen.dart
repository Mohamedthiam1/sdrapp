import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  late Timer _timer;
  late DateTime _currentTime;
  int _countdown = 5;
  List<Map<String, dynamic>> hiveData = [];

  List<Map<String, dynamic>> hiveHistory = [];
  DateTime appStartTime = DateTime.now();

  final String apiUrl = 'https://beehives-api.esiea.fr/ruches';

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    appStartTime = _currentTime;

    _loadHiveData(); // Charger les données actuelles

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
        _countdown--;
      });

      if (_countdown <= 0) {
        _generateAndSendHiveData(); // Met à jour les données
        _storeCurrentHiveData();    // Stocke les données actuelles dans l'historique
        _countdown = 5;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final xMax = hiveHistory.length.toDouble();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(182, 236, 224, 1.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("🐝 Surveillance Ruches - ESIEA"),
            Text(_formatTime(_currentTime)),
            Row(
              children: [
                Text("$_countdown s"),
                IconButton(
                  onPressed: () {
                    _generateAndSendHiveData();
                    setState(() {
                      _countdown = 5;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHiveData,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Wrap(
                      key: ValueKey<int>(hiveData.length), // clé liée à la liste pour détecter le changement
                      runSpacing: 30,
                      spacing: 30,
                      children: hiveData.map((hive) {
                        return GestureDetector(
                          key: ValueKey(hive['id']), // clé unique par ruche
                          onTap: () => _showHiveDialog(existingHive: hive),
                          child: _buildHiveCard(hive, width),
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 15),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildLegendItem("Ruche 1", Colors.red),
                        _buildLegendItem("Ruche 2", Colors.blue),
                        _buildLegendItem("Ruche 3", Colors.green),
                      ],
                    ),
                  ),
                  buildChart("Température", "temperature"),
                  buildChart("Entrées", "in"),
                  buildChart("Sorties", "out"),
                  buildChart("Total", "total"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7))),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildHiveCard(Map<String, dynamic> hive, double width) {
    List<double> spectrum = _parseSpectrum(hive['spectrum']);
    final temperature = hive["temperature"] ?? 0.0;
    final fahrenheit = (temperature * 9 / 5) + 32;

    return Container(
      width: width / 2 - 40,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hive['alert'] == true
            ? Colors.red.shade100
            : const Color(0xFFE0EFD9),
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
          Text(hive['id'] ?? 'Inconnue',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDataRow("🌡 Température", "${temperature.toStringAsFixed(1)}°C / ${fahrenheit.toStringAsFixed(1)}°F"),
          _buildDataRow("🐝 Entrée", hive["in"].toString()),
          _buildDataRow("🐝 Sortie", hive["out"].toString()),
          _buildDataRow("📊 Activité totale", hive["total"].toString()),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🎵 Spectre sonore"),
              Container(
                height: 20,
                width: 100,
                margin: const EdgeInsets.only(top: 10),
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
          if (hive["alert"] == true) ...[
            const Text(
              "⚠️ Alerte détectée :",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...List<Widget>.from((hive["alertReasons"] as List<String>).map((r) => Text("• $r", style: const TextStyle(color: Colors.red))))
          ] else ...[
            const Text(
              "✅ Données normales",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ]
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _showHiveDialog({Map<String, dynamic>? existingHive}) async {
    final String generatedId = existingHive?['id'] ??
        'ruche_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}';

    final TextEditingController idController = TextEditingController(text: generatedId);
    final TextEditingController tempController = TextEditingController(
        text: existingHive?['temperature']?.toString() ?? '');
    final TextEditingController inController = TextEditingController(
        text: existingHive?['in']?.toString() ?? '');
    final TextEditingController outController = TextEditingController(
        text: existingHive?['out']?.toString() ?? '');
    final TextEditingController spectrumController = TextEditingController(
        text: _parseSpectrum(existingHive?['spectrum']).join(', '));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingHive == null ? "Ajouter une ruche" : "Modifier une ruche"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idController, decoration: const InputDecoration(labelText: "ID"), enabled: false),
              TextField(controller: tempController, decoration: const InputDecoration(labelText: "Température (°C)"), keyboardType: TextInputType.number),
              TextField(controller: inController, decoration: const InputDecoration(labelText: "Entrées"), keyboardType: TextInputType.number),
              TextField(controller: outController, decoration: const InputDecoration(labelText: "Sorties"), keyboardType: TextInputType.number),
              TextField(controller: spectrumController, decoration: const InputDecoration(labelText: "Spectre sonore (ex: 0.3, 0.5, 0.8, 0.2)"), keyboardType: TextInputType.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              List<double> parsedSpectrum = spectrumController.text
                  .split(',')
                  .map((e) => double.tryParse(e.trim()) ?? 0.0)
                  .toList();

              final inCount = int.tryParse(inController.text) ?? 0;
              final outCount = int.tryParse(outController.text) ?? 0;

              final newHive = {
                "id": idController.text,
                "temperature": double.tryParse(tempController.text) ?? 0.0,
                "in": inCount,
                "out": outCount,
                "total": inCount + outCount,
                "spectrum": parsedSpectrum,
                "alert": false,
              };

              final hiveId = idController.text;
              final url = 'http://localhost:8081/api/ruches/$hiveId';

              final spectrum = newHive["spectrum"] as List<double>? ?? [];

              final response = await http.put(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  "temperature": newHive["temperature"],
                  "activity_in": newHive["in"],
                  "activity_out": newHive["out"],
                  "sound_spectrum_1": spectrum.isNotEmpty ? spectrum[0] : 0.0,
                  "sound_spectrum_2": spectrum.length > 1 ? spectrum[1] : 0.0,
                  "sound_spectrum_3": spectrum.length > 2 ? spectrum[2] : 0.0,
                  "sound_spectrum_4": spectrum.length > 3 ? spectrum[3] : 0.0,
                }),
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                Navigator.pop(context);
                _loadHiveData();
              } else {
                debugPrint("Erreur lors de l'envoi: ${response.statusCode}");
                debugPrint("Message serveur : ${response.body}");
              }
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  Widget buildChart(String label, String keyName) {
    List<Color> colors = [Colors.red, Colors.green, Colors.blue];
    List<String> rucheIds = ['ruche_1', 'ruche_2', 'ruche_3'];

    // 🔹 Extraire la valeur maximale de 'time'
    double xMax = hiveHistory.map((h) => h["time"] as double).fold(0.0, (prev, curr) => curr > prev ? curr : prev);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: LineChart(
                  LineChartData(
                    lineBarsData: rucheIds.asMap().entries.map((entry) {
                      int i = entry.key;
                      String id = entry.value;

                      List<FlSpot> spots = hiveHistory
                          .where((h) => h["id"] == id)
                          .map((h) => FlSpot(h["time"], (h[keyName] as num).toDouble()))
                          .toList();

                      return LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: colors[i],
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      );
                    }).toList(),
                    minX: 0,
                    maxX: xMax,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        // tooltipBgColor: Colors.white,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final color = spot.bar?.color ?? Colors.black; // Sécurité si `bar` est null
                            return LineTooltipItem(
                              spot.y.toStringAsFixed(1),
                              TextStyle(color: color, fontWeight: FontWeight.bold),
                            );
                          }).toList();

                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: _getInterval(xMax),
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}s', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getInterval(double maxX) {
    if (maxX <= 20) return 1;
    return (maxX / 20).ceilToDouble(); // max 20 labels
  }

  void _storeCurrentHiveData() {
    final timeSinceStart = DateTime.now().difference(appStartTime).inSeconds.toDouble();

    for (var hive in hiveData) {
      hiveHistory.add({
        "id": hive["id"],
        "time": timeSinceStart,
        "temperature": hive["temperature"],
        "in": hive["in"],
        "out": hive["out"],
        "total": hive["total"]
      });
    }
  }

  Future<void> _loadHiveData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Map<String, dynamic>> loadedHives = [];

      for (var hive in data) {
        final parsedHive = {
          "id": hive["hive_id"],
          "temperature": hive["temperature"],
          "in": hive["activity_in"],
          "out": hive["activity_out"],
          "total": hive["activity_in"] + hive["activity_out"],
          "spectrum": [
            hive["sound_spectrum_1"],
            hive["sound_spectrum_2"],
            hive["sound_spectrum_3"],
            hive["sound_spectrum_4"]
          ],
        };

        parsedHive["alertReasons"] = getAlertReasons(parsedHive);
        parsedHive["alert"] = parsedHive["alertReasons"].isNotEmpty;
        loadedHives.add(parsedHive);
      }

      setState(() {
        hiveData = loadedHives;
      });
    }
  }

  Future<void> _generateAndSendHiveData() async {
    final random = Random();
    List<Map<String, dynamic>> newData = List.generate(3, (index) {
      final temperature = 5 + random.nextDouble() * 40;
      final inCount = random.nextInt(101);
      final outCount = random.nextInt(101);
      final total = inCount + outCount;
      final spectrum = List.generate(4, (_) => double.parse((random.nextDouble()).toStringAsFixed(2)));

      final hive = {
        "id": "ruche_${index + 1}",
        "temperature": temperature,
        "in": inCount,
        "out": outCount,
        "total": total,
        "spectrum": spectrum,
      };

      hive["alertReasons"] = getAlertReasons(hive);
      hive["alert"] = (hive["alertReasons"] as List?)?.isNotEmpty ?? false;

      return hive;
    });

    for (var hive in newData) {
      await http.put(
        Uri.parse("$apiUrl/${hive['id']}"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "temperature": hive["temperature"],
          "activity_in": hive["in"],
          "activity_out": hive["out"],
          "sound_spectrum_1": hive["spectrum"][0],
          "sound_spectrum_2": hive["spectrum"][1],
          "sound_spectrum_3": hive["spectrum"][2],
          "sound_spectrum_4": hive["spectrum"][3],
        }),
      );
    }

    setState(() {
      hiveData = newData;
    });
  }

  String _formatTime(DateTime time) {
    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')}/"
        "${time.year} "
        "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}";
  }

  List<String> getAlertReasons(Map<String, dynamic> hive) {
    List<String> reasons = [];

    final temperature = hive["temperature"] is num ? hive["temperature"].toDouble() : 0.0;
    final inCount = hive["in"] ?? 0;
    final outCount = hive["out"] ?? 0;
    final total = hive["total"] ?? 0;
    final spectrum = _parseSpectrum(hive["spectrum"]);

    if (temperature < 10) {
      reasons.add("Température trop basse (moins de 10°C)");
    } else if (temperature > 40) {
      reasons.add("Température trop élevée (plus de 40°C)");
    }

    if (total == 0) {
      reasons.add("Aucune activité détectée");
    } else {
      if (outCount >= total * 0.9) {
        reasons.add("Sortie anormale élevée");
      }
      if (outCount == 0 && inCount > 0) {
        reasons.add("Entrées sans sorties détectées");
      }
    }

    if (spectrum.isNotEmpty) {
      final maxVal = spectrum.reduce(max);
      final avgVal = spectrum.reduce((a, b) => a + b) / spectrum.length;

      if (maxVal > 0.9) {
        reasons.add("Pics sonores élevés détectés");
      } else if (avgVal < 0.05) {
        reasons.add("Spectre sonore très faible");
      }
    } else {
      reasons.add("Spectre sonore manquant");
    }

    return reasons;
  }

  List<double> _parseSpectrum(dynamic spectrum) {
    if (spectrum is List) {
      return spectrum.map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0).toList();
    } else if (spectrum is String) {
      return spectrum.split(',').map((s) => double.tryParse(s) ?? 0.0).toList();
    }
    return [];
  }

}
