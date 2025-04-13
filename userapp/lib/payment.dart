import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final int id;
  final int amt;
  const PaymentPage({super.key, required this.id, required this.amt});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  late SupabaseClient supabase;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final primaryColor = const Color(0xFF6A1B9A); // Deep purple
  final accentColor = const Color(0xFFE91E63); // Pink accent

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    supabase = Supabase.instance.client;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCheckout();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final paymentData = {
        'payment_rzid': response.paymentId,
        'payment_date': DateTime.now().toIso8601String(),
        'payment_amount': widget.amt,
        'booking_id': widget.id,
      };

      await supabase.from('tbl_payment').insert(paymentData);
      await supabase.from('tbl_booking').update({'status': 4}).eq('id', widget.id);

      Fluttertoast.showToast(
        msg: "Payment Successful: ${response.paymentId}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: primaryColor,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving payment: $e');
      Fluttertoast.showToast(
        msg: "Payment recorded but failed to save: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
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

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
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
    if (widget.amt <= 0) {
      Fluttertoast.showToast(
        msg: "Invalid amount: ${widget.amt}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pop(context);
      }
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
      contact = '1234567890';
      email = 'user@example.com';
    }

    var options = {
      'key': 'rzp_test_3Y3fSHEdiKurFd',
      'amount': widget.amt * 100,
      'name': 'Tailor App',
      'description': 'Payment for Booking #${widget.id}',
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
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(230, 255, 252, 197),
                  primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Payment Icon with Fixed Bounds
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: 80, // Fixed width
                      height: 80, // Fixed height
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primaryColor, accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Solid color text (no ShaderMask)
                  Text(
                    "Processing Payment",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(seconds: 1),
                    child: Text(
                      "Please wait while we process your payment.\nYou’ll be redirected shortly.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(
                                0.5 + 0.5 * (index / 3 + _controller.value),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Securing your transaction...",
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
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