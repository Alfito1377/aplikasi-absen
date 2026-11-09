import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'history_controller.dart';
import '../../core/api_config.dart';

class HistoryView extends StatelessWidget {
  HistoryView({Key? key}) : super(key: key);

  final HistoryController controller = Get.put(HistoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.listRiwayat.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada riwayat presensi.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        //  daftar riwayat 
        return RefreshIndicator(
          onRefresh: () => controller.fetchHistory(), 
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.listRiwayat.length,
            itemBuilder: (context, index) {
              final data = controller.listRiwayat[index];
              final bool isTepatWaktu = data['status'] == 'Tepat Waktu';

              return Card(
                margin: const EdgeInsets.only(bottom: 12), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: data['foto_bukti'] != null
                          ? Image.network(
                              '${ApiConfig.storageUrl}/${data['foto_bukti']}', 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                            )
                          : const Icon(Icons.person),
                    ),
                  ),
                  title: Text(
                    data['tanggal'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Jam Masuk: ${data['jam_masuk'] ?? '-'}'),
                      const SizedBox(height: 2),
                      Text('Jam Pulang: ${data['jam_pulang'] ?? 'Belum Pulang'}', 
                        style: TextStyle(
                          color: data['jam_pulang'] == null ? Colors.orange : Colors.black
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Koordinat: ${data['latitude']}, ${data['longitude']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isTepatWaktu ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['status'] ?? '-',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}