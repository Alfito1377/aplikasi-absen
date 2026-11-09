import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';

class HomeController extends GetxController {
  var currentTime = ''.obs;
  Timer? _timer;
  var imagePath = ''.obs;
  final ImagePicker _picker = ImagePicker();

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var jarakDariKantor = 0.0.obs;
  var dalamRadius = false.obs;
  var statusLokasi = 'Mencari lokasi...'.obs;
  var isMencariLokasi = true.obs;
  var isUploading = false.obs;
  
  var userName = ''.obs; 
  var absenStatus = 'belum_masuk'.obs; 

  final double officeLat = -8.159875440260537;
  final double officeLng = 113.72308402369067;
  final double batasRadiusMeter = 500.0;

  @override
  void onInit() {
    super.onInit();
    _loadUserName();
    _startClock();
    _cekLokasiSaatIni();
    cekStatusAbsen(); // Cek status absensi 
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      currentTime.value = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  void _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString('user_name') ?? 'Pegawai';
  }

  // cek status
  Future<void> cekStatusAbsen() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance-status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        absenStatus.value = result['status']; 
      }
    } catch (e) {
      print("Error cek status: $e");
    }
  }

  Future<void> _cekLokasiSaatIni() async {
    isMencariLokasi.value = true;
    statusLokasi.value = 'Memeriksa izin GPS...';

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      statusLokasi.value = 'GPS tidak aktif.';
      isMencariLokasi.value = false; return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        statusLokasi.value = 'Izin lokasi ditolak.';
        isMencariLokasi.value = false; return;
      }
    }

    statusLokasi.value = 'Membaca koordinat...';
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    latitude.value = position.latitude;
    longitude.value = position.longitude;

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude, position.longitude, officeLat, officeLng,
    );
    jarakDariKantor.value = distanceInMeters;

    if (distanceInMeters <= batasRadiusMeter) {
      dalamRadius.value = true;
      statusLokasi.value = 'Lokasi Sesuai (${distanceInMeters.toStringAsFixed(1)} m)';
    } else {
      dalamRadius.value = false;
      statusLokasi.value = 'Di Luar Jangkauan (${distanceInMeters.toStringAsFixed(1)} m)';
    }
    isMencariLokasi.value = false;
  }

  void catatKehadiran() async {
    // --- TAMBAHAN KODE PENGUNCI ---
    if (absenStatus.value == 'sudah_pulang') {
      Get.snackbar(
        'Selesai', 
        'Anda sudah menyelesaikan absensi hari ini. Silakan kembali besok pagi.', 
        backgroundColor: Colors.blue[100],
        colorText: Colors.black87,
      );
      return; 
    }

    if (!dalamRadius.value) {
      Get.snackbar('Gagal', 'Anda berada di luar area presensi!', backgroundColor: Colors.red[100]);
      return;
    }
    

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (photo != null) {
        imagePath.value = photo.path;
        isUploading.value = true;

        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/presensi'));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';

        request.fields['latitude'] = latitude.value.toString();
        request.fields['longitude'] = longitude.value.toString();
        request.files.add(await http.MultipartFile.fromPath('foto_bukti', photo.path));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var result = jsonDecode(responseData);

        isUploading.value = false;
        Get.back(); 

        if (response.statusCode == 200) {
          Get.snackbar('Sukses', result['message'], backgroundColor: Colors.green[100]);
          cekStatusAbsen(); 
        } else {
          Get.snackbar('Gagal', result['message'] ?? 'Gagal mencatat presensi', backgroundColor: Colors.red[100]);
        }
      }
    } catch (e) {
      isUploading.value = false;
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal memproses absensi', backgroundColor: Colors.red[100]);
    }
  }

  void refreshLokasi() => _cekLokasiSaatIni();

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}