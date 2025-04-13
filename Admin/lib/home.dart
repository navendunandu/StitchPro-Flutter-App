import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:project/main.dart';
import 'package:project/manage_attribute.dart';
import 'package:project/manage_category.dart';
import 'package:project/manage_clothtype.dart';
import 'package:project/manage_complaint.dart';
import 'package:project/manage_district.dart';
import 'package:project/manage_place.dart';
import 'package:project/manage_tailors.dart';
import 'package:project/profilepage.dart';
import 'package:project/report.dart';

class Tail extends StatefulWidget {
  const Tail({super.key});

  @override
  State<Tail> createState() => _TailState();
}

class _TailState extends State<Tail> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<FlSpot> yearlyEarnings = [];
  bool isLoadingGraph = true;
  double maxY = 0;

  @override
  void initState() {
    super.initState();
    _fetchYearlyEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Future<void> _fetchYearlyEarnings() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfYear = DateTime(now.year, 1, 1);

      final response = await supabase
          .from('tbl_booking')
          .select('amount, created_at')
          .gte('created_at', startOfYear.toIso8601String())
          .gte('status', 4); // Only completed or paid bookings

      Map<int, double> monthlyData = {};
      // Initialize all months with 0
      for (int i = 1; i <= 12; i++) {
        monthlyData[i] = 0;
      }

      // Process the response
      for (var booking in response) {
        DateTime bookingDate = DateTime.parse(booking['created_at']);
        int month = bookingDate.month; // 1-12
        double amount = (booking['amount'] as num?)?.toDouble() ?? 0.0;
        monthlyData[month] = (monthlyData[month] ?? 0.0) + amount;
      }

      // Convert to FlSpot list and find maxY
      List<FlSpot> spots = [];
      double maxAmount = 0;
      monthlyData.forEach((month, amount) {
        spots.add(FlSpot(month.toDouble() - 1, amount)); // Subtract 1 to match array index (0-11)
        if (amount > maxAmount) maxAmount = amount;
      });

      setState(() {
        yearlyEarnings = spots;
        maxY = maxAmount + (maxAmount * 0.1); // Add 10% padding to max value
        isLoadingGraph = false;
      });
    } catch (e) {
      print("Error fetching yearly earnings: $e");
      setState(() {
        isLoadingGraph = false;
      });
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Colors.blueGrey[900]),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.blueGrey[900],
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: Colors.black, size: 30),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Manage your application',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ...options.map((option) => ListTile(
                leading: Icon(option['icon'] as IconData, color: option['color'] as Color),
                title: Text(option['title'] as String),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => option['page'] as Widget),
                  );
                },
              )),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 30),
              _buildStatsSection(),
              const SizedBox(height: 30),
              _buildSalesGraph(), // New sales graph section
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waves_sharp, color: Colors.yellow[700], size: 30),
              const SizedBox(width: 10),
              const Text(
                'Welcome back, Admin!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Manage and monitor your tailoring application',
            style: TextStyle(color: Colors.grey[300], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder(
      future: Future.wait([
        _getActiveTailorsCount(),
        _getTotalOrdersCount(),
        _getNewComplaintsCount(),
        _getTotalRevenue(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tailorsCount = snapshot.data?[0] ?? 0;
        final ordersCount = snapshot.data?[1] ?? 0;
        final complaintsCount = snapshot.data?[2] ?? 0;
        final totalRevenue = snapshot.data?[3] ?? 0.0;

        return Row(
          children: [
            _buildStatCard('Active Tailors', tailorsCount.toString(), Icons.people, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard('Total Orders', ordersCount.toString(), Icons.shopping_bag, Colors.green),
            const SizedBox(width: 16),
            _buildStatCard('New Complaints', complaintsCount.toString(), Icons.warning, Colors.orange),
            const SizedBox(width: 16),
            _buildStatCard(
          'Total Revenue (${DateTime.now().year})',
          NumberFormat.currency(symbol: '₹').format(totalRevenue),
          Icons.monetization_on,
          Colors.purple,
        ),
          ],
        );
      },
    );
  }

  Future<int> _getActiveTailorsCount() async {
    try {
      final response = await supabase
          .from('tbl_tailor')
          .select('*')
          .eq('tailor_status', 1); // Status 1 for active/verified tailors

      return response.length;
    } catch (e) {
      print('Error fetching tailors count: $e');
      return 0;
    }
  }

  Future<int> _getTotalOrdersCount() async {
    try {
      final response = await supabase
          .from('tbl_booking')
          .select('*');

      return response.length;
    } catch (e) {
      print('Error fetching orders count: $e');
      return 0;
    }
  }

  Future<int> _getNewComplaintsCount() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select('*')
          .eq('complaint_status', 0); // Status 0 for new/unresolved complaints

      return response.length;
    } catch (e) {
      print('Error fetching complaints count: $e');
      return 0;
    }
  }

  Future<double> _getTotalRevenue() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfYear = DateTime(now.year, 1, 1);

      final response = await supabase
          .from('tbl_booking')
          .select('amount')
          .gte('created_at', startOfYear.toIso8601String())
          .gte('status', 4); // Only completed or paid bookings

      double totalRevenue = 0;
      for (var booking in response) {
        totalRevenue += (booking['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return totalRevenue;
    } catch (e) {
      print('Error fetching total revenue: $e');
      return 0;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesGraph() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Overview - ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoadingGraph
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: maxY / 5,
                        verticalInterval: 1,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameSize: 30, // Increase space for labels
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              final int index = value.toInt();
                              if (index >= 0 && index < months.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 5, // Spacing between label and chart
                                  child: Text(
                                    months[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxY / 5,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  NumberFormat.currency(
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(value),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      minX: 0,
                      maxX: 11,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: yearlyEarnings,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> options = [
  {
    'title': 'Manage District',
    'page': const ManageDistrict(),
    'color': Colors.blue,
    'icon': Icons.location_city
  },
  {
    'title': 'Manage Cloth Type',
    'page': const Manageclothtype(),
    'color': Colors.orange,
    'icon': Icons.shopping_bag
  },
  {
    'title': 'Manage Category',
    'page': const Managecategory(),
    'color': Colors.green,
    'icon': Icons.category
  },
  {
    'title': 'Manage Attribute',
    'page': const ManageAttribute(),
    'color': Colors.purple,
    'icon': Icons.settings
  },
  {
    'title': 'Manage Place',
    'page': const ManagePlace(),
    'color': Colors.teal,
    'icon': Icons.place
  },
  {
    'title': 'Manage Complaint',
    'page': const AdminComplaintsPage(),
    'color': Colors.red,
    'icon': Icons.report_problem
  },
  {
    'title': 'Manage Tailors',
    'page': const AdminTailors(),
    'color': Colors.indigo,
    'icon': Icons.people
  },
  {
    'title': 'Reports',
    'page': const Report(),
    'color': Colors.amber,
    'icon': Icons.assessment
  },
];
