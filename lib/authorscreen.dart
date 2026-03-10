import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartschoolapp_fixed_new/Adminscreen.dart';
import 'package:smartschoolapp_fixed_new/addteacherscreen.dart';


import 'main.dart';

class Author extends StatefulWidget {
  final String SchoolId;
  const Author({super.key, required this.SchoolId});

  @override
  State<Author> createState() => _AuthorState();
}

class _AuthorState extends State<Author> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      Adduser(
        SchoolId: widget.SchoolId,
        Title: "Add School",
      ),
      const SubscriptionPage(),
      Accountpageadmin(schoolId: widget.SchoolId)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double bottomNavHeight = constraints.maxWidth > 600 ? 100 : 80;
        double buttonSize = constraints.maxWidth > 600 ? 36 : 26;
        double padding = constraints.maxWidth > 600 ? 20 : 14;

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Bottom navigation bar
          bottomNavigationBar: Container(
            width: double.infinity,
            height: bottomNavHeight,
            margin: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600 ? 60 : 20,
              vertical: constraints.maxWidth > 600 ? 30 : 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(Icons.home, 0, buttonSize, padding),
                  _buildNavButton(Icons.school, 1, buttonSize, padding),
                  _buildNavButton(Icons.card_membership, 2, buttonSize, padding),
                  _buildNavButton(Icons.account_circle, 3, buttonSize, padding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton(
      IconData icon, int index, double size, double padding) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.white,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: isSelected ? Colors.deepPurple : Colors.black,
        ),
      ),
    );
  }
}

//
// 🏠 HOME PAGE
//

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalSchools = 0;
  int totalTeachers = 0;
  int totalStudents = 0;
  int totalAdmins = 0;

  @override
  void initState() {
    super.initState();
    loadAuthorDashboardCounts();
  }

  // ================== AUTHOR DASHBOARD COUNT ==================
  Future<void> loadAuthorDashboardCounts() async {
    DatabaseReference ref =
    FirebaseDatabase.instance.ref("smart/user1");

    final snap = await ref.get();

    int schools = 0;
    int teachers = 0;
    int students = 0;
    int admins = 0;

    if (snap.exists && snap.value is Map) {
      final Map data = snap.value as Map;

      for (var entry in data.entries) {
        final value = entry.value;

        if (value is Map) {
          // ✅ Count ONLY schools
          if (value["role"] == "School") {
            schools++;

            // Teachers
            if (value["Teacher"] is Map) {
              teachers += (value["Teacher"] as Map).length;
            }

            // Students
            if (value["Student"] is Map) {
              students += (value["Student"] as Map).length;
            }

            // Admins
            if (value["Admin"] is Map) {
              admins += (value["Admin"] as Map).length;
            }
          }
        }
      }
    }

    setState(() {
      totalSchools = schools;
      totalTeachers = teachers;
      totalStudents = students;
      totalAdmins = admins;
    });
  }


  // ================== UI CARD ==================
  Widget cardUI(String title, int number) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "$number",
            style: const TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadAuthorDashboardCounts, // 👈 refresh on pull
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(), // IMPORTANT
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return cardUI("Total Schools", totalSchools);
                case 1:
                  return cardUI("Total Teachers", totalTeachers);
                case 2:
                  return cardUI("Total Students", totalStudents);
                case 3:
                  return cardUI("Total Admins", totalAdmins);
                default:
                  return const SizedBox();
              }
            },
          ),
        ),
      ),

    );
  }
}
//
// 💳 SUBSCRIPTION PAGE
//
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPage();
}

class _SubscriptionPage extends State<SubscriptionPage> {

  DatabaseReference ref = FirebaseDatabase.instance.ref("smart/user1");

  Future<void> onoff(String sid, bool value) async {
    DatabaseReference schoolRef =
    FirebaseDatabase.instance.ref("smart/user1/$sid");

    await schoolRef.update({
      "issubscribe": value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading user"));
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No user Found"));
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return const Center(child: Text("Invalid data format"));
          }

          final Map data = rawData;

          final List<Map<String, dynamic>> users = [];

          data.forEach((key, value) {
            if (value is Map) {
              users.add({
                "key": key,
                ...Map<String, dynamic>.from(value),
              });
            }
          });

          return ListView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              bool isSubscribed =
                  user["issubscribe"] == true;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.school,
                      color: Colors.deepPurple),
                  title: Text(user["name"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user["email"] ?? ""),
                      Text(user["schoolId"] ?? ""),
                    ],
                  ),
                  trailing: Switch(
                    value: isSubscribed,
                    onChanged: (value) {
                      onoff(user["schoolId"], value);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Accountpageadmin extends StatefulWidget {
  final String schoolId;
  
  const Accountpageadmin({
    super.key,
    required this.schoolId,
   
  });



  @override
  State<Accountpageadmin> createState() => _Accountpageadmin();
}



class _Accountpageadmin extends State<Accountpageadmin> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  File? selectedImage;
  String? profileImage;

  String? selectedGender;



  final List<String> genders = ["Male", "Female"];

  /// 🔹 Cloudinary config
  static const String cloudName = "YOUR_CLOUD_NAME";
  static const String uploadPreset = "YOUR_UPLOAD_PRESET";

  @override
  void initState() {
    super.initState();
    loadAuthorData();
    loadProfileImage();
  }

  // ================= LOAD ADMIN DATA =================
  Future<void> loadAuthorData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        roleController.text = data['role'] ?? '';
        schoolController.text = data['schoolId'];
        phoneController.text = data['phone'] ?? '';

        selectedGender =
        genders.contains(data['gender']) ? data['gender'] : null;

      });
    }
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  // ================= LOAD PROFILE IMAGE =================
  Future<void> loadProfileImage() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1",
    );

    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() => profileImage = data['image']);
    }
  }

  // ================= CLOUDINARY UPLOAD =================
  Future<String?> uploadImageToCloudinary(File image) async {
    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dmpqvjpes/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = "Smart School"
      ..files.add(await http.MultipartFile.fromPath("file", image.path));

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      throw Exception("Cloudinary upload failed");
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1",
    );

    String? imageUrl = profileImage;

    try {
      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
      }

      await ref.update({
        "name": nameController.text.trim(),
        "email":emailController.text.trim(),
         "schoolId":schoolController.text.trim(),
        "phone": phoneController.text.trim(),
        "gender": selectedGender,
        "image": imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      setState(() {
        profileImage = imageUrl;
        selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= UI (UNCHANGED) =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (profileImage != null && profileImage!.isNotEmpty)
                      ? NetworkImage(profileImage!)
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: (selectedImage == null &&
                      (profileImage == null ||
                          profileImage!.isEmpty))
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: nameController,

              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: emailController,

              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: roleController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: schoolController,

              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: InputDecoration(
                hintText: "Gender",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: genders
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedGender = v),
            ),

            const SizedBox(height: 20),

            Container(
              height: 40,
              width: 500,
              child: ElevatedButton(

                onPressed: saveProfile,
                child: const Text("Save"),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 40,
              width: 500,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage(title: "")),
                        (route) => false,
                  );
                },
                child: const Text("Log Out"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

