import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Root reference
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();

  // Function to update on1 variable (toggle true/false)
  Future<void> _toggleOn1(bool value) async {
    await _rootRef.update({'on1': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- Live Data Card ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder(
                  stream: _rootRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.value != null) {
                      final data = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map,
                      );

                      final moisture = data['moisture']?.toString() ?? 'N/A';
                      final waterLevel = data['water_level']?['cm']?.toString() ?? 'N/A';
                      final humidity = data['humidity']?.toString() ?? 'N/A';
                      final temperature = data['temperature']?.toString() ?? 'N/A';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics,
                              size: 48, color: Colors.indigo),
                          const SizedBox(height: 12),
                          Text(
                            "💧 Water Level: $waterLevel cm",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "🌱 Moisture: $moisture",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "🌡 Temperature: $temperature °C",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "💦 Humidity: $humidity %",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    }
                    return const Text(
                      "No data available in the database.",
                      style: TextStyle(color: Colors.grey),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- ON1 Control Card ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder(
                  stream: _rootRef.child('on1').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    bool isOn1 = false;
                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.value != null) {
                      isOn1 = snapshot.data!.snapshot.value as bool;
                    }

                    return Column(
                      children: [
                        const Icon(Icons.power_settings_new,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(
                          "ON1 is ${isOn1 ? "ON" : "OFF"}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          value: isOn1,
                          onChanged: (value) => _toggleOn1(value),
                          title: const Text("Toggle ON1"),
                          activeColor: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
