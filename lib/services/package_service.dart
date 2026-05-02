import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';
import '../core/api_config.dart';

class PackageService {
  // Fetch packages for a specific agent
  Future<List<PackageModel>> getAgentPackages(int partnerId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.packages}?partnerid=$partnerId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => PackageModel.fromJson(e)).toList();
        }
      }
      throw Exception('Failed to load packages');
    } catch (e) {
      print('API Error (getAgentPackages): $e. Using mock data.');
      return [
        PackageModel(
          packageid: 1,
          partnerid: partnerId,
          categoryid: 1,
          packagename: 'Manali Snow Adventure',
          description: 'Experience the beautiful snow in Manali.',
          cityid: 3,
          days: 4,
          nights: 3,
          price: 12000.0,
          maxpersons: 2,
          isactive: 1,
          categoryName: 'Adventure',
          cityName: 'Manali',
          thumbnail: 'https://images.unsplash.com/photo-1605649487212-4d4ce38d14af?auto=format&fit=crop&q=80',
        ),
        PackageModel(
          packageid: 2,
          partnerid: partnerId,
          categoryid: 2,
          packagename: 'Goa Beach Holiday',
          description: 'Relax at the sunny beaches of Goa.',
          cityid: 4,
          days: 5,
          nights: 4,
          price: 15500.0,
          maxpersons: 4,
          isactive: 1,
          categoryName: 'Family',
          cityName: 'Goa',
          thumbnail: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&q=80',
        ),
      ];
    }
  }
}

final packageService = PackageService();
