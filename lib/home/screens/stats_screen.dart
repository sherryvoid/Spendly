import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:Spendly/utils/timeFormatter.dart';

Future<List<QueryDocumentSnapshot>> fetchUserExpenses() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

  return snapshot.docs;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatsScreen> {
  List<Map<String, dynamic>> allExpenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];

  String selectedFilter = 'Day';
  DateTime? selectedDate;
  List<String> categories = ['All'];
  String selectedCategory = 'All';

  final List<String> filters = ['Day', 'Week', 'Month', 'Year'];
  final Color themeColor = const Color(0xFF2E6D6A);
  final Color redColor = Colors.red.shade400;
  bool isLoading = true;

  Future<void> loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .get();

    // Extract unique categories
    final categoriesSet = <String>{};
    for (var doc in snapshot.docs) {
      final category = doc['category'];
      if (category != null &&
          category is String &&
          category.trim().isNotEmpty) {
        categoriesSet.add(category);
      }
    }

    setState(() {
      categories = ['All', ...categoriesSet.toList()]; // include "All"
    });
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); // set default
    loadCategories();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    setState(() {
      isLoading = true;
    });
    final docs = await fetchUserExpenses();

    setState(() {
      // Load all expenses from Firestore
      allExpenses =
          docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where(
                (data) => data.containsKey('date') && data['date'] is Timestamp,
              )
              .toList();
      isLoading = false;

      // You can choose to initialize selectedDate here if not set
      selectedDate ??= DateTime.now(); // optional fallback

      // Apply filters now that data and date are set
      applyFilters();
    });
  }

  void applyFilters() {
    if (selectedDate == null) return;

    final normalizedSelectedDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );

    setState(() {
      filteredExpenses =
          allExpenses.where((expense) {
            final rawDate = expense['date'];
            if (rawDate is! Timestamp) return false;

            final date = rawDate.toDate().toLocal();
            final normalizedExpenseDate = DateTime(
              date.year,
              date.month,
              date.day,
            );

            final matchesCategory =
                selectedCategory == 'All' ||
                expense['category'] == selectedCategory;

            bool matchesDate = false;

            if (selectedFilter == 'Day') {
              matchesDate = normalizedExpenseDate == normalizedSelectedDate;
            } else if (selectedFilter == 'Week') {
              final startOfWeek = normalizedSelectedDate.subtract(
                Duration(days: normalizedSelectedDate.weekday - 1),
              );
              final endOfWeek = startOfWeek.add(const Duration(days: 6));

              matchesDate =
                  date.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                  ) &&
                  date.isBefore(endOfWeek.add(const Duration(days: 1)));
            } else if (selectedFilter == 'Month') {
              matchesDate =
                  date.month == normalizedSelectedDate.month &&
                  date.year == normalizedSelectedDate.year;
            } else if (selectedFilter == 'Year') {
              matchesDate = date.year == normalizedSelectedDate.year;
            }

            return matchesDate && matchesCategory;
          }).toList();
    });
  }

  List<FlSpot> generateChartSpots() {
    if (filteredExpenses.isEmpty || selectedDate == null) {
      // Return default spots to prevent chart errors
      return [FlSpot(0, 0), FlSpot(1, 0)];
    }

    Map<int, double> dataMap = {};

    for (var expense in filteredExpenses) {
      final date = (expense['date'] as Timestamp).toDate();
      final amount = (expense['amount'] as num).toDouble();

      int key = 0;

      if (selectedFilter == 'Day') {
        key = date.hour;
      } else if (selectedFilter == 'Week') {
        key = date.weekday;
      } else if (selectedFilter == 'Month') {
        key = date.day;
      } else if (selectedFilter == 'Year') {
        key = date.month;
      }

      dataMap[key] = (dataMap[key] ?? 0) + amount;
    }

    final sortedKeys = dataMap.keys.toList()..sort();

    // Ensure we have at least 2 points for the chart
    if (sortedKeys.isEmpty) {
      return [FlSpot(0, 0), FlSpot(1, 0)];
    }

    final spots =
        sortedKeys.map((k) => FlSpot(k.toDouble(), dataMap[k]!)).toList();

    // If we only have one point, add a second point to prevent chart errors
    if (spots.length == 1) {
      spots.add(FlSpot(spots.first.x + 1, 0));
    }

    return spots;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    final nonNegativeYs = spots.map((e) => e.y).where((y) => y >= 0);
    if (nonNegativeYs.isEmpty) return 100;

    final maxY = nonNegativeYs.reduce((a, b) => a > b ? a : b);

    // If all values are 0, return a reasonable default
    if (maxY == 0) return 100;

    final interval = _getYInterval(spots);
    return (maxY / interval).ceil() * interval;
  }

  double _getYInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;

    final nonNegativeYs = spots.map((e) => e.y).where((y) => y >= 0);
    if (nonNegativeYs.isEmpty) return 10;

    final maxY = nonNegativeYs.reduce((a, b) => a > b ? a : b);

    if (maxY == 0) return 10;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 50;
  }

  double _getInterval(String filter) {
    switch (filter) {
      case 'Day':
        return 2; // Every 2 hours for better spacing
      case 'Week':
        return 1; // Mon to Sun
      case 'Month':
        return 5; // Every 5th day
      case 'Year':
        return 1; // Jan to Dec
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = generateChartSpots();
    final positiveSpots = spots.where((spot) => spot.y >= 0).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Statistics"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Wrap(
              spacing: 28,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children:
                  filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                        applyFilters();
                      },
                      selectedColor: themeColor,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      selectedShadowColor: Colors.white,
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Date Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                      applyFilters();
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate != null
                        ? DateFormat.yMMMd().format(selectedDate!)
                        : "Pick Date",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                      applyFilters();
                    }
                  },
                  items:
                      categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Line Chart
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: _getMaxY(positiveSpots),
                lineBarsData: [
                  LineChartBarData(
                    spots: positiveSpots,
                    isCurved: true,
                    color: themeColor,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: themeColor.withOpacity(0.3),
                    ),
                    dotData: FlDotData(
                      show:
                          positiveSpots.isNotEmpty &&
                          positiveSpots.any((spot) => spot.y > 0),
                      checkToShowDot: (spot, _) => spot.y > 0,
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getInterval(selectedFilter),
                      getTitlesWidget: (value, meta) {
                        switch (selectedFilter) {
                          case 'Day':
                            return Text(
                              '${value.toInt()}h',
                              style: const TextStyle(fontSize: 12),
                            );
                          case 'Week':
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            final index = (value.toInt() - 1).clamp(0, 6);
                            return Text(
                              days[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          case 'Month':
                            if (value % 5 == 0 && value > 0) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 12),
                              );
                            }
                            return const SizedBox.shrink();
                          case 'Year':
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            final index = (value.toInt() - 1).clamp(0, 11);
                            return Text(
                              months[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          default:
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 12),
                            );
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _getYInterval(spots),
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(),
                    left: BorderSide(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Transaction History Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction History Heading
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Transaction History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction List
                Expanded(
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredExpenses.isEmpty
                          ? const Center(
                            child: Text(
                              "No transactions found.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final exp = filteredExpenses[index];
                              return _buildTransactionItem(
                                exp['category'] ?? "Other",
                                exp['date'],
                                (exp['amount'] as num).toDouble(),
                                redColor,
                                index,
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRandomColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[index % colors.length];
  }

  Widget _buildTransactionItem(
    String title,
    Timestamp timestamp,
    double amount,
    Color amountColor,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.shade100,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _getRandomColor(index),
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(timestamp.toDate()),
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          '${amount.toStringAsFixed(2)}',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
