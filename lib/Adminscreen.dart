
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:smartschoolapp_fixed_new/authorscreen.dart';
import 'package:smartschoolapp_fixed_new/main.dart';
import 'package:smartschoolapp_fixed_new/services/services_store.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// optional (only if used elsewhere)
import 'package:smartschoolapp_fixed_new/addteacherscreen.dart';

import 'Student.dart';
import 'Teacher.dart';

String formatDateTime(String dateTimeString) {

  final dt = DateTime.parse(dateTimeString);
  return DateFormat('dd MMM yyyy • hh:mm a').format(dt);

}



class Admin extends StatefulWidget {
  final String schoolId;
  final String adminId;

  const Admin({super.key, required this.schoolId, required this.adminId});

  @override
  State<Admin> createState() => _AdminPageState();
}
class _AdminPageState extends State<Admin> {
  String? profileImageUrl;
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  String? Schoolname;
  bool showDot = false;
  void checkUpdate() async {
    bool hasNew = await RedDotService.hasNewUpdate(
      "smart/user1/${widget.schoolId}/Notification",
      widget.adminId,
    );

    if (!mounted) return;

    setState(() {
      showDot = hasNew;
    });
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

  @override
  void initState() {
    super.initState();
    loadAdminData();
    loadSchoolData();
    checkUpdate();
    _pages = [
      homepage(
        schoolId: widget.schoolId,
        adminid: widget.adminId,
      ),
      Adduser(
        SchoolId: widget.schoolId,
        Title: "Add Teacher",
      ),
      Adduser(
        SchoolId: widget.schoolId,
        Title: "Add Student",
      ),
      accountpage(
        adminid: widget.adminId,
        schoolId: widget.schoolId, onlyview: false, title: "Account",
      ),
    ];
  }

  Future<void> loadAdminData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.schoolId}/Admin/${widget.adminId}",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        profileImageUrl = data['image'];
      });
    }
  }

  // ================= APP BAR =================
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ❌ No AppBar for Add Teacher & Add Student
    if (_selectedIndex == 1 || _selectedIndex == 2) {
      return null;
    }

    // ✅ Home Page AppBar
    if (_selectedIndex == 0) {
      return AppBar(
        toolbarHeight: width < 360 ? 56 : 70,
        title: Row(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: CircleAvatar(
                  radius: width < 360 ? 18 : 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (profileImageUrl != null &&
                      profileImageUrl!.isNotEmpty &&
                      profileImageUrl!.startsWith('http'))
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: (profileImageUrl == null ||
                      profileImageUrl!.isEmpty ||
                      !profileImageUrl!.startsWith('http'))
                      ? const Icon(Icons.person)
                      : null,
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
                      userid: widget.adminId,
                      user: "Admin",
                    ),
                  ),
                );

                // Refresh red dot after returning
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
      );
    }

    // ✅ Account Page AppBar

  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _pages[_selectedIndex],

        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: 20,
            left: width > 600 ? width * 0.2 : 20, // ✅ responsive margin
            right: width > 600 ? width * 0.2 : 20,
          ),
          child: Container(
            width: double.infinity,
            height: width < 360 ? 65 : 80, // ✅ responsive height
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
                  _buildNavButton(Icons.home, 0, width),
                  _buildNavButton(Icons.person_add_alt_1, 1, width),
                  _buildNavButton(Icons.group_add, 2, width),
                  _buildNavButton(Icons.account_circle, 3, width),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= NAV BUTTON =================
  Widget _buildNavButton(IconData icon, int index, double width) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(width < 360 ? 10 : 14), // ✅ responsive
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
          size: width < 360 ? 22 : 26, // ✅ responsive
          color: isSelected ? Colors.deepPurple : Colors.black,
        ),
      ),
    );
  }
}


class homepage extends StatefulWidget {
  final String schoolId;
  final String adminid;

  const homepage({
    super.key,
    required this.schoolId,
    required this.adminid,
  });

  @override
  State<homepage> createState() => _homepageState();
}


class _homepageState extends State<homepage> {
  late PageController _pageController;

  int _currentIndex = 0;

  List<String?> sliderImages = [null, null, null, null];

  late DatabaseReference sliderRef;
  late StreamSubscription<DatabaseEvent> _sliderSub;
  Timer? _sliderTimer;

  TextEditingController searchController = TextEditingController();
  int pressedIndex = -1;

  late List<Map<String, dynamic>> items = [
    {
      "title": "Attendens",
      "image": "assets/images/att.png",
      "route": (String title) => Attendens(SchoolID: widget.schoolId),
    },
    {
      "title": "Analysis",
      "image": "assets/images/analysis.png",
      "route": (String title) =>
          Analysis(Schoolid: widget.schoolId, title: title),
    },
    {
      "title": "Announcement",
      "image": "assets/images/anno.png",
      "route": (String title) =>
          Announcement(Schoolid: widget.schoolId, title: title),
    },
    {
      "title": "Events",
      "image": "assets/images/Event.png",
      "route": (String title) =>
          Event(SchoolId: widget.schoolId, Title: title),
    },
    {
      "title": "Notice",
      "image": "assets/images/notice.png",
      "route": (String title) => Notice(Schoolid: widget.schoolId),
    },
    {
      "title": "Gallery",
      "image": "assets/images/sum.png",
      "route": (String title) =>
          Gallery(SchoolId: widget.schoolId, Title: title),
    },
    {
      "title": "Home Work",
      "image": "assets/images/work.png",
      "route": (String title) =>
          Homework(SchoolId: widget.schoolId, Title: title, userid: widget.adminid,),
    },
    {
      "title": "Time Table",
      "image": "assets/images/table.png",
      "route": (String title) =>
          TimeTable(SchoolId: widget.schoolId, Title: title),
    },
    {
      "title": "Detail's",
      "image": "assets/images/detail.png",
      "route": (String title) => Detail(
        Schoolid: widget.schoolId,
        title: title,
        userid: widget.adminid,
      ),
    },
  ];

  List<Map<String, dynamic>> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = List.from(items);
    _pageController = PageController();

    sliderRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.schoolId}/Slider");

    _loadSliderImages();
    _startAutoSlide();
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
  Future<void> pickAndUploadSliderImage(int index) async {
    final picker = ImagePicker();

    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked == null) return;

    File imageFile = File(picked.path);

    // ⬆️ Upload to Cloudinary
    final uri =
    Uri.parse("https://api.cloudinary.com/v1_1/dmpqvjpes/image/upload");

    var request = http.MultipartRequest("POST", uri);

    request.fields["upload_preset"] = "Smart School";
    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = jsonDecode(resStr);

      final imageUrl = data["secure_url"];

      // ⬇️ Save URL to Firebase
      await sliderRef.child("img${index + 1}").set(imageUrl);
    } else {
      debugPrint("Cloudinary upload failed");
    }
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
          return GestureDetector(

              onTap: () {
                pickAndUploadSliderImage(index); // 🔥 CLICK ACTION
              },

            child: Container(
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
            ),
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
                          Image.asset(
                            item["image"],
                            width: width < 360 ? 45 : 60, // ✅ responsive
                            height: width < 360 ? 45 : 60,
                            color: isPressed ? Colors.white : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item["title"],
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isPressed
                                  ? Colors.white
                                  : Colors.deepPurple,
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

class Detail extends StatefulWidget {
  final String Schoolid;
  final String title;
  final String userid;

  const Detail({
    super.key,
    required this.Schoolid,
    required this.title,
    required this.userid,
  });

  @override
  State<Detail> createState() => _Detail();
}


class _Detail extends State<Detail> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ✅ responsive card size
    final double cardSize = width < 360
        ? 120
        : width < 600
        ? 140
        : 160;

    final double imageSize = cardSize * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,

                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Teacherdetail(
                            Schoolid: widget.Schoolid,
                            title: "Teacher's Detail",
                            userid: widget.userid,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: cardSize,
                      width: cardSize,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/teachers.png",
                              width: imageSize,
                              height: imageSize,
                              color: isPressed ? Colors.white : null,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Teacher's",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Studentdetail(
                            Schoolid: widget.Schoolid,
                            title: "Student's Detail",
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: cardSize,
                      width: cardSize,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/students.png",
                              width: imageSize,
                              height: imageSize,
                              color: isPressed ? Colors.white : null,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Student's",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Teacherdetail extends StatefulWidget {
  final String Schoolid;
  final String title;
  final String userid;

  const Teacherdetail({
    super.key,
    required this.Schoolid,
    required this.title,
    required this.userid,
  });

  @override
  State<Teacherdetail> createState() => _Teacherdetail();
}

class _Teacherdetail extends State<Teacherdetail> {
  List<Map<String, dynamic>> students = [];
  bool isFilterApplied = false;

  String? medium;
  String? gender;

  late DatabaseReference ref;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> genders = ["Male", "Female"];

  @override
  void initState() {
    super.initState();
    applyFilter();
  }

  Future<void> applyFilter() async {
    ref = FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Teacher");

    final snapshot = await ref.get();
    students.clear();

    if (!snapshot.exists) {
      setState(() {});
      return;
    }

    final Map data = Map.from(snapshot.value as Map);

    data.forEach((mediumkey, mediumvalue) {
      if (medium != null && mediumkey != medium) return;
      (mediumvalue as Map).forEach((genderkey, gendervalue) {
        if (gender != null && genderkey != gender) return;
        final studentsMap =
        Map<String, dynamic>.from(gendervalue['students']);
        studentsMap.forEach((id, student) {
          students.add(student);
        });
      });
    });

    setState(() {
      isFilterApplied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ✅ responsive grid columns
    int filterColumns = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.black,
      ),


      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 FILTER SECTION
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: filterColumns, // responsive
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: MediaQuery.of(context).size.width < 360
                        ? 2
                        : 2.2,
                    children: [
                      /// Medium Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: "Medium",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: medium,
                        items: mediums
                            .map(
                              (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() => medium = value);
                        },
                      ),

                      /// Gender Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: "Gender",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: gender,
                        items: genders
                            .map(
                              (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() => gender = value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// 🔍 SEARCH BUTTON (OUTSIDE GRID)
                  SizedBox(
                    height: 42,
                    width: 180,
                    child: ElevatedButton(
                      onPressed: applyFilter,
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: const StadiumBorder(), // pill shape
                      ).copyWith(
                        backgroundColor:
                        MaterialStateProperty.resolveWith<Color>(
                              (states) => states.contains(MaterialState.pressed)
                              ? Colors.deepPurple
                              : Colors.white,
                        ),
                        foregroundColor:
                        MaterialStateProperty.resolveWith<Color>(
                              (states) => states.contains(MaterialState.pressed)
                              ? Colors.black
                              : Colors.deepPurple,
                        ),
                      ),
                      child: const Text("Search"),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 TEACHER LIST
            Expanded(
              child: StreamBuilder(
                stream: ref.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text("No Teacher's Found"),
                    );
                  }

                  Map data = snapshot.data!.snapshot.value as Map;

                  List users = data.entries.map((e) {
                    return {
                      "key": e.key,
                      ...e.value,
                    };
                  }).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onLongPress: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Accountpage(
                                SchoolId: users[index]["schoolId"],
                                Teacherid: users[index]["key"],
                                onlyview: true, title: "Details",
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.deepPurple,
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => message(
                                      Schoolid: widget.Schoolid,
                                      userid: users[index]["key"],
                                      user: "teacher",
                                    ),
                                  ),
                                );
                              },
                            ),
                            title: Text(users[index]["name"] ?? ""),
                            subtitle: Text(users[index]["email"] ?? ""),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )

    );
  }
}

class Studentdetail extends StatefulWidget {
  final String Schoolid;
  final String title;

  const Studentdetail({
    super.key,
    required this.Schoolid,
    required this.title,
  });

  @override
  State<Studentdetail> createState() => _Studentdetail();
}

class _Studentdetail extends State<Studentdetail> {
  List<Map<String, dynamic>> students = [];
  bool isFilterApplied = false;

  String? medium;
  String? std;
  String? gender;
  String? devision;

  late DatabaseReference ref;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> genders = ["Male", "Female"];
  final List<String> stds = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"];
  final List<String> devisions = ["A", "B", "C", "D", "E", "F", "G", "H"];

  @override
  void initState() {
    super.initState();
    applyFilter();
  }

  // ✅ APPLY FILTER
  Future<void> applyFilter() async {
    ref = FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Student");

    final snapshot = await ref.get();
    students.clear();

    if (!snapshot.exists) {
      setState(() {});
      return;
    }

    final Map data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((key, value) {
      final student = Map<String, dynamic>.from(value);

      if (medium != null && student['medium'] != medium) return;
      if (std != null && student['standard'] != std) return;
      if (devision != null && student['division'] != devision) return;
      if (gender != null && student['gender'] != gender) return;

      students.add({
        "key": key,
        ...student,
      });
    });

    setState(() {
      isFilterApplied = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;

          if (constraints.maxWidth >= 900) {
            crossAxisCount = 4; // Desktop/Web
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 3; // Tablet
          }

          return Column(
            children: [

              /// 🔹 FILTER SECTION
              Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [

                    /// 🔸 FILTER GRID
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 15,
                      childAspectRatio: 2.5,
                      children: [

                        /// Medium
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Medium",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: medium,
                          items: mediums
                              .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => medium = value);
                          },
                        ),

                        /// Std
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Std",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: std,
                          items: stds
                              .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => std = value);
                          },
                        ),

                        /// Division
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Div",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: devision,
                          items: devisions
                              .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => devision = value);
                          },
                        ),

                        /// Gender
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Gender",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: gender,
                          items: genders
                              .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => gender = value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// 🔍 SEARCH BUTTON (OUTSIDE GRID)
                    SizedBox(
                      height: 42,
                      width: 180,
                      child: ElevatedButton(
                        onPressed: applyFilter,
                        style: ElevatedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: const StadiumBorder(),
                        ).copyWith(
                          backgroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                                (states) => states.contains(MaterialState.pressed)
                                ? Colors.deepPurple
                                : Colors.white,
                          ),
                          foregroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                                (states) => states.contains(MaterialState.pressed)
                                ? Colors.black
                                : Colors.deepPurple,
                          ),
                        ),
                        child: const Text("Search"),
                      ),
                    ),
                  ],
                ),
              ),

              /// 🔹 STUDENT LIST
              Expanded(
                child: StreamBuilder(
                  stream: ref.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text("No Student's Found"),
                      );
                    }



                    List users = students;

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onLongPress: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>studentAccountpage(
                                  SchoolId: users[index]["schoolId"],
                                  Teacherid: users[index]["key"],
                                  onlyview: true, title: "Detail's",
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.deepPurple),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => message(
                                            Schoolid: widget.Schoolid,
                                            userid: users[index]["key"],
                                            user: "student",
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.message,
                                        color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                              title: Text(users[index]["name"] ?? ""),
                              subtitle: Text(users[index]["email"] ?? ""),
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

class Announcement extends StatefulWidget {
  final String Schoolid;
  final String title;

  const Announcement({
    super.key,
    required this.Schoolid,
    required this.title,
  });

  @override
  State<Announcement> createState() => _Announcement();
}
class _Announcement extends State<Announcement> {
  late DatabaseReference view;
  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    view = FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Announcement");
  }

  void writenotice(
      BuildContext context, bool update, String key, String oldText) {
    TextEditingController noticeController =
    TextEditingController(text: update ? oldText : "");

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth =
            constraints.maxWidth > 600 ? 600 : constraints.maxWidth * 0.9;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                titlePadding: EdgeInsets.zero,
                title: Container(
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: const Center(
                    child: Text(
                      "Announcement",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                content: SizedBox(
                  width: dialogWidth,
                  child: TextField(
                    controller: noticeController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write Announcement here...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () {
                      senddata(noticeController, update, key);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> senddata(
      TextEditingController controller, bool update, String key) async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write a Announcement"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (update) {
      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Announcement/$key");

      await ref.update({
        "Announcement": controller.text.trim(),
        "DateTime": DateTime.now().toString(),
      });
    } else {
      ref = FirebaseDatabase.instance
          .ref("smart/user1/${widget.Schoolid}/Announcement");

      await ref.push().set({
        "Announcement": controller.text.trim(),
        "DateTime": DateTime.now().toString(),
      });
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Announcement")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });

  }

  void delete(String key) {
    DatabaseReference deleteref = FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Announcement/$key");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content:
        const Text("Are you sure you want to delete this Announcement?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteref.remove();
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
          double buttonWidth =
          constraints.maxWidth > 500 ? 300 : constraints.maxWidth * 0.8;

          return Column(
            children: [
              const SizedBox(height: 20),

              /// 🔹 ADD BUTTON
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      writenotice(context, false, "", "");
                    },
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    child: const Text("Add Announcement"),
                  ),
                ),
              ),

              /// 🔹 LIST
              Expanded(
                child: StreamBuilder(
                  stream: view.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Error loading Announcement"));
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(
                          child: Text("No Announcement Found"));
                    }

                    Map data = snapshot.data!.snapshot.value as Map;

                    List announcements = data.entries
                        .map((e) => {"key": e.key, ...e.value})
                        .toList();

                    return ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final dt = DateTime.tryParse(
                          announcements[index]["DateTime"] ?? "",
                        ) ??
                            DateTime.now();

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(
                              "Announcement :- ${announcements[index]["Announcement"] ?? ""}",
                            ),
                            subtitle: Text(
                              "Time :- ${DateFormat('hh:mm a').format(dt)}",
                            ),

                            leading: Icon(Icons.campaign),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.deepPurple),
                                  onPressed: () {
                                    writenotice(
                                      context,
                                      true,
                                      announcements[index]["key"],
                                      announcements[index]["Announcement"],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    delete(announcements[index]["key"]);
                                  },
                                ),
                              ],
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

class Analysis extends StatefulWidget {
  final String title;
  final String Schoolid;

  const Analysis({super.key, required this.title, required this.Schoolid});

  @override
  State<Analysis> createState() => _Analysis();
}

class _Analysis extends State<Analysis> {
  int totalTeachers = 0;
  int totalStudent = 0;

  int totalmarathiteacher = 0;
  int totalgujrathiteacher = 0;
  int totalenglishteacher = 0;
  int totalhinditeacher = 0;

  int totalmarathistudent = 0;
  int totalgujrathistudent = 0;
  int totalenglishstudent = 0;
  int totalhindistudent = 0;

  @override
  void initState() {
    super.initState();
    loadTeacherCounts();
    loadStudentCounts();
  }

  // ================== TEACHER COUNT ==================
  Future<void> loadTeacherCounts() async {
    DatabaseReference ref =
    FirebaseDatabase.instance.ref("smart/user1/${widget.Schoolid}/Teacher");

    final snap = await ref.get();

    int total = 0;
    int marathi = 0;
    int english = 0;
    int hindi = 0;
    int gujrathi = 0;

    if (snap.exists && snap.value is Map) {
      final data = snap.value as Map;

      data.forEach((key, value) {
        total++;

        String medium = value["medium"] ?? "";

        if (medium == "Marathi") {
          marathi++;
        } else if (medium == "English") {
          english++;
        } else if (medium == "Hindi") {
          hindi++;
        } else if (medium == "Gujrathi") {
          gujrathi++;
        }
      });
    }

    setState(() {
      totalTeachers = total;
      totalmarathiteacher = marathi;
      totalenglishteacher = english;
      totalhinditeacher = hindi;
      totalgujrathiteacher = gujrathi;
    });
  }

  // ================== STUDENT COUNT ==================
  Future<void> loadStudentCounts() async {
    DatabaseReference ref =
    FirebaseDatabase.instance.ref("smart/user1/${widget.Schoolid}/Student");

    final snap = await ref.get();

    int total = 0;
    int marathi = 0;
    int english = 0;
    int hindi = 0;
    int gujrathi = 0;

    if (snap.exists && snap.value is Map) {
      final Map data = snap.value as Map;

      data.forEach((key, value) {
        total++;

        String medium = value["medium"] ?? "";

        if (medium == "Marathi") marathi++;
        if (medium == "English") english++;
        if (medium == "Hindi") hindi++;
        if (medium == "Gujrathi") gujrathi++;
      });
    }

    setState(() {
      totalStudent = total;
      totalmarathistudent = marathi;
      totalenglishstudent = english;
      totalhindistudent = hindi;
      totalgujrathistudent = gujrathi;
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
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadTeacherCounts();
          await loadStudentCounts();
        },

        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double maxCardWidth = 250; // maximum width of each card

              return GridView.builder(
                itemCount: 10, // total cards
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCardWidth,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9, // adjust height dynamically
                ),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return cardUI("Total Teachers", totalTeachers);
                    case 1:
                      return cardUI("Total Students", totalStudent);
                    case 2:
                      return cardUI("Total Teachers Of Marathi Medium", totalmarathiteacher);
                    case 3:
                      return cardUI("Total Teachers Of English Medium", totalenglishteacher);
                    case 4:
                      return cardUI("Total Teachers Of Gujrathi Medium", totalgujrathiteacher);
                    case 5:
                      return cardUI("Total Teachers Of Hindi Medium", totalhinditeacher);
                    case 6:
                      return cardUI("Total Students Of Marathi Medium", totalmarathistudent);
                    case 7:
                      return cardUI("Total Students Of English Medium", totalenglishstudent);
                    case 8:
                      return cardUI("Total Students Of Gujrathi Medium", totalgujrathistudent);
                    case 9:
                      return cardUI("Total Students Of Hindi Medium", totalhindistudent);
                    default:
                      return const SizedBox();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class Attendens extends StatefulWidget {
   final String SchoolID;

   const Attendens({super.key, required this.SchoolID});


  @override
  _Attendens createState() => _Attendens();
}

class _Attendens extends State<Attendens> {

  List<Map<String, dynamic>> students = [];
  bool isFilterApplied = false;
  TextEditingController dateController = TextEditingController();
  DateTime? selectedDate;

  // ✅ Nullable variables
  String? medium;
  String? std;
  String? division;

  // ✅ Today's date
  String todayDate = DateTime.now().toString().split(' ')[0];
  late DatabaseReference ref;
  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> standards = ["1","2","3","4","5","6","7","8","9","10","11","12"];
  final List<String> divisions = ["A", "B", "C","D","E","F"];

  @override
  void initState() {
    super.initState();
    dateController.text = todayDate;
    applyFilter(); // load today's attendance automatically
  }

  // ✅ DROPDOWN

  // ✅ APPLY FILTER FUNCTION
  Future<void> applyFilter() async {
    if (dateController.text.isEmpty) return;

    ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolID}/Attendance/${dateController.text}",
    );

    final snapshot = await ref.get();
    students.clear();

    if (!snapshot.exists) {
      setState(() {});
      return;
    }

    final Map data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((studentId, value) {
      final student = Map<String, dynamic>.from(value);

      if (medium != null && student["medium"] != medium) return;
      if (std != null && student["standard"] != std) return;
      if (division != null && student["division"] != division) return;

      students.add({
        "id": studentId,
        ...student,
      });
    });


    setState(() {
      isFilterApplied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body:Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(5),
            child: LayoutBuilder(builder: (context, constraints) {
              double maxWidth = constraints.maxWidth;
              double itemWidth = 150; // Approx width for each dropdown/button
              int itemsPerRow = maxWidth ~/ itemWidth;

              return Wrap(
                spacing: 15,
                runSpacing: 10,
                children: [

                  SizedBox(
                    width: maxWidth / itemsPerRow - 15, // dynamic width
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: "Medium",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: medium,
                      items: mediums.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => medium = value);
                      },
                    ),
                  ),

                  SizedBox(
                    width: maxWidth / itemsPerRow - 15,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: "Standard",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: std,
                      items: standards.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => std = value);
                      },
                    ),
                  ),

                  SizedBox(
                    width: maxWidth / itemsPerRow - 15,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: "Division",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: division,
                      items: divisions.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => division = value);
                      },
                    ),
                  ),

                  SizedBox(
                    width: maxWidth / itemsPerRow - 15,
                    child: TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Select Date",
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            dateController.text =
                            "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                          });
                        }
                      },
                    ),
                  ),

                  SizedBox(
                    width: maxWidth / itemsPerRow - 15,
                    child: ElevatedButton(
                      onPressed: applyFilter,
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => states.contains(MaterialState.pressed)
                                ? Colors.deepPurple
                                : Colors.white),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => states.contains(MaterialState.pressed)
                                ? Colors.black
                                : Colors.deepPurple),
                      ),
                      child: const Text("Search"),
                    ),
                  ),
                ],
              );
            }),
          ),


          /// 🔹 DATA LIST (BELOW DATE)
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text("No Attendance Found"))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                String status = students[index]["status"] ?? "";

                Color statusColor =
                status.toLowerCase() == "present"
                    ? Colors.green
                    : Colors.red;

                return InkWell(
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.deepPurple),
                      title: Text(students[index]["name"] ?? "No Name"),
                      subtitle: Text(
                        "Roll No: ${students[index]["rollNo"]}\nTaken by: ${students[index]["takenby"]}",
                      ),
                      trailing: Icon(Icons.circle, color: statusColor),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      )







    );
  }
}

