import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smartschoolapp_fixed_new/services/services_store.dart';

import 'Adminscreen.dart';
import 'Teacher.dart';
import 'main.dart';

class home extends StatefulWidget{
  final String schoolId;
  final String studentid;

  const home({
    super.key,
    required this.schoolId,
    required this.studentid,
  });

  @override
  State<home> createState() => _home();
}
class _home extends State<home> {
  String? img1;
  String? img2;
  String? img3;
  String? img4;
  bool showDot = false;

  String? profileImageUrl;
  String? Schoolname;
  int _currentIndex = 0;
  int pressedIndex = -1;
  List<String?> sliderImages = [null, null, null, null];
  late DatabaseReference sliderRef;
  late StreamSubscription<DatabaseEvent> _sliderSub;
  Timer? _sliderTimer;
  late PageController _pageController;
  TextEditingController searchController = TextEditingController();
  late List<Map<String, dynamic>> items = [


    {
      "title": "Announcement",
      "folder": "Announcement",
      "image": "assets/images/anno.png",
      "route": (String title) =>
          Announcements(SchoolId: widget.schoolId, Teacherid: widget.studentid,),
    },
    {
      "title": "Events",
      "folder": "Event",
      "image": "assets/images/Event.png",
      "route": (String title) =>
          Eventss(SchoolId: widget.schoolId,Teacherid: widget.studentid,),

    },
    {
      "title": "Notice",
      "folder": "Notice",
      "image": "assets/images/notice.png",
      "route": (String title) =>NoticesforStudent(SchoolId: widget.schoolId,studentid: widget.studentid,),

    },

    {
      "title": "Gallery",
      "folder": "Gallery",
      "image": "assets/images/sum.png",
      "route": (String title) =>
          Gallerys(SchoolId: widget.schoolId, Teacherid: widget.studentid,),
    },
    {
      "title": "Home Work",
      "folder": "Homework",
      "image": "assets/images/work.png",
      "route": (String title) =>
          Homeworkpage(SchoolId: widget.schoolId,studentid: widget.studentid,),
    },
    {
      "title": "Time Table",
      "folder": "TimeTable",
      "image": "assets/images/table.png",
      "route": (String title) =>
          Timetables(SchoolId: widget.schoolId, Title: title, userid: widget.studentid,),
    },
    {
      "title": "Attendance",
      "folder": "Attendance",
      "image": "assets/images/att.png",
      "route": (String title) =>
          Attendanceofstudent(SchoolId: widget.schoolId, studentid: widget.studentid, title: "Attendance",),
    },
  ];
  List<Map<String, dynamic>> filteredItems = [];
  Map<String, bool> redDotStatus = {};

  @override
  void initState() {
    super.initState();
    filteredItems = List.from(items);
    sliderRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.schoolId}/Slider");

