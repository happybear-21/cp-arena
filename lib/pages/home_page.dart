import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contest Aggregator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          surface: Colors.grey.shade50,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contest> upcomingContests = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContests();
  }

  Future<void> fetchContests() async {
    try {
      final response = await http.get(
        Uri.parse('https://codeforces.com/api/contest.list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List contests = data['result'];
          setState(() {
            upcomingContests =
                contests
                    .where((c) => c['phase'] == 'BEFORE')
                    .map((c) => Contest.fromJson(c))
                    .toList();
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load contests';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    return '${hours}h ${(seconds % 3600) ~/ 60}m';
  }

  String formatTimeUntil(int seconds) {
    final duration = Duration(seconds: seconds.abs());
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Upcoming Contests',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.grey)),
              )
              : RefreshIndicator(
                color: Colors.black,
                onRefresh: fetchContests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: upcomingContests.length,
                  itemBuilder: (context, index) {
                    final contest = upcomingContests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ContestCard(
                        contest: contest,
                        formatDuration: formatDuration,
                        formatTimeUntil: formatTimeUntil,
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class ContestCard extends StatelessWidget {
  final Contest contest;
  final String Function(int) formatDuration;
  final String Function(int) formatTimeUntil;

  const ContestCard({
    super.key,
    required this.contest,
    required this.formatDuration,
    required this.formatTimeUntil,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      contest.startTimeSeconds * 1000,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CODEFORCES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  contest.type,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              contest.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'STARTS IN',
                    value: formatTimeUntil(contest.relativeTimeSeconds),
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'DURATION',
                    value: formatDuration(contest.durationSeconds),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${startTime.day}/${startTime.month}/${startTime.year} at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class Contest {
  final int id;
  final String name;
  final String type;
  final String phase;
  final int durationSeconds;
  final int startTimeSeconds;
  final int relativeTimeSeconds;

  Contest({
    required this.id,
    required this.name,
    required this.type,
    required this.phase,
    required this.durationSeconds,
    required this.startTimeSeconds,
    required this.relativeTimeSeconds,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      phase: json['phase'],
      durationSeconds: json['durationSeconds'],
      startTimeSeconds: json['startTimeSeconds'],
      relativeTimeSeconds: json['relativeTimeSeconds'],
    );
  }
}
