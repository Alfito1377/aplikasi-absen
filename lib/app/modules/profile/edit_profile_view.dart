import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class EditProfileView extends StatelessWidget {
  EditProfileView({Key? key}) : super(key: key);

  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LOGO APLIKASI
            Center(
              child: Image.asset(
                'assets/logo.png', // Pastikan nama file gambarmu sesuai
                height: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 100, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 30),

            // Form Lengkap
            const Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: controller.namaController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            const Text('Keamanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: controller.passwordBaruController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Baru (Kosongkan jika tidak diubah)',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Simpan
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.simpanProfil(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )),
            
            const SizedBox(height: 20),

            // Tombol Logout
            OutlinedButton.icon(
              onPressed: () {
                // Konfirmasi sebelum keluar
                Get.defaultDialog(
                  title: 'Konfirmasi',
                  middleText: 'Apakah Anda yakin ingin keluar dari aplikasi?',
                  textConfirm: 'Ya, Keluar',
                  textCancel: 'Batal',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  cancelTextColor: Colors.black,
                  onConfirm: () {
                    Get.back(); // Tutup dialog
                    controller.logout(); // Jalankan fungsi logout
                  },
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('KELUAR (LOGOUT)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}