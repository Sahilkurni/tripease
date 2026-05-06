import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentImplementation {
  late Razorpay _razorpay;
  late Function(String paymentId) _onSuccess;
  late Function(String error) _onError;

  void init({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onError = onError;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess(response.paymentId ?? "");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError(response.message ?? "Payment Failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onError("External Wallet selected: ${response.walletName}");
  }

  void openPayment(Map<String, dynamic> options) {
    try {
      _razorpay.open(options);
    } catch (e) {
      _onError(e.toString());
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
