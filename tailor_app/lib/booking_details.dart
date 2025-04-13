import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_app/main.dart';

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

  final primaryColor = const Color(0xFF6A1B9A); // Deep purple
  final accentColor = const Color(0xFFE91E63); // Pink accent
  final double fabricWidthMeters = 1.12; // 44 inches ≈ 1.12 meters

  bool isLoading = false;

  Future<void> fetchBooking() async {
    try {
      final booking = await supabase
          .from('tbl_booking')
          .select(
              "id, status, amount, tracking_id, tbl_dress(dress_id, dress_amount, dress_remark, tbl_material(material_amount, material_photo, material_colors, tbl_clothtype(clothtype_name)), tbl_measurement(*, tbl_attribute(attribute_name)), tbl_category(category_name))")
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

  String getStatus(int status) {
    switch (status) {
      case 1:
        return 'New Order';
      case 2:
        return 'Accepted';
      case 3:
        return 'Rejected';
      case 4:
        return 'Payment Completed';
      case 5:
        return 'Work Started';
      case 6:
        return 'Work Completed';
      case 7:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue; // New Order
      case 2:
        return Colors.green; // Accepted
      case 3:
        return Colors.red; // Rejected
      case 4:
        return Colors.purple; // Payment Completed
      case 5:
        return Colors.orange; // Work Started
      case 6:
        return Colors.teal; // Work Completed
      case 7:
        return Colors.greenAccent; // Delivered
      default:
        return Colors.grey; // Unknown
    }
  }

  void showChangeStatusDialog() {
    if (bookingData == null || bookingData!['status'] == null) return;

    int currentStatus = bookingData!['status'];
    List<int> allowedStatuses = [];

    // Define allowed next statuses based on current status
    switch (currentStatus) {
      case 2: // Accepted
        allowedStatuses = [5]; // Can move to Work Started
        break;
      case 4: // Payment Completed
        allowedStatuses = [5]; // Can move to Work Started
        break;
      case 5: // Work Started
        allowedStatuses = [6]; // Can move to Work Completed
        break;
      case 6: // Work Completed
        allowedStatuses = [7]; // Can move to Delivered
        break;
      default:
        return; // No status change allowed for other statuses
    }

    if (allowedStatuses.isEmpty) return;

    TextEditingController trackingIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Change Status",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current Status: ${getStatus(currentStatus)}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...allowedStatuses.map((status) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (status == 7 && trackingIdController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Please enter a tracking ID."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              await updateStatus(status, status == 7 ? trackingIdController.text : null);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getStatusColor(status),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              "Set to ${getStatus(status)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (status == 7) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: trackingIdController,
                              decoration: InputDecoration(
                                labelText: "Tracking ID",
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
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
          ],
        );
      },
    );
  }

  Future<void> updateStatus(int newStatus, String? trackingId) async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<String,dynamic> updateData = {'status': newStatus};
      if (newStatus == 7 && trackingId != null && trackingId.isNotEmpty) {
        updateData['tracking_id'] = trackingId; // Add tracking ID to update
      }

      await supabase
          .from('tbl_booking')
          .update(updateData).eq('id', widget.booking);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to ${getStatus(newStatus)}!"),
          backgroundColor: primaryColor,
        ),
      );

      await fetchBooking(); // Refresh data
    } catch (e) {
      print("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to update status."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showAcceptOrderDialog() {
    List<TextEditingController> serviceChargeControllers =
        dressData.map((dress) => TextEditingController(text: '0')).toList();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double calculateDialogTotal() {
              double total = 0.0;
              for (int i = 0; i < dressData.length; i++) {
                final dress = dressData[i];
                final materialCost = calculateDressMaterialCost(dress);
                final serviceCharge =
                    double.tryParse(serviceChargeControllers[i].text) ?? 0.0;
                total += materialCost + serviceCharge;
              }
              return total;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.all(0),
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, primaryColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Accept Order",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Enter service charges for each dress and select the estimated delivery date.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dressData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> dress = entry.value;
                        double materialCost = calculateDressMaterialCost(dress);
                        String category =
                            dress['tbl_category']['category_name'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$category",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Material Cost: ₹${materialCost.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          serviceChargeControllers[index],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Service Charge (₹)",
                                        labelStyle:
                                            TextStyle(color: primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        prefixIcon: Icon(Icons.currency_rupee,
                                            color: primaryColor),
                                      ),
                                      onChanged: (value) =>
                                          setDialogState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Text(
                        "Estimated Delivery Date",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: primaryColor,
                                  colorScheme:
                                      ColorScheme.light(primary: primaryColor),
                                  buttonTheme: const ButtonThemeData(
                                      textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(selectedDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Icon(Icons.calendar_today, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            "₹${calculateDialogTotal().toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style:
                                  TextStyle(color: accentColor, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await acceptOrder(
                                  serviceChargeControllers, selectedDate);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> acceptOrder(List<TextEditingController> serviceChargeControllers,
      DateTime? selectedDate) async {
    try {
      setState(() {
        isLoading = true;
      });

      double totalBookingCost = 0.0;

      for (int i = 0; i < dressData.length; i++) {
        final dress = dressData[i];
        final materialCost = calculateDressMaterialCost(dress);
        final serviceCharge =
            double.tryParse(serviceChargeControllers[i].text) ?? 0.0;
        final totalDressCost = materialCost + serviceCharge;

        await supabase.from('tbl_dress').update({
          'dress_amount': totalDressCost,
          'dress_status': 2, // Accepted
        }).eq('dress_id', dress['dress_id']);

        totalBookingCost += totalDressCost;
      }

      await supabase.from('tbl_booking').update({
        'amount': totalBookingCost,
        'status': 2, // Accepted
        'booking_fordate': selectedDate?.toIso8601String(),
      }).eq('id', bookingId);

      Navigator.pop(context); // Close dialog
      await fetchBooking(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Order accepted successfully!"),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print("Error accepting order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to accept order."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> rejectOrder() async {
    try {
      await supabase.from('tbl_booking').update({
        'status': 3, // Rejected
      }).eq('id', widget.booking);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Order rejected successfully!"),
          backgroundColor: Colors.red,
        ),
      );
      await fetchBooking(); // Refresh data
    } catch (e) {
      print("Error rejecting order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to reject order."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBooking();
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Status
                  if (bookingData != null && bookingData!['status'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(bookingData!['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: getStatusColor(bookingData!['status']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Status: ${getStatus(bookingData!['status'])}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(bookingData!['status']),
                        ),
                      ),
                    ),
                  // Display Tracking ID
                  if (bookingData != null &&
                      bookingData!['status'] == 7 &&
                      bookingData!['tracking_id'] != null &&
                      bookingData!['tracking_id'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "Tracking ID: ${bookingData!['tracking_id']}",
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Change Status Button
                  if (bookingData != null &&
                      (bookingData!['status'] == 2 ||
                          bookingData!['status'] == 4 ||
                          bookingData!['status'] == 5 ||
                          bookingData!['status'] == 6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : showChangeStatusDialog,
                        icon: const Icon(
                          Icons.update,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Change Status",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
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
                            final colors =
                                (material['material_colors'] as List?)
                                        ?.map((c) => c as Map<String, dynamic>)
                                        .toList() ??
                                    [];
                            String category =
                                dress['tbl_category']['category_name'];
                            String remark =
                                dress['dress_remark'] ?? "No remarks";
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: material['material_photo'] !=
                                                  null
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
                                                    child: const Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image,
                                                      size: 40,
                                                      color: Colors.grey),
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
                                                "Required Fabric Length: ${fabricLength.toStringAsFixed(1)} meters",
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
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _hexToColor(
                                                                color['hex']),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color:
                                                                    Colors.grey,
                                                                width: 0.5),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          color['name'],
                                                          style:
                                                              const TextStyle(
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: measurements.length,
                                      itemBuilder: (context, mIndex) {
                                        final measurement =
                                            measurements[mIndex];
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
                    if (bookingData != null && bookingData!['status'] == 1)
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : showAcceptOrderDialog,
                                label: const Text(
                                  "Accept Order",
                                  style: TextStyle(color: Colors.white),
                                ),
                                icon: const Icon(Icons.check,
                                    color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        rejectOrder();
                                      },
                                label: const Text(
                                  "Reject Order",
                                  style: TextStyle(color: Colors.white),
                                ),
                                icon: const Icon(Icons.dangerous_outlined,
                                    color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}