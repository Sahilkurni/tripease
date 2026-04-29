import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class HotelOwnerDashboard extends StatelessWidget {
  const HotelOwnerDashboard({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.clearSession();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: const Center(child: Text('Hotel Owner features coming soon...')),
    );
  }
}
