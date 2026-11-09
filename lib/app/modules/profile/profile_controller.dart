import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../auth/login_view.dart';

class ProfileController extends GetxController {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordBaruController = TextEditingController();

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNamaPanggilan();
  }

  void _loadNamaPanggilan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    namaController.text = prefs.getString('user_name') ?? '';
  }

  // === FUNGSI UPDATE PROFIL (SUDAH DINAMIS) ===
  void simpanProfil() async {
    // 1. Pastikan minimal ada SATU kolom yang diisi sebelum memanggil API
    if (namaController.text.isEmpty && 
        emailController.text.isEmpty && 
        passwordBaruController.text.isEmpty) {
      Get.snackbar(
        'Peringatan', 
        'Isi minimal satu data (Nama, Email, atau Password) yang ingin diubah!',
        backgroundColor: Colors.orange[100],
      );
      return;
    }

    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 2. Buat keranjang data kosong
      Map<String, String> bodyData = {};

      // 3. Isi keranjang HANYA dengan data yang diketik oleh user
      if (namaController.text.isNotEmpty) {
        bodyData['name'] = namaController.text;
      }
      if (emailController.text.isNotEmpty) {
        bodyData['email'] = emailController.text;
      }
      if (passwordBaruController.text.isNotEmpty) {
        bodyData['password'] = passwordBaruController.text;
      }

      // 4. Kirim data dinamis ke Laravel
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/update-profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyData,
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Jika nama ikut diubah, perbarui juga di memori HP agar langsung berubah di layar
        if (namaController.text.isNotEmpty) {
          await prefs.setString('user_name', namaController.text);
        }
        
        Get.snackbar('Berhasil', result['message'] ?? 'Profil diperbarui', backgroundColor: Colors.green[100]);
        
        // Kosongkan kolom password setelah berhasil
        passwordBaruController.clear(); 
      } else {
        // Tangkap pesan error dari Laravel jika email sudah dipakai orang lain
        final result = jsonDecode(response.body);
        Get.snackbar('Gagal', result['message'] ?? 'Gagal memperbarui profil', backgroundColor: Colors.red[100]);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Tidak dapat terhubung ke server', backgroundColor: Colors.red[100]);
    }
  }

  // === FUNGSI LOGOUT ===
  // === FUNGSI LOGOUT ===
  void logout() async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Tembak API Logout Laravel
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      // 1. Sapu bersih SEMUA memori penyimpanan lokal HP
      await prefs.clear();

      Get.back(); // Tutup loading dialog

      // 2. KODE SAKTI: Hapus semua cache memori Controller GetX yang nyangkut!
      Get.deleteAll(force: true); 

      // 3. Pindah ke halaman Login
      Get.offAll(() => LoginView()); 
      Get.snackbar('Sukses', 'Anda berhasil keluar', backgroundColor: Colors.green[100]);

    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal melakukan logout', backgroundColor: Colors.red[100]);
    }
  }

  @override
  void onClose() {
    namaController.dispose();
    emailController.dispose();
    passwordBaruController.dispose();
    super.onClose();
  }
}