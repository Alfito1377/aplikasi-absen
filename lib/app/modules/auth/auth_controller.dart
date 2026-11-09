import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart'; 
import '../home/home_view.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nomorPegawaiController = TextEditingController();
  final namaController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();

  var isLoading = false.obs;

 // === FUNGSI AKTIVASI AKUN (SEBELUMNYA REGISTER) ===
  void register() async {
    // 1. Nama tidak perlu lagi dicek karena sudah diurus Admin
    if (nomorPegawaiController.text.isEmpty || 
        registerEmailController.text.isEmpty || 
        registerPasswordController.text.isEmpty) {
      Get.snackbar('Peringatan', 'Semua kolom wajib diisi!', backgroundColor: Colors.red[100]);
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: {'Accept': 'application/json'},
        body: {
          'nomor_pegawai': nomorPegawaiController.text,
          // 'name': namaController.text, <-- HAPUS ATAU BERI KOMENTAR BARIS INI
          'email': registerEmailController.text,
          'password': registerPasswordController.text,
        },
      );

      isLoading.value = false;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Sukses', data['message'] ?? 'Aktivasi Berhasil! Silakan Login.', backgroundColor: Colors.green[100]);
        _clearRegisterForm();
        await Future.delayed(const Duration(seconds: 2));
        Get.back(); // Kembali ke halaman login
      } else {
        Get.snackbar('Gagal', data['message'] ?? 'Terjadi kesalahan validasi', backgroundColor: Colors.orange[100]);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Tidak dapat terhubung ke server', backgroundColor: Colors.red[100]);
    }
  }

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Peringatan', 'Email dan Password tidak boleh kosong!', backgroundColor: Colors.red[100]);
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      isLoading.value = false;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Ambil token dan nama dari respons Laravel
        String token = data['token'];
        String userName = data['data']['name'];

        // Simpan token dan NAMA ke memori HP (Ini sudah benar!)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_name', userName);

        emailController.clear();
        passwordController.clear();

        Get.snackbar('Sukses', 'Berhasil Login', backgroundColor: Colors.green[100]);
        await Future.delayed(const Duration(milliseconds: 500));
        
        Get.offAll(() => HomeView());
      } else {
        Get.snackbar('Gagal', data['message'] ?? 'Email atau Password salah', backgroundColor: Colors.red[100]);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Tidak dapat terhubung ke server', backgroundColor: Colors.red[100]);
    }
  }

  void _clearRegisterForm() {
    nomorPegawaiController.clear();
    namaController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
  }

  @override
  void onClose() {
    emailController.dispose(); passwordController.dispose();
    nomorPegawaiController.dispose(); namaController.dispose();
    registerEmailController.dispose(); registerPasswordController.dispose();
    super.onClose();
  }
}