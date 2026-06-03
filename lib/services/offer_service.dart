import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offer_model.dart';
import '../core/api_config.dart';

class OfferService {
  Future<List<OfferModel>> getOffers({
    required int userId,
    String? serviceType,
    int? serviceId,
    String? status,
    String roleView = 'customer',
  }) async {
    String url = '${ApiConfig.getOffers}?userid=$userId&role_view=$roleView';
    if (serviceType != null) url += '&service_type=$serviceType';
    if (serviceId != null) url += '&service_id=$serviceId';
    if (status != null) url += '&status=$status';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => OfferModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // print("Error fetching offers: $e");
      return [];
    }
  }

  Future<OfferModel?> getOfferDetails(int offerId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.offerDetails}?offerid=$offerId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return OfferModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      // print("Error fetching offer details: $e");
      return null;
    }
  }

  Future<bool> createOffer(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.createOffer), body: data);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error creating offer: $e");
      return false;
    }
  }

  Future<bool> updateOffer(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.updateOffer), body: data);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error updating offer: $e");
      return false;
    }
  }

  Future<bool> deleteOffer(int offerId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteOffer),
        body: {'offerid': offerId.toString(), 'userid': userId.toString()},
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error deleting offer: $e");
      return false;
    }
  }

  Future<bool> approveOffer(int offerId, int adminId, String status) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.approveOffer),
        body: {'offerid': offerId.toString(), 'userid': adminId.toString(), 'status': status},
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error approving offer: $e");
      return false;
    }
  }
}

final offerService = OfferService();