    loadStudentData();
    loadSchoolData();
    _pageController = PageController();
    _loadSliderImages();
    _startAutoSlide();
    checkAllUpdates();
    checkUpdate();
  }
  Future<void> checkUpdate() async {
    bool hasNew = await RedDotService.hasNewUpdate(
      "smart/user1/${widget.schoolId}/Teacher/${widget.studentid}/Notification",
      widget.studentid,
    );

    if (!mounted) return;

    setState(() {
      showDot = hasNew;
    });
  }

  Future<void> checkAllUpdates() async {

    for (var item in items) {

      String folder = item["folder"];

      bool hasNew = await RedDotService.hasNewUpdate(
        "smart/user1/${widget.schoolId}/$folder",
        widget.studentid,
      );

      redDotStatus[folder] = hasNew;
    }

    if (!mounted) return;

    setState(() {});
  }


  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _currentIndex = (_currentIndex + 1) % 4;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }
  void _loadSliderImages() {
    _sliderSub = sliderRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          sliderImages[0] = data["img1"];
          sliderImages[1] = data["img2"];
          sliderImages[2] = data["img3"];
          sliderImages[3] = data["img4"];
        });
      }
    });
  }
  Widget imageSlider(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: width < 400 ? 160 : 200, // ✅ responsive height
      child: PageView.builder(
        controller: _pageController,
        itemCount: 4,
        itemBuilder: (context, index) {
          final img = sliderImages[index];
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade300,
              image: img != null
                  ? DecorationImage(
                image: NetworkImage(img),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: img == null
                ? const Center(
              child:
              Icon(Icons.add, size: 50, color: Colors.black54),
            )
                : null,
          );
        },
      ),
    );
  }

  void filterSearch(String query) {
    setState(() {
      filteredItems = items
          .where((item) =>
          item["title"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sliderTimer?.cancel();
    _sliderSub.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSchoolData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.schoolId}",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        Schoolname= data['name'];
      });
    }
  }
  Future<void> loadStudentData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.schoolId}/Student/${widget.studentid}",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        profileImageUrl = data['image'];
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ✅ responsive grid count
    int crossAxisCount = width >= 900
        ? 5
        : width >= 600
        ? 4
        : 3;
        return Scaffold(
          appBar: AppBar(

          title: Row(
            children: [
              InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>studentAccountpage(
                        SchoolId: widget.schoolId,
                        Teacherid: widget.studentid,
                        onlyview: false, title: "Account",
                      ),
                    ),
                  );
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: CircleAvatar(

                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child: (profileImageUrl == null ||
                          profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Schoolname ?? "Loading...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () async {

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationPage(
                        Schoolid: widget.schoolId,
                        userid: widget.studentid,
                        user: "Student",
                      ),
                    ),
                  );

                  // 🔄 Refresh red dot after returning
                  checkUpdate();
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [

                        const Icon(
                          Icons.notifications,
                          color: Colors.deepPurple,
                        ),

                        if (showDot)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),

          body: CustomScrollView(
            slivers: [
              /// 🔍 SEARCH BAR
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    width < 360 ? 12 : 20,
                    12,
                    0,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon:
                      const Icon(Icons.search, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              /// 🖼 SLIDER
              SliverToBoxAdapter(child: imageSlider(context)),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              /// 🧩 GRID
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = filteredItems[index];
                      final isPressed = pressedIndex == index;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTapDown: (_) =>
                            setState(() => pressedIndex = index),
                        onTapUp: (_) =>
                            setState(() => pressedIndex = -1),
                        onTapCancel: () =>
                            setState(() => pressedIndex = -1),
                        onTap: () {
                          final routeBuilder = item["route"];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  routeBuilder(item["title"]),
                            ),
                          );
                        },
                        child: Card(
                          color:
                          isPressed ? Colors.deepPurple : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: Colors.deepPurple),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.asset(
                                    item["image"],
                                    width: width < 360 ? 45 : 60,
                                    height: width < 360 ? 45 : 60,
                                    color: isPressed ? Colors.white : null,
                                  ),

                                  if (redDotStatus[item["folder"]] == true)

                                    Container(
                                      height: 10,
                                      width: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                item["title"],
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPressed ? Colors.white : Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        ),
                      );
                    },
                    childCount: filteredItems.length,
                  ),
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // ✅ responsive
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

class Attendanceofstudent extends StatefulWidget{
  final String SchoolId;
  final String studentid;
  final String title;
  const Attendanceofstudent({super.key, required this.SchoolId,required this.studentid,required this.title});

  @override
  State<Attendanceofstudent> createState() => _Attendanceofstudent();
}

class _Attendanceofstudent extends State<Attendanceofstudent> {
  TextEditingController dateController = TextEditingController();

  List<Map<String, dynamic>> attendanceList = [];

