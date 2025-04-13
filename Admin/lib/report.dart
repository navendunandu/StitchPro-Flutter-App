import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  List<Map<String, dynamic>> orderData = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  Future<void> generateAndDownloadPDF() async {
    final pdf = pw.Document();

    // Define custom styles
    final titleStyle = pw.TextStyle(
      fontSize: 28,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueAccent,
    );
    final subtitleStyle = pw.TextStyle(
      fontSize: 16,
      color: PdfColors.grey700,
    );
    final headerStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final contentStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.black,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Order Report', style: titleStyle),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${DateFormat('MMMM d, y').format(DateTime.now())}',
                      style: subtitleStyle,
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Revenue',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rs.${NumberFormat('#,##,###.##').format(calculateTotalAmount())}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'Period: ${DateFormat('MMMM d, y').format(startDate!)} - ${DateFormat('MMMM d, y').format(endDate!)}',
              style: subtitleStyle,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Date', 'User', 'Tailor', 'Amount'],
            headerStyle: headerStyle,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.blueAccent,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            headerHeight: 35,
            cellStyle: contentStyle,
            cellHeight: 40,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
            },
            cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              color: rowNum % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
            ),
            data: orderData.map((order) => [
              DateFormat('MMM d, y').format(DateTime.parse(order['created_at'])),
              order['tbl_user']['user_name'] ?? 'N/A',
              order['tbl_tailor']['tailor_name'] ?? 'N/A',
              'Rs.${NumberFormat('#,##,###.##').format(order['amount'] ?? 0)}',
            ]).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'Order_Report_${DateFormat('yyyy_MM_dd').format(startDate!)}_${DateFormat('yyyy_MM_dd').format(endDate!)}.pdf';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> fetchOrderData() async {
    if (startDate == null || endDate == null) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('tbl_booking')
          .select('*, tbl_user(user_name), tbl_tailor(tailor_name)')
          .gte('status', 3)
          .gte('created_at', startDate!.toIso8601String())
          .lte('created_at', endDate!.add(const Duration(days: 1)).toIso8601String())
          .order('created_at', ascending: false);

      setState(() {
        orderData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      fetchOrderData();
    }
  }

  double calculateTotalAmount() {
    return orderData.fold(0, (sum, order) => sum + (order['amount'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Order Reports',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          if (orderData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: generateAndDownloadPDF,
                icon: const Icon(Icons.download),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              startDate != null && endDate != null
                                  ? '${DateFormat('MMMM d, y').format(startDate!)} - ${DateFormat('MMMM d, y').format(endDate!)}'
                                  : 'No date range selected',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _selectDateRange(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Select Dates'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (orderData.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Card(
                          elevation: 0,
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Revenue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,###.##').format(calculateTotalAmount())}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orderData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                startDate == null
                                    ? 'Select a date range to view reports'
                                    : 'No orders found for selected date range',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          margin: const EdgeInsets.all(16),
                          elevation: 0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey[100],
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Date',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'User',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Tailor',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Amount',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              rows: orderData.map((order) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(DateFormat('MMM d, y').format(
                                        DateTime.parse(order['created_at'])))),
                                    DataCell(Text(
                                        order['tbl_user']['user_name'] ?? 'N/A')),
                                    DataCell(Text(
                                        order['tbl_tailor']['tailor_name'] ??
                                            'N/A')),
                                    DataCell(
                                      Text(
                                        '₹${NumberFormat('#,##,###.##').format(order['amount'] ?? 0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
