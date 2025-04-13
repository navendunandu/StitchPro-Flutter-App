import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:userapp/main.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BookingDetails extends StatefulWidget {
  final int booking;
  const BookingDetails({super.key, required this.booking});

  @override
  State<BookingDetails> createState() => _BookingDetailsState();
}

class _BookingDetailsState extends State<BookingDetails> {
  Map<String, dynamic>? bookingData;
  List<Map<String, dynamic>> dressData = [];
  int bookingId = 0;

  late Razorpay _razorpay;
  final primaryColor = const Color(0xFF6A1B9A); // Deep purple
  final accentColor = const Color(0xFFE91E63); // Pink accent
  final double fabricWidthMeters = 1.12; // 44 inches ≈ 1.12 meters

  bool isLoading = false; // For button loader
  bool isPaymentProcessing = false; // To track payment state

  Future<void> fetchBooking() async {
    try {
      final booking = await supabase
          .from('tbl_booking')
          .select(
              "*, tbl_dress(dress_id, dress_amount, dress_remark, tbl_material(material_amount, material_photo, material_colors, tbl_clothtype(clothtype_name)), tbl_measurement(*, tbl_attribute(attribute_name)), tbl_category(category_name))")
          .eq('id', widget.booking)
          .maybeSingle()
          .limit(1);  
      if (booking != null) {
        setState(() {
          bookingId = booking['id'];
          bookingData = booking;
          dressData = (booking['tbl_dress'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
        });
      } else {
        print("No booking found.");
        setState(() {
          dressData = [];
          bookingData = null;
        });
      }
    } catch (e) {
      print("Error fetching booking: $e");
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  double calculateFabricLength(List<dynamic> measurements) {
    const double cmToMeters = 0.01;
    if (measurements.isEmpty) return 0.0;
    final maxMeasurement = measurements
        .map((m) => (m['measurement_value'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    double lengthMeters = maxMeasurement * cmToMeters;
    return (lengthMeters / 0.5).ceil() * 0.5; // Round to nearest 0.5 meter
  }

  double calculateDressMaterialCost(Map<String, dynamic> dress) {
    final measurements = dress['tbl_measurement'] as List<dynamic>;
    final materialCostPerMeter =
        (dress['tbl_material']['material_amount'] as num).toDouble();
    final fabricLength = calculateFabricLength(measurements);
    return materialCostPerMeter * fabricLength;
  }

  double getDressCost(Map<String, dynamic> dress) {
    return dress['dress_amount'] != null
        ? (dress['dress_amount'] as num).toDouble()
        : calculateDressMaterialCost(dress);
  }

  double calculateTotalCost() {
    if (bookingData != null && bookingData!['amount'] != null) {
      return (bookingData!['amount'] as num).toDouble();
    }
    return dressData.fold(
      0.0,
      (sum, dress) => sum + calculateDressMaterialCost(dress),
    );
  }

  String getStatusText(int status) {
    switch (status) {
      case 0:
        return "Incomplete";
      case 1:
        return "Pending";
      case 2:
        return "Accepted";
      case 3:
        return "Rejected";
      case 4:
        return "Payment Completed";
      case 5:
        return 'Work Started';
      case 6:
        return 'Work Completed';
      case 7:
        return 'Delivered';
      default:
        return "Unknown";
    }
  }

  String getStatusMessage(int status) {
    switch (status) {
      case 0:
        return "Your booking is incomplete. Please contact support if you need assistance.";
      case 1:
        return "Your booking is pending approval. We will notify you once it’s accepted.";
      case 2:
        return "Your booking has been accepted. Please proceed with payment.";
      case 3:
        return "Your booking has been rejected. Contact us for more details.";
      case 4:
        return "Payment completed successfully! Your order is being processed.";
      case 5:
        return "Your order has been delivered. Thank you for choosing us!";
      default:
        return "No additional information available.";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBooking();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      isPaymentProcessing = false;
    });
    try {
      final paymentData = {
        'payment_rzid': response.paymentId,
        'payment_date': DateTime.now().toIso8601String(),
        'payment_amount': calculateTotalCost(),
        'booking_id':
            widget.booking, // Add booking_id to link payment to booking
      };

      await supabase.from('tbl_payment').insert(paymentData);
      await supabase
          .from('tbl_booking')
          .update({'status': 4}).eq('id', widget.booking);

      Fluttertoast.showToast(
        msg: "Payment Successful: ${response.paymentId}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: primaryColor,
        textColor: Colors.white,
      );

      // Refresh booking data after payment
      await fetchBooking();
    } catch (e) {
      print('Error saving payment: $e');
      Fluttertoast.showToast(
        msg: "Payment recorded but failed to save: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isPaymentProcessing = false;
    });
    String message = response.message ?? 'Unknown error';
    print('Payment error: ${response.code} - $message');

    if (response.code == 1) {
      message = "Payment cancelled by user";
    }

    Fluttertoast.showToast(
      msg: "Payment Failed: $message",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isPaymentProcessing = false;
    });
    print('External wallet: ${response.walletName}');
    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: primaryColor,
      textColor: Colors.white,
    );
  }

  Future<void> openCheckout() async {
    if (isPaymentProcessing) return; // Prevent multiple clicks

    setState(() {
      isPaymentProcessing = true;
    });

    if (bookingData == null || bookingData!['amount'] == null) {
      Fluttertoast.showToast(
        msg: "No amount available to pay.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        isPaymentProcessing = false;
      });
      return;
    }

    String? contact;
    String? email;

    try {
      final user = await supabase
          .from('tbl_user')
          .select('user_contact, user_email')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      contact = user['user_contact']?.toString();
      email = user['user_email']?.toString();
    } catch (e) {
      print('Error fetching user data: $e');
      contact = '1234567890'; // Fallback
      email = 'user@example.com'; // Fallback
    }

    var options = {
      'key': 'rzp_test_565dkZaITtTfYu',
      'amount':
          (calculateTotalCost() * 100).toInt(), // Use calculated total in paise
      'name': 'Tailor App',
      'description': 'Payment for Booking #${widget.booking}',
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
      Fluttertoast.showToast(
        msg: "Error initiating payment: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        isPaymentProcessing = false;
      });
    }
  }

  void showTrackingIdDialog() {
    if (bookingData == null ||
        bookingData!['tracking_id'] == null ||
        bookingData!['tracking_id'].isEmpty) {
      Fluttertoast.showToast(
        msg: "No tracking ID available.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Tracking Details",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tracking ID: ${bookingData!['tracking_id']}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Use this ID to track your delivery with the courier service.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: accentColor, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void showComplaintDialog() {
    TextEditingController complaintController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Raise a Complaint",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: complaintController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Describe your complaint",
                  labelStyle: TextStyle(color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: accentColor, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (complaintController.text.isNotEmpty) {
                  try {
                    await supabase.from('tbl_complaint').insert({
                      'tailor_id': bookingData!['tailor_id'],
                      'complaint_text': complaintController.text,
                      'user_id': supabase.auth.currentUser!.id,
                    });
                    Fluttertoast.showToast(
                      msg: "Complaint submitted successfully!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: primaryColor,
                      textColor: Colors.white,
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "Failed to submit complaint: $e",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter a complaint.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void showRatingDialog() {
  double rating = 0.0;
  TextEditingController feedbackController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Rate Your Experience",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: index < rating ? Colors.amber : Colors.grey,
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                    );
                  }),
                ),
                
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Add Feedback (Optional)",
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: accentColor, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (rating > 0) {
                try {
                  await supabase.from('tbl_rating').insert({
                    'tailor_id': bookingData!['tailor_id'],
                    'rating_count': rating,
                    'rating_content': feedbackController.text,
                  });
                  Fluttertoast.showToast(
                    msg: "Rating submitted successfully!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: primaryColor,
                    textColor: Colors.white,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: "Failed to submit rating: $e",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              } else {
                Fluttertoast.showToast(
                  msg: "Please provide a rating.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Submit"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookingData != null) ...[
                Text(
                  "Status: ${getStatusText(bookingData!['status'])}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getStatusMessage(bookingData!['status']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (bookingData!['status'] == 7 &&
                    bookingData!['tracking_id'] != null &&
                    bookingData!['tracking_id'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: showTrackingIdDialog,
                      icon:
                          const Icon(Icons.local_shipping, color: Colors.white),
                      label: const Text(
                        "View Tracking ID",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              dressData.isEmpty
                  ? Center(
                      child: Text(
                        "No dresses booked yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dressData.length,
                      itemBuilder: (context, index) {
                        final dress = dressData[index];
                        final measurements =
                            dress['tbl_measurement'] as List<dynamic>;
                        final material = dress['tbl_material'];
                        final colors = (material['material_colors'] as List?)
                                ?.map((c) => c as Map<String, dynamic>)
                                .toList() ??
                            [];
                        String category =
                            dress['tbl_category']['category_name'];
                        String remark = dress['dress_remark'] ?? "No remarks";
                        double fabricLength =
                            calculateFabricLength(measurements);
                        double cost = getDressCost(dress);

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            remark,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: material['material_photo'] != null
                                          ? Image.network(
                                              material['material_photo'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image,
                                                    size: 40,
                                                    color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image,
                                                  size: 40, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            material['tbl_clothtype']
                                                ['clothtype_name'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Cost: ₹${cost.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: accentColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Fabric Length: ${fabricLength.toStringAsFixed(1)} meters",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          if (colors.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: colors.map((color) {
                                                return Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: _hexToColor(
                                                            color['hex']),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: Colors.grey,
                                                            width: 0.5),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      color['name'],
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Measurements",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: measurements.length,
                                  itemBuilder: (context, mIndex) {
                                    final measurement = measurements[mIndex];
                                    String measurementName =
                                        measurement['tbl_attribute']
                                            ['attribute_name'];
                                    double measurementValue =
                                        measurement['measurement_value']
                                            .toDouble();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            measurementName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            "$measurementValue cm",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              if (dressData.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Cost",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          "₹${calculateTotalCost().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bookingData != null && bookingData!['status'] >= 2
                      ? "Includes material and service costs."
                      : "Note: This is only the material cost; service cost will be added later.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (bookingData != null && bookingData!['status'] == 2) ...[
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: isPaymentProcessing ? null : openCheckout,
                        label: isPaymentProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Pay Now",
                                style: TextStyle(color: Colors.white),
                              ),
                        icon: isPaymentProcessing
                            ? const SizedBox.shrink()
                            : const Icon(
                                Icons.payment_rounded,
                                color: Colors.white,
                              ),
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 50),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: showComplaintDialog,
                      icon:
                          const Icon(Icons.report_problem, color: Colors.white),
                      label: const Text(
                        "Raise Complaint",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (bookingData != null && bookingData!['status'] == 7)
                      ElevatedButton.icon(
                        onPressed: showRatingDialog,
                        icon: const Icon(Icons.star, color: Colors.white),
                        label: const Text(
                          "Rate Order",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