class accountpage extends StatefulWidget {
  final String schoolId;
  final String adminid;
  final String title;
  final bool onlyview;
  const accountpage({
    super.key,
    required this.schoolId,
    required this.title,
    required this.adminid,
    required this.onlyview,
  });



  @override
  State<accountpage> createState() => _accountpageState();
}
class _accountpageState extends State<accountpage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  File? selectedImage;
  String? profileImage;

  String? selectedGender;
  String? medium;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> genders = ["Male", "Female"];

  /// 🔹 Cloudinary config


  @override
  void initState() {
    super.initState();
    loadAdminData();
    loadProfileImage();
  }

  // ================= LOAD ADMIN DATA =================
  Future<void> loadAdminData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.schoolId}/Admin/${widget.adminid}",
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
        profileImage = data['image'];
        selectedGender =
        genders.contains(data['gender']) ? data['gender'] : null;
        medium = mediums.contains(data['medium']) ? data['medium'] : null;
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
      "smart/user1/${widget.schoolId}/Admin/${widget.adminid}",
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
      "smart/user1/${widget.schoolId}/Admin/${widget.adminid}",
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
                prefixIcon: const Icon(Icons.people_alt_sharp),
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



class Notice extends StatefulWidget {
  final String Schoolid;

  const Notice({super.key, required this.Schoolid});

