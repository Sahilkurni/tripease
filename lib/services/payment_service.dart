import 'package:flutter/foundation.dart';
import 'payment_implementation_mobile.dart'
    if (dart.library.js) 'payment_implementation_web.dart';

class PaymentService {
  final PaymentImplementation _impl = PaymentImplementation();

  void init({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    _impl.init(onSuccess: onSuccess, onError: onError);
  }

  void openPayment({
    required double amount,
    required String name,
    required String description,
    String? email,
    String? contact,
  }) {
    var options = {
      'key': 'rzp_test_Sm8iA4dKloK2f9',
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact ?? '9999999999',
        'email': email ?? 'test@tripease.com',
      },
    };

    _impl.openPayment(options);
  }

  void dispose() {
    _impl.dispose();
  }
}

final paymentService = PaymentService();
