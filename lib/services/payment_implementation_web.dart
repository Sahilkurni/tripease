import 'dart:js' as js;

class PaymentImplementation {
  late Function(String paymentId) _onSuccess;
  late Function(String error) _onError;

  void init({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
  }

  void openPayment(Map<String, dynamic> options) {
    // Add success/error callbacks for Web
    options['handler'] = js.allowInterop((dynamic response) {
      if (response != null && response['razorpay_payment_id'] != null) {
        _onSuccess(response['razorpay_payment_id']);
      } else {
        _onError("Payment response missing ID");
      }
    });

    options['modal'] = {
      'ondismiss': js.allowInterop(([dynamic _]) {
        _onError("Payment cancelled by user");
      }),
    };

    try {
      final rzp = js.context.callMethod('Razorpay', [js.JsObject.jsify(options)]);
      rzp.callMethod('open');
    } catch (e) {
      _onError("Web Payment Error: $e");
    }
  }

  void dispose() {
    // No cleanup needed for Web JS
  }
}
