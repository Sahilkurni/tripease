import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/hotel_card.dart';

class HotelListScreen extends StatelessWidget {
  const HotelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ]
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => context.push('/hotel_detail'),
            child: HotelCard(
              name: 'Grand Hyatt Beach Resort',
              city: 'Goa, India',
              rating: 4.8,
              price: 120.0 + (index * 20),
              imageUrl: 'https://picsum.photos/seed/hotel$index/800/600',
            ),
          );
        },
      ),
    );
  }
}
