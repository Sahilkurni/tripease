import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return authService;
});

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => authService.currentUser;

  void setUser(UserModel? user) {
    state = user;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel?>(() => UserNotifier());

class AuthController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool> login(String credentials, String password) async {
    state = true;
    try {
      final service = ref.read(authServiceProvider);
      final result = await service.login(credentials, password);
      
      if (result['success'] == true) {
        ref.read(userProvider.notifier).setUser(result['user']);
        state = false;
        return true;
      }
      state = false;
      return false;
    } catch (e) {
      state = false;
      return false;
    }
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.clearSession();
    ref.read(userProvider.notifier).setUser(null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, bool>(() => AuthController());
