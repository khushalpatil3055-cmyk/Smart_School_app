import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartschoolapp_fixed_new/Adminscreen.dart';
import 'package:smartschoolapp_fixed_new/Teacher.dart';
import 'package:smartschoolapp_fixed_new/authorscreen.dart';
import 'package:smartschoolapp_fixed_new/splash.dart';

import 'Student.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  runApp(
    MyApp(
      firstScreen: isLoggedIn
          ? const DynamicSchoolSplash()
          : const MyHomePage(title: 'Smart School Login'),
    ),
  );
}

Future<void> saveLoginSchool(String uri) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("urischool", uri);
}


// ================= SAVE LOGIN DATA =================
Future<void> saveLoginData(
    String email,
    String pass,
    String role,
    String schoolId,
    String userId,
    ) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString("email", email);
  await prefs.setString("password", pass);
  await prefs.setString("role", role);
  await prefs.setString("schoolId", schoolId);
  await prefs.setString("adminId", userId); // reused key
  await prefs.setBool("isLoggedIn", true);
}

class MyApp extends StatelessWidget {
  final Widget firstScreen;
  const MyApp({super.key, required this.firstScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart School',
      home: firstScreen,
    );
  }
}

// ================= LOGIN PAGE =================

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final nameText = TextEditingController();
  final emailText = TextEditingController();
  final schoolid = TextEditingController();
  final pass = TextEditingController();

  String? selectedRole;
  late DatabaseReference ref;
  late DatabaseReference school;


  Future<void> loginUser() async {
    String inputEmail = emailText.text.trim();
    String inputPass = pass.text.trim();

    if (selectedRole == null) {
      _showAlert("Please select role");
      return;
    }

    String inputRole = selectedRole!;
    final prefs = await SharedPreferences.getInstance();

    // ================= AUTHOR LOGIN (FIX HERE) =================
    if (inputRole == "Author") {
      final snapshot =
      await FirebaseDatabase.instance.ref("smart/user1").get();

      if (!snapshot.exists || snapshot.value == null) {
        _showAlert("Author not found");
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final dbEmail = data["email"]?.toString().trim().toLowerCase();
      final dbPass = data["password"]?.toString().trim();

      if (dbEmail == inputEmail.toLowerCase() &&
          dbPass == inputPass) {

        await saveLoginData(
          inputEmail,
          inputPass,
          "Author",
          "NA",
          "AUTHOR",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Author(SchoolId: "NA"),
          ),
        );
        return; // 🔴 IMPORTANT
      } else {
        _showAlert("Invalid Author credentials ❌");
        return;
      }
    }

    // ================= ADMIN / TEACHER / STUDENT =================

    String inputSchoolId = schoolid.text.trim();

    ref = FirebaseDatabase.instance
        .ref("smart/user1/$inputSchoolId/$inputRole");

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) {
        _showAlert("No users found");
        return;
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(snapshot.value as Map);

      for (final entry in data.entries) {
        if (entry.value is! Map) continue;

        final user = Map<String, dynamic>.from(entry.value);

        final dbEmail =
        user["email"]?.toString().trim().toLowerCase();
        final dbPass =
        user["password"]?.toString().trim();

        if (dbEmail == inputEmail.toLowerCase() &&
            dbPass == inputPass) {

          await saveLoginData(
            inputEmail,
            inputPass,
            inputRole,
            inputSchoolId,
            entry.key.toString(),
          );


          final schoolSnap = await FirebaseDatabase.instance
              .ref("smart/user1/$inputSchoolId")
              .get();

          if (schoolSnap.exists && schoolSnap.value != null) {
            final schoolData =
            Map<String, dynamic>.from(schoolSnap.value as Map);

            final splashUrl = schoolData["imageschool"];

            print("Splash URL from Firebase: $splashUrl");

            if (splashUrl != null) {
              await saveLoginSchool(splashUrl.toString());
            }
          }

          if (inputRole == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DynamicSchoolSplash(),
              ),
            );

          } else if (inputRole == "Teacher") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DynamicSchoolSplash(),
              ),
            );

          } else if (inputRole == "Student") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DynamicSchoolSplash(),
              ),
            );

          }
          return;
        }
      }

      _showAlert("Invalid credentials ❌");
    } catch (e) {
      _showAlert("Error: $e");
    }
  }


  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Status"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart School"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.symmetric(
              vertical: 30,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                width: 2,
                color: Colors.deepPurple,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= EMAIL =================
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: emailText,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? "Enter email"
                          : null,
                    ),
                  ),

                  // ================= SCHOOL ID =================
                  if (selectedRole != "Author")
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: schoolid,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          hintText: "School ID",
                          prefixIcon: const Icon(Icons.school),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? "Enter school ID" : null,
                      ),
                    ),

                  // ================= ROLE =================
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      value: selectedRole,
                      items: const [
                        "Admin",
                        "Teacher",
                        "Student",
                        "Author",
                      ]
                          .map(
                            (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ),
                      )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedRole = v),
                      validator: (v) =>
                      v == null ? "Select role" : null,
                      hint: const Text("Select Role"),
                    ),
                  ),

                  // ================= PASSWORD =================
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? "Enter password"
                          : null,
                    ),
                  ),

                  // ================= LOGIN BUTTON =================
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final form = _formKey.currentState;
                          if (form == null) {
                            _showAlert("Form not ready, try again");
                            return;
                          }

                          if (form.validate()) {
                            loginUser();
                          }
                        },

                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )

    );
  }
}
