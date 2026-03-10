import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Adminscreen.dart';
import 'Student.dart';
import 'Teacher.dart';
import 'authorscreen.dart';
import 'main.dart';

class DynamicSchoolSplash extends StatefulWidget {
  const DynamicSchoolSplash({super.key});

  @override
  State<DynamicSchoolSplash> createState() => _DynamicSchoolSplashState();
}

class _DynamicSchoolSplashState extends State<DynamicSchoolSplash> {
  String? logoUrl;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startFlow();
    });
  }


  Future<void> startFlow() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    print("Splash URL from prefs: $logoUrl");

    // FIRST TIME → LOGIN PAGE
    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MyHomePage(title: 'Smart School Login'),
        ),
      );
      return;
    }

    // LOGGED IN → SHOW SCHOOL SPLASH
    logoUrl = prefs.getString("urischool");
    if (mounted) setState(() {});

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final role = prefs.getString("role") ?? "";
    final schoolId = prefs.getString("schoolId") ?? "";
    final userId = prefs.getString("adminId") ?? "";


    Widget nextScreen = const MyHomePage(title: 'Smart School Login');

    if (role == "Admin" && schoolId.isNotEmpty && userId.isNotEmpty) {
      nextScreen = Admin(schoolId: schoolId, adminId: userId);
    } else if (role == "Teacher" && schoolId.isNotEmpty && userId.isNotEmpty) {
      nextScreen = Teacher(SchoolId: schoolId, Teacherid: userId);
    } else if (role == "Student" && schoolId.isNotEmpty && userId.isNotEmpty) {
      nextScreen = home(schoolId: schoolId, studentid: userId);
    } else if (role == "Author") {
      nextScreen = Author(SchoolId: "NA");
    } else {
      // fallback → login
      nextScreen = const MyHomePage(title: 'Smart School Login');
    }


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(   // Makes it full screen
        child: logoUrl != null
            ? Image.network(
          logoUrl!,
          fit: BoxFit.cover,   // Cover full screen
          errorBuilder: (_, __, ___) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        )
            : const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
