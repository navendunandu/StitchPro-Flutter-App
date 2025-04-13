import 'package:flutter/material.dart';
import 'package:tailor_app/login.dart';
import 'package:tailor_app/main.dart';
import 'package:tailor_app/mybookings.dart';
import 'package:tailor_app/mymaterial.dart';
import 'package:tailor_app/profilepage.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this package for charts
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final primaryColor = Color(0xFF6A1B9A); // Deep purple for fashion theme
  final accentColor = Color(0xFFE91E63); // Pink accent

  // Data structures
  Map<String, dynamic> dashboardStats = {};
  Map<String, dynamic> tailorProfile = {};
  List<FlSpot> weeklyEarnings = [];
  List<Map<String, dynamic>> recentOrders = [];
  double maxValue = 500;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _fetchTailorProfile(),
        _fetchDashboardStats(),
        _fetchWeeklyEarnings(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTailorProfile() async {
    try {
      final user = await supabase
          .from('tbl_tailor')
          .select()
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .single();
      final orders = await supabase
          .from('tbl_booking')
          .count()
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .eq('status', 7);
      final ratingData = await supabase
          .from('tbl_rating')
          .select()
          .eq('tailor_id', supabase.auth.currentUser!.id);
      double rating = 0;
      for (var data in ratingData) {
        rating = rating + (data['rating_count'] as num).toDouble();
      }
      double avgRating = ratingData.isNotEmpty ? rating / ratingData.length : 0.0;
      setState(() {
        tailorProfile = {
          'name': user['tailor_name'],
          'rating': avgRating,
          'completedOrders': orders,
          'profileImage': user['tailor_photo'],
        };
      });
    } catch (e) {
      print("Error fetching tailor profile: $e");
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final newOrders = await supabase
          .from('tbl_booking')
          .count()
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .eq('status', 1);
      final ongoingOrders = await supabase
          .from('tbl_booking')
          .count()
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .gte('status', 4)
          .lt('status', 7);
      final completedOrders = await supabase
          .from('tbl_booking')
          .count()
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .eq('status', 7);
      final totalEarnings = await supabase
          .from('tbl_booking')
          .select('amount')
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .gte('status', 4);
      final pendingPayments = await supabase
          .from('tbl_booking')
          .select('amount')
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .lt('status', 4);
      final material = await supabase
          .from('tbl_material')
          .count()
          .eq('tailor_id', supabase.auth.currentUser!.id);
      int totalAmount = 0;
      int pendingAmount = 0;
      for (var data in pendingPayments) {
        int amount = (data['amount'] as num?)?.toInt() ?? 0;
        pendingAmount += amount;
      }
      for (var data in totalEarnings) {
        int amount = (data['amount'] as num?)?.toInt() ?? 0;
        totalAmount += amount;
      }
      int starting = 500;
      while(starting<totalAmount){
        starting = starting+500;
      }
      setState(() {
        dashboardStats['newOrders'] = newOrders;
        dashboardStats['ongoingOrders'] = ongoingOrders;
        dashboardStats['completedOrders'] = completedOrders;
        dashboardStats['totalEarnings'] = totalAmount;
        dashboardStats['pendingPayments'] = pendingAmount;
        dashboardStats['materialsCount'] = material;
        maxValue = starting.toDouble();
      });
    } catch (e) {
      print("Error fetching dashboard stats: $e");
    }
  }

  Future<void> _fetchWeeklyEarnings() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final response = await supabase
          .from('tbl_booking')
          .select('amount, created_at')
          .eq('tailor_id', supabase.auth.currentUser!.id)
          .gte('created_at', startOfWeek.toIso8601String())
          .gte('status', 4); // Only completed or paid bookings

      Map<int, double> weeklyData = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      for (var booking in response) {
        DateTime bookingDate = DateTime.parse(booking['created_at']);
        int dayOfWeek = bookingDate.weekday - 1; // 0 = Monday, 6 = Sunday
        if (dayOfWeek >= 0 && dayOfWeek < 7) {
          double amount = (booking['amount'] as num?)?.toDouble() ?? 0.0;
          weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0.0) + amount;
        }
      }

      setState(() {
        weeklyEarnings = [
          FlSpot(0, weeklyData[0]!),
          FlSpot(1, weeklyData[1]!),
          FlSpot(2, weeklyData[2]!),
          FlSpot(3, weeklyData[3]!),
          FlSpot(4, weeklyData[4]!),
          FlSpot(5, weeklyData[5]!),
          FlSpot(6, weeklyData[6]!),
        ];
      });
    } catch (e) {
      print("Error fetching weekly earnings: $e");
    }
  }

  String formatDate(String? date) {
    if (date == null) return "Not Given";
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate); // e.g., "Oct 25, 2023"
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            _buildAppBar(),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),

                    // Tailor Profile Card
                    _buildProfileCard(),

                    SizedBox(height: 24),

                    // Quick Stats Cards
                    _buildQuickStats(),

                    SizedBox(height: 24),

                    // Weekly Earnings Chart
                    _buildWeeklyEarningsChart(),

                    SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: Text(
        "StitchPro Tailor Dashboard",
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: primaryColor),
          onPressed: () async {
            bool confirm = await _showLogoutConfirmationDialog();
            if (confirm) {
              await supabase.auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: tailorProfile['profileImage'] != null
                        ? DecorationImage(
                            image: NetworkImage(tailorProfile['profileImage']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: tailorProfile['profileImage'] == null
                      ? Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16),
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tailorProfile['name'] ?? 'Unknown Tailor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildProfileStat(
                              Icons.star, "${tailorProfile['rating']}"),
                          SizedBox(width: 16),
                          _buildProfileStat(Icons.check_circle,
                              "${tailorProfile['completedOrders']} orders"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Stats",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              "New Orders",
              "${dashboardStats['newOrders'] ?? 0}",
              Icons.shopping_bag_outlined,
              accentColor,
            ),
            SizedBox(width: 6),
            _buildStatCard(
              "Ongoing",
              "${dashboardStats['ongoingOrders'] ?? 0}",
              Icons.access_time,
              Colors.orange,
            ),
            SizedBox(width: 6),
            _buildStatCard(
              "Completed",
              "${dashboardStats['completedOrders'] ?? 0}",
              Icons.check_circle_outline,
              Colors.green,
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              "Earnings",
              "₹${NumberFormat('#,###').format(dashboardStats['totalEarnings'] ?? 0)}",
              Icons.account_balance_wallet_outlined,
              Colors.blue,
              isWide: true,
            ),
            SizedBox(width: 12),
            _buildStatCard(
              "Pending",
              "₹${NumberFormat('#,###').format(dashboardStats['pendingPayments'] ?? 0)}",
              Icons.payment_outlined,
              Colors.red,
              isWide: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool isWide = false}) {
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: isWide ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyEarningsChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Earnings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "This Week",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value >= 0 && value < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxValue,
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyEarnings,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accentColor.withOpacity(0.2),
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

 

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 5,
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, "Home", true),
            _buildBottomNavItem(Icons.shopping_bag_outlined, "Orders", false),
            _buildBottomNavItem(
                Icons.design_services_outlined, "Materials", false),
            _buildBottomNavItem(Icons.person_outline, "Profile", false),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (label == "Orders") {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => MyBooking()));
        } else if (label == "Profile") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ProfileScreen()));
        } else if (label == "Materials") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MyMaterialPage()));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text("Logout"),
              content: Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Logout"),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