  @override
  State<Notice> createState() => _Notice();
}



class _Notice extends State<Notice> {
  String? medium;
  String? std;
  String? division;
  String? role;
  bool isTeacherSelected = false;

  late String sid;
  late DatabaseReference view;
  late DatabaseReference Ref;
  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> roles = ["Teacher", "Student"];
  final List<String> standards = [
    "1","2","3","4","5","6","7","8","9","10","11","12"
  ];
  final List<String> divisions = ["A","B","C","D","E","F"];

  @override
  void initState() {
    super.initState();
    sid = widget.Schoolid;
    view = FirebaseDatabase.instance.ref("smart/user1/$sid/Notice");
  }

  late DatabaseReference ref;

  void writenotice(BuildContext context, bool update, String key, String oldText) {



    TextEditingController noticeController =
    TextEditingController(text: update ? oldText : "");

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth > 600 ? 600 : constraints.maxWidth * 0.9;
            double dialogHeight = constraints.maxHeight > 500 ? 320 : constraints.maxHeight * 0.7;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Container(
                  height: 40,
                  color: Colors.deepPurple,
                  child: const Center(
                    child: Text("Notice", style: TextStyle(color: Colors.white)),
                  ),
                ),
                content: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Role",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          value: role,
                          items: roles.map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              role = value;

                              // ✅ THIS LINE CONTROLS DISABLE / ENABLE
                              isTeacherSelected = value == "Teacher";

                              if (isTeacherSelected) {
                                std = null;
                                division = null;
                              }
                            });
                          },


                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Medium",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          value: medium,
                          items: mediums.map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          )).toList(),
                          onChanged: (value) {
                            setState(() => medium = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Standard",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          value: std,
                          items: standards.map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          )).toList(),
                          onChanged: isTeacherSelected
                              ? null
                              : (value) {
                            setState(() => std = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Division",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          value: division,
                          items: divisions.map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          )).toList(),
                          onChanged: isTeacherSelected
                              ? null
                              : (value) {
                            setState(() => division = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noticeController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: "Write notice here...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () {
                      senddata(noticeController, update, key);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> senddata(TextEditingController controller, bool update, String key) async {
    ref = FirebaseDatabase.instance.ref("smart/user1/${widget.Schoolid}/Notice");
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write a notice"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Map<String, dynamic> data = {
      "Medium": medium,
      "Standard": std,
      "Division": division,
      "role" : role,
      "Notice": controller.text.trim(),
      "DateTime": DateTime.now().toString(),
    };


    if (update == true){
      await ref.update(data);
    }
    else{
      await ref.push().set(data);
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.Schoolid}/Notice")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });

  }

  void delete(String key) {
    DatabaseReference deleteref=FirebaseDatabase.instance.ref("smart/user1/${widget.Schoolid}/Notice/$key");




    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notice"),
        content: const Text("Are you sure you want to delete this notice?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await deleteref.remove();

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notice"),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => writenotice(context, false, "", ""),
              style: ElevatedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed)
                      ? Colors.deepPurple
                      : Colors.white,
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed)
                      ? Colors.black
                      : Colors.deepPurple,
                ),
              ),
              child: const Text("Add Notice"),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: view.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading notice"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No Notice Found"));
                }

                Map data = snapshot.data!.snapshot.value as Map;
                List notes = data.entries.map((e) => {
                  "key": e.key,
                  ...e.value,
                }).toList();

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final dt = notes[index]["DateTime"] != null
                        ? DateTime.parse(notes[index]["DateTime"])
                        : DateTime.now();

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("Notice :- ${notes[index]["Notice"] ?? ""}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                                Text("Medium :- ${notes[index]["Medium"] ?? ""}"),
                                Text("Standard :- ${notes[index]["Standard"] ?? ""}"),




                                Text("Division :- ${notes[index]["Division"] ?? ""}"),
                                Text("Date :- ${DateFormat('dd MMM yyyy').format(dt)}"),


                            Text("Time :- ${DateFormat('HH:mm').format(dt)}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepPurple),
                              onPressed: () => writenotice(
                                context,
                                true,
                                notes[index]["key"],
                                notes[index]["Notice"] ?? "",
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => delete(notes[index]["key"],),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event extends StatefulWidget {
  final String SchoolId;
  final String Title;
  const Event({super.key, required this.SchoolId, required this.Title});

  @override
  State<Event> createState() => _Event();
}

class _Event extends State<Event> {
  TextEditingController EventController = TextEditingController();
  TextEditingController Eventdescription = TextEditingController();
  TextEditingController EventDate = TextEditingController();

  late DatabaseReference view;
  late String sid;

  @override
  void initState() {
    super.initState();
    sid = widget.SchoolId;
    view = FirebaseDatabase.instance.ref("smart/user1/$sid/Event");
  }

  // ✅ ADD / UPDATE EVENT
  Future<void> addev(bool update, String key) async {
    final DatabaseReference baseRef =
    FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Event");

    Map<String, dynamic> data = {
      "Title": EventController.text.trim(),
      "Description": Eventdescription.text.trim(),
      "Date": EventDate.text.trim(),
      "DateTime": DateTime.now().toIso8601String(),
    };

    if (update) {
      await baseRef.child(key).update(data);
    } else {
      await baseRef.push().set(data);
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Event")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });

    EventController.clear();
    Eventdescription.clear();
    EventDate.clear();
  }

  void delete(String key) {
    DatabaseReference deleteref =
    FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Event/$key");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteref.remove();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void addEvent(bool update, String key) {
    if (update) {
      // pre-fill data if updating
    }

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth =
            constraints.maxWidth > 600 ? 600 : constraints.maxWidth * 0.9;
            double dialogHeight =
            constraints.maxHeight > 400 ? 280 : constraints.maxHeight * 0.6;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Container(
                  height: 40,
                  color: Colors.deepPurple,
                  child: const Center(
                    child:
                    Text("Event", style: TextStyle(color: Colors.white)),
                  ),
                ),
                content: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextFormField(
                          controller: EventController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Title Of Event",
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: Eventdescription,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Event Description",
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: EventDate,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "DD/MM/YY",
                            prefixIcon: Icon(Icons.date_range),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    onPressed: () {
                      addev(update, key);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                addEvent(false, "");
              },
              style: ElevatedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed)
                      ? Colors.deepPurple
                      : Colors.white,
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed)
                      ? Colors.black
                      : Colors.deepPurple,
                ),
              ),
              child: const Text("Add Events"),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: view.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading events"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No events found"));
                }

                final rawData = snapshot.data!.snapshot.value;
                if (rawData is! Map) {
                  return const Center(child: Text("Invalid data format"));
                }

                final Map<dynamic, dynamic> data = rawData;
                final List<Map<String, dynamic>> events = data.entries
                    .where((e) => e.value is Map)
                    .map((e) => {
                  "key": e.key,
                  ...Map<String, dynamic>.from(e.value),
                })
                    .toList();

                if (events.isEmpty) {
                  return const Center(child: Text("No events available"));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("Title :- ${event["Title"] ?? ""}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Description :- ${event["Description"] ?? ""}"),
                            Text("Date :- ${event["Date"] ?? ""}"),

                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.deepPurple),
                              onPressed: () {
                                addEvent(true, event["key"]);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                delete(event["key"]);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Gallery extends StatefulWidget {
  final String SchoolId;
  final String Title;

  const Gallery({super.key, required this.SchoolId, required this.Title});

  @override
  State<Gallery> createState() => _Gallery();
}
class _Gallery extends State<Gallery> {
  String? selectedCardKey; // track long-pressed card

  String formattedDate =
      "${DateTime.now().day.toString().padLeft(2, '0')}-"
      "${DateTime.now().month.toString().padLeft(2, '0')}-"
      "${DateTime.now().year}";

  File? selectedImage;
  TextEditingController titleController = TextEditingController();

  late DatabaseReference view =
  FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Gallery");

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;

    final uri =
    Uri.parse("https://api.cloudinary.com/v1_1/dmpqvjpes/image/upload");

    var request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = "Smart School"
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        selectedImage!.path,
      ));

    var response = await request.send();

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> saveGalleryData(String sid) async {
    if (titleController.text.isEmpty || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title & Image required")),
      );
      return;
    }

    String? imageUrl = await uploadImage();
    if (imageUrl == null) return;

    DatabaseReference ref =
    FirebaseDatabase.instance.ref("smart/user1/$sid/Gallery").push();

    await ref.set({
      "title": titleController.text.trim(),
      "image": imageUrl,
      "createdDate": formattedDate,
    });
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
    setState(() {
      titleController.clear();
      selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gallery item added")),
    );
  }

  Future<void> updateSection(String firebaseKey) async {
    Map<String, dynamic> updateData = {
      "title": titleController.text.trim(),
      "createdDate": formattedDate,
    };

    if (selectedImage != null) {
      String? imageUrl = await uploadImage();
      if (imageUrl != null) {
        updateData["image"] = imageUrl;
      }
    }

    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery/$firebaseKey")
        .update(updateData);

    titleController.clear();
    selectedImage = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Section updated")),
    );
  }

  Future<void> deleteSection(String firebaseKey) async {
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery/$firebaseKey")
        .remove();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image deleted")),
    );
  }

  void showDeleteDialog(String firebaseKey) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Section"),
        content: const Text("Are you sure you want to delete this Section?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteSection(firebaseKey);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void addOrUpdateSection(
      BuildContext context, String sid, bool update, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(builder: (context, constraints) {
          double dialogWidth =
          constraints.maxWidth > 600 ? 600 : constraints.maxWidth * 0.9;
          double dialogHeight =
          constraints.maxHeight > 300 ? 200 : constraints.maxHeight * 0.6;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Container(
                height: 40,
                color: Colors.deepPurple,
                child: const Center(
                  child:
                  Text("Add Section", style: TextStyle(color: Colors.white)),
                ),
              ),
              content: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: "Write Section Title here...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text("Pick Image For Section"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!update) {
                      await saveGalleryData(widget.SchoolId);
                    } else {
                      await updateSection(key);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                addOrUpdateSection(context, widget.SchoolId, false, "");
              },
              style: ElevatedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) =>
                  states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white,
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) =>
                  states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple,
                ),
              ),
              child: const Text("Add Section"),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: view.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading user"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No user Found"));
                }

                Map data = snapshot.data!.snapshot.value as Map;
                List items = data.entries
                    .map((e) => {
                  "key": e.key,
                  ...e.value,
                })
                    .toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 800
                        ? 4
                        : constraints.maxWidth > 500
                        ? 3
                        : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageUploadPage(SchoolId: widget.SchoolId, Title: 'Gallery', keye: item["key"],),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      item["image"],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, size: 50);
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item["title"] ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                          onPressed: () {
                                            addOrUpdateSection(context, widget.SchoolId, true, item['key']);
                                          }),
                                      IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            showDeleteDialog(item['key']);
                                          }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  final String Schoolid;
  final String userid;
  final String user;

  const NotificationPage(
      {super.key,
        required this.Schoolid,
        required this.userid,
        required this.user});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}