  bool isFilterApplied = false;


  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString().split(" ")[0];
    loadAttendance();
    updateSeen();

  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Attendance",
      widget.studentid,
    );
  }



  // ================= LOAD ATTENDANCE =================
  Future<void> loadAttendance() async {
    attendanceList.clear();

    // 🔹 DATE FILTER APPLIED
    if (isFilterApplied) {
      ref = FirebaseDatabase.instance.ref(
        "smart/user1/${widget.SchoolId}/Attendance/${dateController.text}",
      );

      final snapshot = await ref.get();
      if (!snapshot.exists) {
        setState(() {});
        return;
      }

      final Map data =
      Map<String, dynamic>.from(snapshot.value as Map);

      if (!data.containsKey(widget.studentid)) {
        setState(() {});
        return;
      }

      final record =
      Map<String, dynamic>.from(data[widget.studentid]);

      attendanceList.add({
        "date": dateController.text,
        "takenby": record["takenby"] ?? "",
        "status": record["status"] ?? "",
      });
    }

    // 🔹 LOAD ALL ATTENDANCE
    else {
      ref = FirebaseDatabase.instance.ref(
        "smart/user1/${widget.SchoolId}/Attendance",
      );

      final snapshot = await ref.get();
      if (!snapshot.exists) {
        setState(() {});
        return;
      }

      final Map allDates =
      Map<String, dynamic>.from(snapshot.value as Map);

      allDates.forEach((date, students) {
        if (students is! Map) return;

        if (!students.containsKey(widget.studentid)) return;

        final record =
        Map<String, dynamic>.from(students[widget.studentid]);

        attendanceList.add({
          "date": date,
          "takenby": record["takenby"] ?? "",
          "status": record["status"] ?? "",
        });
      });
    }

    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 📅 DATE PICKER
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Select Date",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  dateController.text =
                  picked.toString().split(" ")[0];
                  isFilterApplied = true;
                  loadAttendance();
                }
              },
            ),
          ),

          const SizedBox(height: 10),

          // 📋 ATTENDANCE LIST
          Expanded(
            child: attendanceList.isEmpty
                ? const Center(child: Text("No Attendance Found"))
                : ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final item = attendanceList[index];
                final bool isPresent =
                    item["status"] == "Present";

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: isPresent
                          ? Colors.green
                          : Colors.red,
                      size: 14,
                    ),
                    title: Text(
                      "Date: ${item["date"]}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Taken by: ${item["takenby"]}",
                    ),
                    trailing: Text(
                      item["status"],
                      style: TextStyle(
                        color: isPresent
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class Homeworkpage extends StatefulWidget {
  final String SchoolId;
  final String studentid;
  const Homeworkpage({super.key, required this.SchoolId,required this.studentid});
  @override
  State<Homeworkpage> createState() => _Homeworkpage();
}
class _Homeworkpage extends State<Homeworkpage>{
  String? role;
  String? medium;
  String? division;
  String? standard;
  List homeworkList = [];


  late DatabaseReference view;
  Future<void> loaddata() async {
    final studentRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Student/${widget.studentid}");

    DataSnapshot snapshot = await studentRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        role = data['role'];
        medium = data['medium'];
        standard = data['Standard']; // correct spelling
        division = data['division'];
      });

      print("STUDENT DATA LOADED → $data");
    } else {
      print("❌ Student data not found");
    }
  }

  @override
  void initState() {
    super.initState();
    updateSeen();
    loaddata();
    view = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Homework");
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Homework",
      widget.studentid,
    );
  }

  void loadnotice(){
    view.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      List filteredNotices = [];

      if (data != null) {
        data.forEach((key, value) {
          if (
          (value['Medium'] == medium)
          ) {
            if (
            (value['Standard'] == standard )
            ) {
              if (
              (value['Division'] == division )
              ) {
                filteredNotices.add(value);
              }
            }
          }
        });
      }

      setState(() {
        homeworkList = filteredNotices;
      });
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HomeWork"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(

            child: StreamBuilder(
              stream: view.onValue,
              builder: (context, snapshot) {

                if (medium == null || standard == null || division == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No HomeWork Found"));
                }

                Map data = snapshot.data!.snapshot.value as Map;

                List filteredNotices = data.entries.where((e) {
                  final hw = e.value as Map;

                  return hw['Medium']?.toString() == medium &&
                      hw['Standard']?.toString() == standard &&
                      hw['Division']?.toString() == division;
                }).map((e) => e.value).toList();


                if (filteredNotices.isEmpty) {
                  return const Center(child: Text("No HomeWork for you"));
                }

                return ListView.builder(
                  itemCount: filteredNotices.length,
                  itemBuilder: (context, index) {
                    final dt = filteredNotices[index]["DateTime"] != null
                        ? DateTime.parse(filteredNotices[index]["DateTime"])
                        : DateTime.now();

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          "Home Work :- ${filteredNotices[index]["Home Work"] ?? ""}",
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date :- ${DateFormat('dd MMM yyyy').format(dt)}"),
                            Text("Time :- ${DateFormat('HH:mm').format(dt)}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )

          ),
        ],
      ),
    );
  }

}
class NoticesforStudent extends StatefulWidget {
  final String SchoolId;
  final String studentid;
  const NoticesforStudent({super.key, required this.SchoolId,  required this.studentid});
  @override
  State<NoticesforStudent> createState() => _NoticesforStudent();
}
class _NoticesforStudent extends State<NoticesforStudent>{
  String? role;
  String? medium;
  String? division;
  String? standard;
  List noticeList = [];


