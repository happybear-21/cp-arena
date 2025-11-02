import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contest> upcomingContests = [];
  bool isLoading = true;
  String? error;
  Set<String> selectedPlatforms = {
    'Codeforces',
    'LeetCode',
    'AtCoder',
    'CodeChef',
  };

  final Map<String, Color> platformColors = {
    'Codeforces': Colors.blue,
    'LeetCode': const Color(0xFFFFA116),
    'AtCoder': Colors.red,
    'CodeChef': const Color(0xFF5B4638),
  };

  @override
  void initState() {
    super.initState();
    fetchContests();
  }

  Future<void> fetchContests() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    List<Contest> allContests = [];

    try {
      if (selectedPlatforms.contains('Codeforces')) {
        allContests.addAll(await fetchCodeforcesContests());
      }
      if (selectedPlatforms.contains('LeetCode')) {
        allContests.addAll(await fetchLeetCodeContests());
      }
      if (selectedPlatforms.contains('AtCoder')) {
        allContests.addAll(await fetchAtCoderContests());
      }
      if (selectedPlatforms.contains('CodeChef')) {
        allContests.addAll(await fetchCodeChefContests());
      }

      allContests.sort(
        (a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds),
      );

      setState(() {
        upcomingContests = allContests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error fetching contests: $e';
        isLoading = false;
      });
    }
  }

  Future<List<Contest>> fetchCodeforcesContests() async {
    try {
      final response = await http.get(
        Uri.parse('https://codeforces.com/api/contest.list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List contests = data['result'];
          return contests
              .where((c) => c['phase'] == 'BEFORE')
              .map((c) => Contest.fromCodeforcesJson(c))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Codeforces fetch error: $e');
    }
    return [];
  }

  Future<List<Contest>> fetchLeetCodeContests() async {
    try {
      final response = await http.post(
        Uri.parse('https://leetcode.com/graphql'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': '''
            query {
              allContests {
                title
                titleSlug
                startTime
                duration
              }
            }
          ''',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['allContests'] != null) {
          final List contests = data['data']['allContests'];
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          return contests
              .where((c) => c['startTime'] != null && c['startTime'] > now)
              .map((c) => Contest.fromLeetCodeJson(c))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('LeetCode fetch error: $e');
    }
    return [];
  }

  Future<List<Contest>> fetchAtCoderContests() async {
    try {
      final response = await http.get(
        Uri.parse('https://contest-hive.vercel.app/api/atcoder'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['data'] != null) {
          final List contests = data['data'];
          return contests
              .map((c) => Contest.fromContestHiveJson(c, 'AtCoder'))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('AtCoder fetch error: $e');
    }
    return [];
  }

  Future<List<Contest>> fetchCodeChefContests() async {
    try {
      final response = await http.get(
        Uri.parse('https://contest-hive.vercel.app/api/codechef'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['data'] != null) {
          final List contests = data['data'];
          return contests
              .map((c) => Contest.fromContestHiveJson(c, 'CodeChef'))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('CodeChef fetch error: $e');
    }
    return [];
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Platforms',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...platformColors.entries.map((entry) {
                    final platform = entry.key;
                    final color = entry.value;
                    final isSelected = selectedPlatforms.contains(platform);

                    return CheckboxListTile(
                      title: Text(
                        platform,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      value: isSelected,
                      activeColor: color,
                      checkColor: Colors.white,
                      onChanged: (bool? value) {
                        setModalState(() {
                          setState(() {
                            if (value == true) {
                              selectedPlatforms.add(platform);
                            } else {
                              selectedPlatforms.remove(platform);
                            }
                          });
                        });
                        fetchContests();
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String formatTimeUntil(int seconds) {
    final duration = Duration(seconds: seconds.abs());
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header without AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Contests',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: isDark ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        onPressed: _showFilterBottomSheet,
                        tooltip: 'Filter',
                      ),
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        onPressed: widget.onThemeToggle,
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contest list
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white : Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                      : error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchContests,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? Colors.white : Colors.black,
                                foregroundColor:
                                    isDark ? Colors.black : Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : upcomingContests.isEmpty
                      ? Center(
                        child: Text(
                          'No upcoming contests',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                      : RefreshIndicator(
                        color: isDark ? Colors.white : Colors.black,
                        onRefresh: fetchContests,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
            ),
          ],
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

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'codeforces':
        return Colors.blue;
      case 'leetcode':
        return const Color(0xFFFFA116);
      case 'atcoder':
        return Colors.red;
      case 'codechef':
        return const Color(0xFF5B4638);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      contest.startTimeSeconds * 1000,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
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
                    color: _getPlatformColor(contest.platform),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contest.platform.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (contest.type != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contest.type!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              contest.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
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
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'DURATION',
                    value: formatDuration(contest.durationSeconds),
                    isDark: isDark,
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
  final bool isDark;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

class Contest {
  final int id;
  final String name;
  final String? type;
  final String platform;
  final int durationSeconds;
  final int startTimeSeconds;
  final int relativeTimeSeconds;

  Contest({
    required this.id,
    required this.name,
    this.type,
    required this.platform,
    required this.durationSeconds,
    required this.startTimeSeconds,
    required this.relativeTimeSeconds,
  });

  factory Contest.fromCodeforcesJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      platform: 'Codeforces',
      durationSeconds: json['durationSeconds'],
      startTimeSeconds: json['startTimeSeconds'],
      relativeTimeSeconds: json['relativeTimeSeconds'],
    );
  }

  factory Contest.fromLeetCodeJson(Map<String, dynamic> json) {
    final startTime = json['startTime'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Contest(
      id: json['titleSlug'].hashCode,
      name: json['title'],
      type: null,
      platform: 'LeetCode',
      durationSeconds: json['duration'] ?? 5400,
      startTimeSeconds: startTime,
      relativeTimeSeconds: startTime - now,
    );
  }

  factory Contest.fromContestHiveJson(
    Map<String, dynamic> json,
    String platform,
  ) {
    final startTime =
        DateTime.parse(json['startTime']).millisecondsSinceEpoch ~/ 1000;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Contest(
      id: json['url'].hashCode,
      name: json['title'],
      type: null,
      platform: platform,
      durationSeconds: json['duration'] ?? 0,
      startTimeSeconds: startTime,
      relativeTimeSeconds: startTime - now,
    );
  }
}