class _NotificationPageState extends State<NotificationPage> {
  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    _checkUser();
    updateSeen();
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.Schoolid}/Notification",
      widget.userid,
    );
  }

  void _checkUser() {
    if (widget.user.toLowerCase() == "admin" ||widget.user.toLowerCase() == "school" ) {

      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Notification");
    } else if (widget.user.toLowerCase() == "teacher") {
      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Teacher/${widget.userid}/Notification");
    }

    else if (widget.user.toLowerCase() == "student") {
      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Student/${widget.userid}/Notification");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Notification"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No notifications found"));
          }

          Map data = snapshot.data!.snapshot.value as Map;
          List items = data.entries
              .map((e) => {
            "key": e.key,
            ...e.value,
          })
              .toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final dt = items[index]["DateTime"] != null
                      ? DateTime.parse(items[index]["DateTime"])
                      : DateTime.now();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.message, color: Colors.deepPurple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Message: ${items[index]["Message"] ?? ""}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Time: ${DateFormat('HH:mm').format(dt)}",
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  Future<void> downloadImage(BuildContext context, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      final directory = await getExternalStorageDirectory();
      final downloadDir = Directory("${directory!.path}/Download");

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath =
          "${downloadDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image saved to Downloads")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download image")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () =>  downloadImage(context, imageUrl)

    ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white, size: 60),
          ),
        ),
      ),
    );
  }
}
class ImageUploadPage extends StatefulWidget {
  final String SchoolId;
  final String Title;
  final String keye;

