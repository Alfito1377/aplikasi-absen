import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';

class HistoryController extends GetxController {
  var isLoading = false.obs;
  var listRiwayat = <dynamic>[].obs; 

  @override
  void onInit() {
    super.onInit();
    fetchHistory(); 
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      isLoading.value = false;
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        listRiwayat.value = result['data'];
      } else {
        Get.snackbar('Gagal', 'Gagal mengambil data riwayat', backgroundColor: Colors.red[100]);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Tidak dapat terhubung ke server', backgroundColor: Colors.red[100]);
    }
  }
}