import 'package:flutter/material.dart';
import 'package:userapp/booking_details.dart';
import 'package:userapp/booktailor.dart';
import 'package:userapp/main.dart';
import 'package:intl/intl.dart'; // For date formatting

class UserProfileBookingPage extends StatefulWidget {
  const UserProfileBookingPage({super.key});

  @override
  _UserProfileBookingPageState createState() => _UserProfileBookingPageState();
}

class _UserProfileBookingPageState extends State<UserProfileBookingPage> {
  List<Map<String, dynamic>> bookings = [];

  final primaryColor = const Color(0xFF6A1B9A); // Deep purple
  final accentColor = const Color(0xFFE91E63); // Pink accent

  Future<void> fetchBooking() async {
    try {
      final response = await supabase
          .from("tbl_booking")
          .select("*,tbl_dress(*),tbl_tailor(tailor_name)")
          .eq("user_id", supabase.auth.currentUser!.id);
      setState(() {
        bookings = response;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBooking();
  }

  String getStatus(int status) {
    switch (status) {
      case 0:
        return 'Incomplete';
      case 1:
        return 'Pending';
      case 2:
        return 'Accepted';
      case 3:
        return 'Rejected';
      case 4:
        return 'Payment Completed';
      case 5:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.redAccent;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.greenAccent;
      default:
        return Colors.grey;
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Booking History"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bookings.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Bookings Yet",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your booking history will appear here once you place an order.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final status = booking['status'] as int;
                        final tailorName = booking['tbl_tailor']['tailor_name'];
                        final itemCount = (booking['tbl_dress'] as List).length;
                        final createdAt = formatDate(booking['created_at']);
                        final amount = booking['amount']?.toString() ?? "Not Given";
                        final deliveryDate =
                            formatDate(booking['booking_fordate']);

                        return GestureDetector(
                          onTap: () {
                            if(booking['status']==0){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookTailor(id: booking['id'].toString(), booking: true,),));
                              
                            }
                            else{
                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetails(booking: booking['id']),));

                            }
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tailorName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(status)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: getStatusColor(status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          getStatus(status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Items: $itemCount",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Order Date: $createdAt",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Amount: ₹$amount",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Est. Delivery: $deliveryDate",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}