  const ImageUploadPage({
    super.key,
    required this.SchoolId,
    required this.Title,
    required this.keye,
  });

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}
class _ImageUploadPageState extends State<ImageUploadPage> {
  String formattedDate =
      "${DateTime.now().day.toString().padLeft(2, '0')}-"
      "${DateTime.now().month.toString().padLeft(2, '0')}-"
      "${DateTime.now().year}";

  File? selectedImage;

  late DatabaseReference view;

  @override
  void initState() {
    super.initState();
    view = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery/${widget.keye}");
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // ---------------- CLOUDINARY UPLOAD ----------------
  Future<Map<String, String>?> uploadImage() async {
    if (selectedImage == null) return null;

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dmpqvjpes/image/upload");
    String publicId = "gallery/${widget.SchoolId}/${DateTime.now().millisecondsSinceEpoch}";

    var request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = "Smart School"
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', selectedImage!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);
      return {"imageUrl": data['secure_url'], "publicId": data['public_id']};
    } else {
      return null;
    }
  }

  // ---------------- DELETE IMAGE ----------------
  Future<void> deleteImage(String firebaseKey, String publicId) async {
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery/${widget.keye}/$firebaseKey")
        .remove();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image deleted")),
    );
  }

  void showDeleteDialog(String firebaseKey, String publicId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteImage(firebaseKey, publicId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------- SAVE IMAGE ----------------
  Future<void> saveGalleryData(String sid, String keyid) async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image required")),
      );
      return;
    }

    final uploadResult = await uploadImage();
    if (uploadResult == null) return;

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("smart/user1/$sid/Gallery/$keyid")
        .push();

    await ref.set({
      "image": uploadResult["imageUrl"],
      "publicId": uploadResult["publicId"],
      "createdDate": formattedDate,
    });
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
    setState(() {
      selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gallery item added")),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await pickImage();
                if (selectedImage != null) {
                  await saveGalleryData(widget.SchoolId, widget.keye);
                }
              },
              style: ElevatedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white,
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple,
                ),
              ),
              child: const Text("Add Images"),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream: view.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading gallery"));
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No images found"));

                final rawData = snapshot.data!.snapshot.value;
                if (rawData is! Map) return const Center(child: Text("Invalid gallery data"));

                List<Map<String, dynamic>> items = [];
                rawData.forEach((key, value) {
                  if (value is Map) {
                    items.add({
                      "key": key,
                      "image": value["image"],
                      "publicId": value["publicId"],
                      "createdDate": value["createdDate"],
                    });
                  }
                });

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return InkWell(
                          onLongPress: () => showDeleteDialog(item["key"], item["publicId"]),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImagePage(
                                  imageUrl: item["image"],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      item["image"],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    item["createdDate"] ?? "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Homework extends StatefulWidget {
  final String SchoolId;
  final String Title;
  final String userid;
  const Homework({super.key, required this.SchoolId, required this.Title,required this.userid,});

  @override
  State<Homework> createState() => _HomeworkState();
}
class _HomeworkState extends State<Homework> {
  TextEditingController homework = TextEditingController();
  String? medium;
  String? std;
  String? div;
  late DatabaseReference show;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> standards = ["1","2","3","4","5","6","7","8","9","10","11","12"];
  final List<String> divisions = ["A", "B", "C","D","E","F"];

  @override
  void initState() {
    super.initState();
    show = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Homework");
  }

  void addHomework(bool update, String key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? localMedium = update ? medium : null;
        String? localStd = update ? std : null;
        String? localDiv = update ? div : null;
        TextEditingController localHomework =
        TextEditingController(text: update ? homework.text : "");

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Container(
                color: Colors.deepPurple,
                  height: 40,
                  child: Center(
                      child: const Text("Home Work",style: TextStyle(color: Colors.white),))
              ),

              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: localMedium,
                      decoration: InputDecoration(
                        hintText: "Medium",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: mediums
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => localMedium = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: localStd,
                      decoration: InputDecoration(
                        hintText: "Standard",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: standards
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => localStd = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: localDiv,
                      decoration: InputDecoration(
                        hintText: "Division",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: divisions
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => localDiv = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: localHomework,
                      maxLines: 5,
                      decoration: InputDecoration(
                          hintText: "Homework",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                    foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (localHomework.text.trim().isEmpty) return;

                    await FirebaseDatabase.instance
                        .ref("smart/user1/${widget.SchoolId}/Homework")
                        .child(update ? key : FirebaseDatabase.instance
                        .ref()
                        .push()
                        .key!)
                        .set({
                      "Medium": localMedium,
                      "Standard": localStd,
                      "Division": localDiv,
                      "Home Work": localHomework.text.trim(),
                      "DateTime": DateTime.now().toIso8601String(),
                    });

                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                    foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
                  ),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> senddata(TextEditingController controller, bool update, String key) async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a Home Work"), backgroundColor: Colors.red),
      );
      return;
    }

    DatabaseReference ref;
    if (update) {
      ref = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Homework/$key");
      await ref.update({
        "Medium": medium,
        "Standard": std,
        "Division": div,
        "Home Work": controller.text.trim(),
        "DateTime": DateTime.now().toString(),
      });
    } else {
      ref = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Homework");
      await ref.push().set({
        "Medium": medium,
        "Standard": std,
        "Division": div,
        "Home Work": controller.text.trim(),
        "DateTime": DateTime.now().toString(),
      });
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Homework")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
  }

  void delete(String key) {
    DatabaseReference deleteref = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Homework/$key");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Home Work"),
        content: const Text("Are you sure you want to delete this Home Work?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteref.remove();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Title),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  medium = null;
                  std = null;
                  div = null;
                  homework.clear();
                });
                addHomework(false, "");
              },

              style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
              ),
              child: const Text("Add"),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: show.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading user"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No Homeworks Found"));

                Map data = snapshot.data!.snapshot.value as Map;
                List homeworkList = data.entries.map((e) => {"key": e.key, ...e.value}).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView.builder(
                      itemCount: homeworkList.length,
                      itemBuilder: (context, index) {
                        final hw = homeworkList[index];
                        final DateTime dt =
                            DateTime.tryParse(hw["DateTime"] ?? "") ?? DateTime.now();

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Text("Home Work: ${hw["Home Work"] ?? ""}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                    Text("Medium: ${hw["Medium"] ?? ""}"),
                                    Text("Standard: ${hw["Standard"] ?? ""}"),

                                    Text("Division: ${hw["Division"] ?? ""}"),
                                    Text("Date: ${DateFormat('dd MMM yyyy').format(dt)}"),

                                Text("Time: ${DateFormat('HH:mm').format(dt)}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () {
                                    setState(() {
                                      medium = hw["Medium"];
                                      std = hw["Standard"];
                                      div = hw["Division"];
                                      homework.text = hw["Home Work"] ?? "";
                                    });
                                    addHomework(true, hw["key"]);
                                  },

                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => delete(hw["key"]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TimeTable extends StatefulWidget {
  final String SchoolId;
  final String Title;

  const TimeTable({super.key, required this.SchoolId, required this.Title});

  @override
  State<TimeTable> createState() => _TimeTableState();
}
class _TimeTableState extends State<TimeTable> {
  TextEditingController timetable = TextEditingController();
  String? medium;
  String? std;
  String? div;
  late DatabaseReference show;
  File? selectedImage;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> standards = ["1","2","3","4","5","6","7","8","9","10","11","12"];
  final List<String> divisions = ["A", "B", "C","D","E","F"];

  @override
  void initState() {
    super.initState();
    show = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/TimeTable");
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<Map<String, String>?> uploadImage() async {
    if (selectedImage == null) return null;

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dmpqvjpes/image/upload");
    String publicId = "gallery/${widget.SchoolId}/${DateTime.now().millisecondsSinceEpoch}";

    var request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = "Smart School"
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', selectedImage!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);
      return {"imageUrl": data['secure_url'], "publicId": data['public_id']};
    } else {
      return null;
    }
  }

  Future<void> downloadTimeTable(String imageUrl) async {
    final Uri url = Uri.parse(imageUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to download Time Table")),
      );
    }
  }

  Future<void> senddata(TextEditingController controller, bool update, String key) async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image required")),
      );
      return;
    }

    final imageUrl = await uploadImage();
    if (imageUrl == null) return;

    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a Time Table"), backgroundColor: Colors.red),
      );
      return;
    }

    DatabaseReference ref;
    if (update) {
      ref = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/TimeTable/$key");
      await ref.update({
        "Medium": medium,
        "Standard": std,
        "Division": div,
        "image": imageUrl["imageUrl"],
        "publicId": imageUrl["publicId"],
        "Time Table": controller.text.trim(),
        "DateTime": DateTime.now().toString(),
      });
    } else {
      ref = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/TimeTable");
      await ref.push().set({
        "Medium": medium,
        "Standard": std,
        "Division": div,
        "Time Table": controller.text.trim(),
        "image": imageUrl["imageUrl"],
        "publicId": imageUrl["publicId"],
        "DateTime": DateTime.now().toString(),
      });
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/TimeTable")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
    setState(() => selectedImage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Time Table saved")),
    );
  }

  void addTimetable(bool update, String key) {
    String? localMedium = update && mediums.contains(medium) ? medium : null;
    String? localStd = update && standards.contains(std) ? std : null;
    String? localDiv = update && divisions.contains(div) ? div : null;

    TextEditingController localController =
    TextEditingController(text: update ? timetable.text : "");

    File? localImage = selectedImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Time Table"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: localMedium,
                      decoration: const InputDecoration(
                        hintText: "Medium",
                        border: OutlineInputBorder(),
                      ),
                      items: mediums
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => localMedium = v),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: localStd,
                      decoration: const InputDecoration(
                        hintText: "Standard",
                        border: OutlineInputBorder(),
                      ),
                      items: standards
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => localStd = v),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: localDiv,
                      decoration: const InputDecoration(
                        hintText: "Division",
                        border: OutlineInputBorder(),
                      ),
                      items: divisions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => localDiv = v),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: localController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Time Table Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setDialogState(() {
                            localImage = File(picked.path);
                          });
                        }
                      },
                      child: Text(localImage == null
                          ? "Pick Time Table Image"
                          : "Image Selected"),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                    foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (localMedium == null ||
                        localStd == null ||
                        localDiv == null ||
                        localController.text.trim().isEmpty ||
                        localImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("All fields required")),
                      );
                      return;
                    }

                    // copy dialog state to widget state
                    medium = localMedium;
                    std = localStd;
                    div = localDiv;
                    timetable.text = localController.text;
                    selectedImage = localImage;

                    await senddata(timetable, update, key);
                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                    foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
                  ),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> deleteFromCloudinary(String publicId) async {
    await http.post(
      Uri.parse("https://your-server.com/delete-image"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"publicId": publicId}),
    );
  }

  Future<void> deleteImage(String firebaseKey, String publicId) async {
    await deleteFromCloudinary(publicId);
    await FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/TimeTable/$firebaseKey").remove();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image deleted")));
  }

  void showDeleteDialog(String firebaseKey, String publicId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteImage(firebaseKey, publicId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Title),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => addTimetable(false, ""),
              style: ElevatedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple)).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.deepPurple : Colors.white),
                foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? Colors.black : Colors.deepPurple),
              ),
              child: const Text("Add"),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: show.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading Time Table"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No Time Table Found"));

                Map data = snapshot.data!.snapshot.value as Map;
                List timetableList = data.entries.map((e) => {"key": e.key, ...e.value}).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView.builder(
                      itemCount: timetableList.length,
                      itemBuilder: (context, index) {
                        final tt = timetableList[index];
                        final dt = DateTime.parse(tt["DateTime"]);

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Description: ${tt["Time Table"] ?? ""}"),
                                const SizedBox(height: 5),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text("Download Time Table"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => downloadTimeTable(tt["image"]),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                    Text("Medium: ${tt["Medium"] ?? ""}"),
                                    Text("Standard: ${tt["Standard"] ?? ""}"),


                                    Text("Division: ${tt["Division"] ?? ""}"),

                                Text("Time: ${DateFormat('HH:mm').format(dt)}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () => addTimetable(true, tt["key"]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => showDeleteDialog(tt["key"], tt["publicId"]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class message extends StatefulWidget {
  final String Schoolid;
  final String userid;
  final String user;
  const message({super.key, required this.Schoolid, required this.userid, required this.user});

  @override
  State<message> createState() => _MessageState();
}
class _MessageState extends State<message> {
  DatabaseReference? view;
  late DatabaseReference ref;
  late DatabaseReference deleter;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  // ================= CHECK USER & VIEW PATH =================
  void _checkUser() {
    final role = (widget.user ?? "").toLowerCase();

    if (role == "admin" || role == "school") {
      view = FirebaseDatabase.instance
          .ref("smart/user1/${widget.Schoolid}/Notification");
    } else if (role == "teacher") {
      view = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Teacher/${widget.userid}/Notification");
    } else if (role == "student") {
      view = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Student/${widget.userid}/Notification");
    } else {
      // fallback (VERY IMPORTANT)
      view = FirebaseDatabase.instance
          .ref("smart/user1/${widget.Schoolid}/Notification");
    }
  }

  // ================= WRITE MESSAGE DIALOG =================
  void writeMessage(
      BuildContext context, bool update, String? key, String? oldText) {

    final controller =
    TextEditingController(text: update ? (oldText ?? "") : "");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Message"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Write Message here...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await sendData(controller, update, key ?? "");
                Navigator.pop(ctx);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }


  // ================= SEND / UPDATE MESSAGE =================
  Future<void> sendData(
      TextEditingController controller, bool update, String key) async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write a Message"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final role = widget.user.toLowerCase();

    if (role == "admin" || role == "school") {
      ref = FirebaseDatabase.instance
          .ref("smart/user1/${widget.Schoolid}/Notification");
    } else if (role == "teacher") {
      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Teacher/${widget.userid}/Notification");
    } else {
      ref = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Student/${widget.userid}/Notification");
    }

    if (update) {
      await ref.child(key).update({
        "Message": controller.text.trim(),
        "DateTime": DateTime.now().toIso8601String(),
      });
    } else {
      await ref.push().set({
        "Message": controller.text.trim(),
        "DateTime": DateTime.now().toIso8601String(),
      });
    }
    await ref.update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ================= DELETE MESSAGE =================
  void deleteMessage(String key) {
    final role = widget.user.toLowerCase();

    if (role == "admin" || role == "school") {
      deleter = FirebaseDatabase.instance
          .ref("smart/user1/${widget.Schoolid}/Notification/$key");
    } else if (role == "teacher") {
      deleter = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Teacher/${widget.userid}/Notification/$key");
    } else {
      deleter = FirebaseDatabase.instance.ref(
          "smart/user1/${widget.Schoolid}/Student/${widget.userid}/Notification/$key");
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await deleter.remove();
              Navigator.pop(context);
            },
            child:
            const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              writeMessage(context, false, null, null);
            },
            child: const Text("Send Message"),
          ),
          Expanded(
            child: view == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder(
              stream: view!.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error"));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No Messages"));
                }

                final Map data =
                snapshot.data!.snapshot.value as Map;

                final List items = data.entries
                    .map((e) => {
                  "key": e.key,
                  ...Map<String, dynamic>.from(e.value)
                })
                    .toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final String message =
                        items[index]["Message"] ?? "";

                    final DateTime dt = DateTime.tryParse(
                        items[index]["DateTime"] ?? "") ??
                        DateTime.now();

                    return InkWell(
                      onLongPress: () => deleteMessage(items[index]["key"]),

                      child: Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: const Icon(Icons.message,
                              color: Colors.deepPurple),

                          title: Text("Message :- $message"),
                          subtitle: Text(
                              "Time :- ${DateFormat('HH:mm').format(dt)}"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

