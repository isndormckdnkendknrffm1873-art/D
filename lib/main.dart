import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = "تطبيق تجريبي نظيف\nاضغط للاتصال بالواجهة";

  Future<void> sendPing() async {
    setState(() {
      _status = "جاري إرسال التجربة...";
    });
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://eos4rirjsl8yp5z.m.pipedream.net');
      final request = await client.postUrl(uri);
      
      request.headers.set('content-type', 'application/json');
      final body = jsonEncode({
        "message": "Hello from the Clean Test App!",
        "time": DateTime.now().toIso8601String()
      });
      
      request.write(body);
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() { _status = "تمت التجربة بنجاح! ✅\nالبيانات في PipeDream الآن"; });
      } else {
        setState(() { _status = "خطأ من السيرفر: ${response.statusCode}"; });
      }
      client.close();
    } catch (e) {
      setState(() { _status = "فشل الاتصال: $e"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: sendPing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text("إرسال التجربة", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
