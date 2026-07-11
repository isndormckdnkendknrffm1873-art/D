import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _status = "تطبيق جلب الموقع\nاضغط للاتصال وإرسال الـ GPS";
  bool _isLoading = false;

  Future<void> _sendLocation() async {
    setState(() {
      _isLoading = true;
      _status = "جاري طلب صلاحيات الـ GPS...";
    });

    try {
      // 1. التحقق من تشغيل الـ GPS وطلب الصلاحيات
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("يرجى تشغيل خدمة الـ GPS (الموقع) في الهاتف أولاً.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("تم رفض صلاحية الوصول للموقع.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("صلاحيات الموقع مرفوضة نهائياً من الإعدادات.");
      }

      setState(() {
        _status = "جاري التقاط الإحداثيات الدقيقة من القمر الصناعي...";
      });

      // 2. جلب الموقع الدقيق
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _status = "تم الالتقاط! جاري الإرسال للسيرفر...";
      });

      // 3. إرسال البيانات للواجهة
      final client = HttpClient();
      final uri = Uri.parse('https://eos4rirjsl8yp5z.m.pipedream.net');
      final request = await client.postUrl(uri);
      
      request.headers.set('content-type', 'application/json');
      final body = jsonEncode({
        "message": "GPS Location Captured!",
        "latitude": position.latitude, // خط العرض
        "longitude": position.longitude, // خط الطول
        "accuracy": position.accuracy, // دقة التحديد بالمتر
        "time": DateTime.now().toIso8601String()
      });
      
      request.write(body);
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() { _status = "تم الإرسال بنجاح! ✅\nافحص PipeDream لترى الإحداثيات"; });
      } else {
        setState(() { _status = "خطأ من السيرفر: ${response.statusCode}"; });
      }
      client.close();
    } catch (e) {
      setState(() { _status = "توقف بسبب:\n$e"; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: _isLoading ? Colors.orange : Colors.redAccent),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              if (!_isLoading)
                ElevatedButton.icon(
                  onPressed: _sendLocation,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text("إرسال إحداثياتي الآن", style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  ),
                ),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }
}
