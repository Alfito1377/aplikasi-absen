import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../history/history_view.dart'; 
import '../profile/edit_profile_view.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeView extends StatelessWidget {
  HomeView({Key? key}) : super(key: key);

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    // Mengambil tinggi layar HP untuk penyesuaian dinamis
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard Presensi', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.to(() => EditProfileView()),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Mengurangi padding atas/bawah agar lebih lega
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. BAGIAN HEADER (SAPAAN & JAM)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Obx(() => Text(
                          'Halo,\n${controller.userName.value}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Obx(() => Text(
                            controller.currentTime.value,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          )),
                      const Text('Waktu Server', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // 2. PANEL STATUS LOKASI GPS (Lebih ramping)
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: controller.isMencariLokasi.value
                          ? Colors.grey[100]
                          : (controller.dalamRadius.value ? Colors.green[50] : Colors.red[50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.isMencariLokasi.value
                            ? Colors.grey
                            : (controller.dalamRadius.value ? Colors.green : Colors.red),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: controller.dalamRadius.value ? Colors.green : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.statusLokasi.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: controller.dalamRadius.value ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                              if (!controller.isMencariLokasi.value)
                                Text(
                                  "${controller.latitude.value.toStringAsFixed(5)}, ${controller.longitude.value.toStringAsFixed(5)}",
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                            ],
                          ),
                        ),
                        // Tombol refresh kecil dipindah ke dalam box status
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                          onPressed: () => controller.refreshLokasi(),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        )
                      ],
                    ),
                  )),
                  
              const SizedBox(height: 16),

              // 3. === WIDGET PETA REAL-TIME (Dibuat sedikit lebih ceper) ===
              Obx(() {
                if (controller.latitude.value == 0.0) {
                  return Container(
                    height: screenHeight * 0.22, // Dinamis: 22% dari tinggi layar
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                return Container(
                  height: screenHeight * 0.22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(controller.latitude.value, controller.longitude.value),
                        initialZoom: 17.5, // Zoom sedikit lebih dekat karena kotak lebih pendek
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.presensiapp.ujikom',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(controller.officeLat, controller.officeLng),
                              color: Colors.blue.withOpacity(0.15),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: controller.batasRadiusMeter,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(controller.officeLat, controller.officeLng),
                              width: 35, height: 35,
                              child: const Icon(Icons.business, color: Colors.blue, size: 30),
                            ),
                            Marker(
                              point: LatLng(controller.latitude.value, controller.longitude.value),
                              width: 35, height: 35,
                              child: Icon(
                                Icons.person_pin_circle, 
                                color: controller.dalamRadius.value ? Colors.green : Colors.red, 
                                size: 35
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // =======================================

              const SizedBox(height: 20),

              // 4. BAGIAN BAWAH (FOTO DI KIRI, TOMBOL DI KANAN)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Pratinjau Foto (Kecil di sebelah kiri)
                  Obx(() => Container(
                        height: 110, 
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
                        ),
                        child: controller.imagePath.value.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 30, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text("Selfie", style: TextStyle(fontSize: 10, color: Colors.grey))
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(controller.imagePath.value), fit: BoxFit.cover),
                              ),
                      )),
                      
                  const SizedBox(width: 16),

                  // Tombol Utama Absen (Di sebelah kanan, mengambil sisa ruang)
                  Expanded(
                    child: Obx(() {
                      Color warnaTombol;
                      String teksTombol;
                      
                      if (controller.absenStatus.value == 'belum_masuk') {
                        warnaTombol = Colors.green;
                        teksTombol = 'ABSEN MASUK';
                      } else if (controller.absenStatus.value == 'sudah_masuk') {
                        warnaTombol = Colors.orange;
                        teksTombol = 'ABSEN PULANG';
                      } else {
                        warnaTombol = Colors.grey;
                        teksTombol = 'SELESAI HARI INI';
                      }

                      return SizedBox(
                        height: 55, // Tinggi tombol diseragamkan
                        child: ElevatedButton(
                          onPressed: controller.absenStatus.value == 'sudah_pulang' 
                              ? null 
                              : () => controller.catatKehadiran(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: warnaTombol,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: Text(
                            teksTombol,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. LINK RIWAYAT (Paling Bawah)
              TextButton.icon(
                onPressed: () => Get.to(() => HistoryView()),
                icon: const Icon(Icons.history, color: Colors.blue, size: 20),
                label: const Text(
                  'Lihat Riwayat Kehadiran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}