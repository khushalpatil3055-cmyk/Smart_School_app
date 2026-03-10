import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartschoolapp_fixed_new/Adminscreen.dart';

import 'Student.dart';
import 'Teacher.dart';

class Adduser extends StatefulWidget {
  final String SchoolId;
  final String Title;

  const Adduser({
    super.key,
    required this.SchoolId,
    required this.Title,
  });

  @override
  State<Adduser> createState() => _AddUserState();
}

class _AddUserState extends State<Adduser> {
  /// ROLE FLAGS
  bool get isTeacher => widget.Title == "Add Teacher";
  bool get isAdmin => widget.Title == "Add Admin";
  bool get isStudent => widget.Title == "Add Student";
  bool get isSchool => widget.Title == "Add School";

  /// FIREBASE REF
  DatabaseReference get ref {
    if (isTeacher) {
      return FirebaseDatabase.instance
          .ref("smart/user1/${widget.SchoolId}/Teacher");
    } else if (isAdmin) {
      return FirebaseDatabase.instance
          .ref("smart/user1/${widget.SchoolId}/Admin");
    } else if (isStudent) {
      return FirebaseDatabase.instance
          .ref("smart/user1/${widget.SchoolId}/Student");
    } else {
      return FirebaseDatabase.instance.ref("smart/user1");
    }
  }

void deleteuser(String key){
    showDialog(context: context, builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            ),
              title: Text("Are You Sure That You Want To Delete This User ?"),
              actions: [
                ElevatedButton(onPressed:() => Navigator.pop(context),style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) => states.contains(MaterialState.pressed)
                    ? Colors.deepPurple
                        :Colors.white,

                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.pressed)
                        ? Colors.black
                        : Colors.deepPurple,
                  ),
                ), child: Text("No")),
                ElevatedButton(onPressed: () async {
      await ref.child(key).remove();
      Navigator.pop(context);
      },style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.pressed)
                        ? Colors.deepPurple
                        :Colors.white,

                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.pressed)
                        ? Colors.black
                        : Colors.deepPurple,
                  ),
                ), child: Text("Yes")),
              ],
        ),
      );
    },);
}

  void gotoadminadd(bool school, String sid) {
    if (school) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Adduser(SchoolId: sid, Title: "Add Admin"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double buttonWidth =
          constraints.maxWidth > 600 ? 250 : constraints.maxWidth * 0.6;

          return Column(
            children: [
              const SizedBox(height: 20),

              /// ADD BUTTON
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Registeruserscreen(
                            title: widget.Title,
                            userId: "",
                            schoolId: isSchool
                                ? DateTime.now()
                                .millisecondsSinceEpoch
                                .toString()
                                : widget.SchoolId,
                            oldData: const {},
                            isTeacher: isTeacher,
                            isAdmin: isAdmin,
                            isStudent: isStudent,
                            isSchool: isSchool,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("Add", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// LIST
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: ref.onValue,
                  builder: (context, snapshot) {
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
                      if (value is Map &&
                          (!isSchool || value.containsKey("schoolId"))) {
                        users.add({
                          "key": key,
                          ...Map<String, dynamic>.from(value),
                        });
                      }
                    });

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return InkWell(
                          onLongPress: () {
                            if (widget.Title == "Add Admin") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => accountpage(

                                    onlyview: true, schoolId: user["schoolId"], adminid:  user["key"], title: 'Details',
                                  ),
                                ),
                              );
                            }
                            else if (widget.Title == "Add Teacher") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Accountpage(
                                    SchoolId: user["schoolId"],
                                    Teacherid: user["key"],
                                    onlyview: true, title: "Details",
                                  ),
                                ),
                              );
                            }
                            else if (widget.Title == "Add Student") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>studentAccountpage(
                                    SchoolId: user["schoolId"],
                                    Teacherid: user["key"],
                                    onlyview: true, title: "Details",
                                  ),
                                ),
                              );
                            }
                          },


                          onTap: () =>
                              gotoadminadd(isSchool, user["key"]),
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.deepPurple),
                              title: Text(user["name"] ?? ""),
                              subtitle: Text(user["email"] ?? ""),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.deepPurple),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              Registeruserscreen(
                                                title: "Update",
                                                userId: user["key"],
                                                schoolId: widget.SchoolId,
                                                oldData: user,
                                                isTeacher: isTeacher,
                                                isAdmin: isAdmin,
                                                isStudent: isStudent,
                                                isSchool: isSchool,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: ()  {
                                      deleteuser(user["key"]);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.message,
                                        color: Colors.deepPurple),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => message(
                                            Schoolid: user["schoolId"],
                                            userid: user["key"],
                                            user: user["role"] ?? "",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ================= REGISTER USER =================

class Registeruserscreen extends StatefulWidget {
  final String title;
  final String userId;
  final String schoolId;
  final Map oldData;
  final bool isTeacher;
  final bool isAdmin;
  final bool isStudent;
  final bool isSchool;

  const Registeruserscreen({
    super.key,
    required this.title,
    required this.userId,
    required this.schoolId,
    required this.oldData,
    required this.isTeacher,
    required this.isAdmin,
    required this.isStudent,
    required this.isSchool,
  });

  @override
  State<Registeruserscreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<Registeruserscreen> {
  final _formKey = GlobalKey<FormState>();
  final schoolIdText = TextEditingController();
  File? selectedImage;
  final nameText = TextEditingController();
  final emailText = TextEditingController();
  final pass = TextEditingController();

  String get role {
    if (widget.isAdmin) return "Admin";
    if (widget.isTeacher) return "Teacher";
    if (widget.isSchool) return "School";
    return "Student";
  }

  @override
  void initState() {
    super.initState();

    if (widget.oldData.isNotEmpty) {
      nameText.text = widget.oldData["name"] ?? "";
      emailText.text = widget.oldData["email"] ?? "";
      pass.text = widget.oldData["password"] ?? "";
      schoolIdText.text = widget.oldData["schoolId"] ?? "";
    }
  }
  Future<bool> userAlreadyExists(String email) async {
    DatabaseReference ref;

    if (widget.isSchool) {
      ref = FirebaseDatabase.instance.ref("smart/user1");
    } else {
      ref = FirebaseDatabase.instance
          .ref("smart/user1/${widget.schoolId}/$role");
    }

    final snapshot = await ref.get();
    if (!snapshot.exists) return false;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (var entry in data.entries) {
      if (entry.value is Map) {
        final user = Map<String, dynamic>.from(entry.value);
        if (user["email"] == email) {
          return true;
        }
      }
    }
    return false;
  }


  void showUserExistsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("User Exists"),
        content: const Text("This user already exists in the database."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }
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


  Future<void> saveUser() async {
    if (widget.isSchool) {
      final schoolId = schoolIdText.text.trim();
      String? imageUrl;
      final ref =
      FirebaseDatabase.instance.ref("smart/user1/$schoolId");
      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
      }
      await ref.update({
        "name": nameText.text.trim(),
        "email": emailText.text.trim(),
        "password": pass.text.trim(),
        "role": "School",
        "imageschool": imageUrl,
        "schoolId": schoolId,
      });

    } else {
      final ref = FirebaseDatabase.instance
          .ref("smart/user1/${widget.schoolId}/$role");

      if (widget.oldData.isEmpty) {
        await ref.push().set({
          "name": nameText.text.trim(),
          "email": emailText.text.trim(),
          "password": pass.text.trim(),
          "role": role,
          "schoolId": widget.schoolId,
        });
      } else {
        await ref.child(widget.userId).update({
          "name": nameText.text.trim(),
          "email": emailText.text.trim(),
          "password": pass.text.trim(),
        });
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double formWidth =
          constraints.maxWidth > 600 ? 500 : constraints.maxWidth * 0.9;

          return Center(
            child: SingleChildScrollView(
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 2, color: Colors.deepPurple),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const Text("Registration",
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: nameText,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: emailText,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Email is required";
                          }

                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(v.trim())) {
                            return "Enter a valid email address";
                          }

                          return null; // ✅ valid
                        },
                      ),

                      const SizedBox(height: 15),
                      if (widget.isSchool)
                        Column(
                          children: [
                            TextFormField(
                              controller: schoolIdText,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "School ID",
                                prefixIcon: Icon(Icons.school),
                              ),
                              validator: (v) => v!.isEmpty ? "School ID required" : null,
                            ),

                          ],
                        ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),

                      const SizedBox(height: 25),
                      if (widget.isSchool)
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () async {
                              pickImage();
                            },
                            child: const Text("Pick Splash"),
                          ),
                        ),

                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {

                              // Only check for new user
                              if (widget.oldData.isEmpty) {
                                bool exists = await userAlreadyExists(emailText.text.trim());

                                if (exists) {
                                  showUserExistsDialog();
                                  return;
                                }
                              }

                              saveUser();
                            }
                          },


                          child: Text(widget.oldData.isEmpty
                              ? "Register"
                              : "Update"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