  late DatabaseReference view;
  Future<void> loaddata() async {
    DatabaseReference studentRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Student/${widget.studentid}");

    DataSnapshot snapshot = await studentRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        role = data['role'];
        medium = data['medium'];
        division = data['division'];
        standard = data['Standard']; // typo as per DB

      });

      print("STUDENT => $medium | $division | $standard");
    }
  }

  @override
  void initState() {
    super.initState();
    loaddata();
    loadnotice();
    updateSeen();

  }


  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Notice",
      widget.studentid,
    );
  }

  void loadnotice(){
    view = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Notice");
    view.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      List filteredNotices = [];

      if (data != null) {
        data.forEach((key, value) {

          print("NOTICE => ${value['Medium']} | ${value['Division']} | ${value['Standard']}");
          if (
          (value['Medium'] == medium)
          ) {
            if (
            (value['Standard'] == standard )
            ) {
              if (
              (value['Division'] == division )
              ) {
                filteredNotices.add(value);
              }
            }
          }

        });
      }

      setState(() {
        noticeList = filteredNotices;
      });
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notice"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: view.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No Notice Found"));
                  }

                  Map data = snapshot.data!.snapshot.value as Map;

                  List filteredNotices = data.entries.where((e) {
                    final notice = Map<String, dynamic>.from(e.value);

                    return notice['Medium'] == medium &&
                        notice['Division'] == division &&
                        notice['Standard'] == standard;
                  }).map((e) => e.value).toList();


                  if (filteredNotices.isEmpty) {
                    return const Center(child: Text("No Notice for your medium"));
                  }

                  return ListView.builder(

                    itemCount: filteredNotices.length,
                    itemBuilder: (context, index) {
                      final dt = filteredNotices[index]["DateTime"] != null
                          ? DateTime.parse(filteredNotices[index]["DateTime"])
                          : DateTime.now();

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                            title: Text(
                              "Notice :- ${filteredNotices[index]["Notice"] ?? ""}",
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date :- ${DateFormat('dd MMM yyyy').format(dt)}"),


                                Text("Time :- ${DateFormat('HH:mm').format(dt)}"),
                              ],
                            )
                        ),
                      );
                    },
                  );
                }

            ),
          ),
        ],
      ),
    );
  }

}
class studentAccountpage extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;
  final String title;
  final bool onlyview ;
  const studentAccountpage({super.key, required this.SchoolId,required this.Teacherid,required this.onlyview,required this.title});

  @override
  State<studentAccountpage> createState() => _studentAccountpage();
}
class _studentAccountpage extends State<studentAccountpage>{
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController rollno = TextEditingController();

  File? selectedImage;
  String? profileImage;

  String? selectedGender;
  String? medium;
  String? division;
  String? std;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> standards = ["1","2","3","4","5","6","7","8","9","10","11","12"];
  final List<String> divisions = ["A", "B", "C","D","E","F"];
  final List<String> genders = ["Male", "Female"];



  @override
  void initState() {
    super.initState();
    loadAdminData();
    loadProfileImage();
  }

  // ================= LOAD ADMIN DATA =================
  Future<void> loadAdminData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolId}/Student/${widget.Teacherid}",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        roleController.text = data['role'] ?? '';
        schoolController.text = data['schoolId'] ?? '';
        phoneController.text = data['phone'] ?? '';
        rollno.text = data['rollNo'] ?? '';
        profileImage = data['image'];
        selectedGender =
        genders.contains(data['gender']) ? data['gender'] : null;
        medium = mediums.contains(data['medium']) ? data['medium'] : null;
        std = standards.contains(data['Standard']) ? data['Standard'] : null;
        division = divisions.contains(data['division']) ? data['division'] : null;

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
      "smart/user1/${widget.SchoolId}/Student/${widget.Teacherid}",
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
      "smart/user1/${widget.SchoolId}/Student/${widget.Teacherid}",
    );

    String? imageUrl = profileImage;

    try {
      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
      }

      await ref.update({
        "phone": phoneController.text.trim(),
        "gender": selectedGender,
        "medium": medium,
        "Standard": std,
        "division": division,
        "rollNo": rollno.text.trim(),

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Account Page AppBar
      appBar:AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: widget.onlyview ? null : pickImage,
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
              controller: rollno,
              readOnly: widget.onlyview,
              decoration: InputDecoration(
                hintText: "RollNo",
                prefixIcon: const Icon(Icons.person),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: emailController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: schoolController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: roleController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: phoneController,
              readOnly: widget.onlyview,
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
              onChanged: widget.onlyview ? null : (v) {
                setState(() => selectedGender = v);
              },
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: medium,
              decoration: InputDecoration(
                hintText: "Medium",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: mediums
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: widget.onlyview ? null : (v) {
                setState(() => medium = v);
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: division,
              decoration: InputDecoration(
                hintText: "Division",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: divisions
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: widget.onlyview ? null : (v) {
                setState(() => division = v);
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: std,
              decoration: InputDecoration(
                hintText: "Standard ",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: standards
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: widget.onlyview ? null : (v) {
                setState(() => std = v);
              },
            ),
            const SizedBox(height: 20),


            if (!widget.onlyview)
              Container(
                height: 40,
                width: 500,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  child: const Text("Save"),
                ),
              ),

            const SizedBox(height: 20),

            if (!widget.onlyview)
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