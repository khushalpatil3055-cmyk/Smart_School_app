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
import 'package:url_launcher/url_launcher.dart';

import 'Adminscreen.dart';
import 'Student.dart';
import 'addteacherscreen.dart';
import 'main.dart';

class Teacher extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;

  const Teacher({super.key, required this.SchoolId,required this.Teacherid});

  @override
  State<Teacher> createState() => _Teacher();
}

class _Teacher extends State<Teacher>{
  String? img1;
   String? img2;
   String? img3;
  String? img4;
  bool showDot = false;
  String? profileImageUrl;
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  String? Schoolname;


  @override
  void initState() {
    super.initState();
    loadTeacherData();
    loadSchoolData();
    checkUpdate();
    _pages = [
      Homepage(SchoolId: widget.SchoolId, Teacherid:widget.Teacherid,),
      Adduser(
        SchoolId: widget.SchoolId,
        Title: "Add Student",
      ),
      AttendensStudent(SchoolId: widget.SchoolId, Teacherid:widget.Teacherid,),
      Accountpage(
        SchoolId: widget.SchoolId, Teacherid:widget.Teacherid, onlyview: false, title: "Account",
      ),
    ];
  }
  Future<void> checkUpdate() async {
    bool hasNew = await RedDotService.hasNewUpdate(
      "smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}/Notification",
      widget.Teacherid,
    );

    if (!mounted) return;

    setState(() {
      showDot = hasNew;
    });
  }

  Future<void> loadSchoolData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolId}",
    );

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
         Schoolname= data['name'];
      });
    }
  }

  Future<void> loadTeacherData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}",
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                   Schoolname!,
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
                      Schoolid: widget.SchoolId,
                      userid: widget.Teacherid,
                      user: "Teacher",
                    ),
                  ),
                );

                // 🔄 Refresh red dot after coming back
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


  }

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
                  _buildNavButton(Icons.how_to_reg, 2, width),
                  _buildNavButton(Icons.account_circle, 3, width),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        padding: EdgeInsets.all(width < 370 ? 10 : 14), // ✅ responsive
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

class Homepage extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;
  const Homepage({super.key, required this.SchoolId,required this.Teacherid});

  @override
  State<Homepage> createState() => _Homepage();
}

class _Homepage extends State<Homepage> {
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
      "title": "Announcement",
      "folder": "Announcement",
      "image": "assets/images/anno.png",
      "route": (String title) =>
          Announcements(SchoolId: widget.SchoolId, Teacherid: widget.Teacherid,),
    },
    {
      "title": "Events",
      "folder": "Event",
      "image": "assets/images/Event.png",
      "route": (String title) =>
          Eventss(SchoolId: widget.SchoolId,Teacherid: widget.Teacherid,),

    },
    {
      "title": "Notice",
      "folder": "Notice",
      "image": "assets/images/notice.png",
      "route": (String title) =>
          Notices(SchoolId: widget.SchoolId,Teacherid: widget.Teacherid,),

    },

    {
      "title": "Gallery",
      "folder": "Gallery",
      "image": "assets/images/sum.png",
      "route": (String title) =>
          Gallerys(SchoolId: widget.SchoolId, Teacherid: widget.Teacherid,),
    },
    {
      "title": "Home Work",
      "image": "assets/images/work.png",
      "route": (String title) =>
          Homework(SchoolId: widget.SchoolId, Title: title, userid: widget.Teacherid,),
    },
    {
      "title": "Time Table",
      "folder": "TimeTable",
      "image": "assets/images/table.png",
      "route": (String title) =>
          Timetables(SchoolId: widget.SchoolId, Title: title, userid: widget.Teacherid,),
    },
    {
      "title": "Detail's",
      "image": "assets/images/detail.png",
      "route": (String title) => Details(
        Schoolid: widget.SchoolId,
        title: title,

      ),
    },
    {
      "title": "AttendanceEdit",
      "image": "assets/images/att.png",
      "route": (String title) => EditAttendance(
       SchoolId: widget.SchoolId, Teacherid:widget.Teacherid,

      ),
    },
  ];

  List<Map<String, dynamic>> filteredItems = [];
  Map<String, bool> redDotStatus = {};
  Future<void> checkAllUpdates() async {

    for (var item in items) {

      String folder = item["folder"];

      bool hasNew = await RedDotService.hasNewUpdate(
        "smart/user1/${widget.SchoolId}/$folder",
        widget.Teacherid,
      );

      redDotStatus[folder] = hasNew;
    }

    if (!mounted) return;

    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    filteredItems = List.from(items);
    _pageController = PageController();

    sliderRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Slider");

    _loadSliderImages();
    _startAutoSlide();
    checkAllUpdates();
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
class Notices extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;

  const Notices({super.key, required this.SchoolId, required this.Teacherid});

  @override
  State<Notices> createState() => _Notices();

}
class _Notices extends State<Notices>{
  String? role;
  String? medium;
  List noticeList = [];

  late DatabaseReference view;
  Future<void> loaddata() async {
    DatabaseReference teacher = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}");
    DataSnapshot snapshot = await teacher.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        role = data['role'];
        medium = data['medium'];
      });
    }
  }
  @override
  void initState() {
    super.initState();
    loaddata();
    view = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Teacher/Notice");
    updateSeen();
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Teacher/Notice",
      widget.Teacherid,
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
          filteredNotices.add(value);
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

                      List filteredNotices = data.entries
                          .where((e) => e.value['Medium'] == medium)
                          .map((e) => e.value)
                          .toList();

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

class Gallerys extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;

  const Gallerys({super.key, required this.SchoolId, required this.Teacherid});

  @override
  State<Gallerys> createState() => _Gallerys();
}
class _Gallerys extends State<Gallerys>{
  late DatabaseReference view =
  FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Gallery");
  @override
  void initState() {
    super.initState();
    updateSeen();

  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Gallery",
      widget.Teacherid,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

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
                                builder: (_) => ImageShowPage(SchoolId: widget.SchoolId, Title: 'Gallery', keye: item["key"],),
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
class ImageShowPage extends StatefulWidget{
  final String SchoolId;
  final String Title;
  final String keye;

  const ImageShowPage({
    super.key,
    required this.SchoolId,
    required this.Title,
    required this.keye,
  });

  @override
  State<ImageShowPage> createState() => _ImageShowPage();
}
class _ImageShowPage extends State<ImageShowPage>{
  late DatabaseReference view;

  @override
  void initState() {
    super.initState();
    view = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Gallery/${widget.keye}");
  }
  @override
  Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.Title),
            centerTitle: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),

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
class Eventss extends StatefulWidget {
  final String SchoolId;
  final String Teacherid;

  const Eventss({super.key, required this.SchoolId, required this.Teacherid});

  @override
  State<Eventss> createState() => _Eventss();

}

class _Eventss extends State<Eventss> {
  late DatabaseReference view;
  @override
  void initState() {
    super.initState();
    view = FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/Event");
    updateSeen();
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Event",
      widget.Teacherid,
    );
  }

  @override
  Widget build(BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Events"),
              centerTitle: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
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

class Announcements extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;
  const Announcements({super.key, required this.SchoolId,required this.Teacherid});

  @override
  State<Announcements> createState() => _Announcements();
}

class _Announcements extends State<Announcements>{
  late DatabaseReference view;
  @override
  void initState() {
    super.initState();
    view = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Announcement");
    updateSeen();
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/Announcement",
      widget.Teacherid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements"),
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
                        leading: Icon(Icons.campaign),
                        title: Text(
                          "Announcement :- ${announcements[index]["Announcement"] ?? ""}",
                        ),
                        subtitle: Text(
                          "Time :- ${DateFormat('HH:mm').format(dt)}",
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
class AttendensStudent extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;
  const AttendensStudent({super.key, required this.SchoolId,required this.Teacherid});

  @override
  State<AttendensStudent> createState() => _AttendensStudent();
}
class _AttendensStudent extends State<AttendensStudent> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceMap = {}; // studentId -> Present/Absent

  TextEditingController dateController = TextEditingController();

  String? medium;
  String? std;
  String? division;
String? teacherid;
String? teachername;

  late DatabaseReference studentRef;

  final List<String> mediums = ["Marathi", "English", "Hindi", "Gujrathi"];
  final List<String> standards = ["1","2","3","4","5","6","7","8","9","10","11","12"];
  final List<String> divisions = ["A", "B", "C","D","E","F"];

  String dateKey = DateTime.now().toString().split(" ")[0];

  @override
  void initState() {
    super.initState();
    dateController.text = dateKey;
    loadteacher();
    studentRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Student");
  }
  Future<void> loadteacher() async {
    DatabaseReference teacherref = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}");
    DataSnapshot snapshot = await teacherref.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
          teacherid = widget.Teacherid;
          teachername =data['name'];
      });
    }
  }
  /// 🔹 LOAD STUDENTS
  Future<void> applyFilter() async {
    if (medium == null || std == null || division == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all filters")),
      );
      return;
    }

    final snapshot = await studentRef.get();
    students.clear();
    attendanceMap.clear();

    if (!snapshot.exists) {
      setState(() {});
      return;
    }

    final Map data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((studentId, value) {
      final student = Map<String, dynamic>.from(value);

      if (student['medium'] != medium) return;
      if (student['Standard'] != std) return;
      if (student['division'] != division) return;

      students.add({
        "id": studentId,
        "name": student["name"],
        "rollNo": student["rollNo"],
      });

      attendanceMap[studentId] = "Absent"; // default
    });

    setState(() {});
  }

  /// 🔹 SUBMIT ATTENDANCE
  Future<void> submitAttendance() async {
    if (students.isEmpty) return;

    DatabaseReference attendanceRef = FirebaseDatabase.instance
        .ref("smart/user1/${widget.SchoolId}/Attendance").child(dateKey);


    for (var student in students) {
      String studentId = student["id"];

      await attendanceRef.child(studentId).set({
        "name": student["name"],
        "rollNo": student["rollNo"],
        "medium": medium,
        "standard": std,
        "division": division,
        "status": attendanceMap[studentId],
        "takenby": teachername,
        "takenid": teacherid,
        "timestamp": ServerValue.timestamp,
      });
      await FirebaseDatabase.instance
          .ref("smart/user1/${widget.SchoolId}/Attendance")
          .update({
        "lastUpdated": DateTime.now().millisecondsSinceEpoch,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Attendance submitted for $dateKey")),
    );
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
      body: Column(
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

          /// 🔹 STUDENT LIST
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                String studentId = students[index]["id"];
                String name = students[index]["name"];
                String rollNo = students[index]["rollNo"];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.deepPurple),
                    subtitle: Text(name),
                    title: Text(rollNo),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 🟢 PRESENT
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              attendanceMap[studentId] = "Present";
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor:
                            attendanceMap[studentId] == "Present"
                                ? Colors.green
                                : Colors.green.withOpacity(0.2),
                            child: attendanceMap[studentId] == "Present"
                                ? const Text("P",style:TextStyle(color: Colors.white),)
                                : null,
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// 🔴 ABSENT
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              attendanceMap[studentId] = "Absent";
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor:
                            attendanceMap[studentId] == "Absent"
                                ? Colors.red
                                : Colors.red.withOpacity(0.2),
                            child: attendanceMap[studentId] == "Absent"
                                ? const Text("A",style:TextStyle(color: Colors.white),)
                                : null,
                          ),
                        ),
                      ],
                    ),

                  ),
                );
              },
            ),
          ),

          /// 🔹 SUBMIT BUTTON
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: submitAttendance,
              child: const Text("Submit Attendance"),
            ),
          ),
        ],
      ),
    );
  }
}
class EditAttendance extends StatefulWidget {
  final String SchoolId;
  final String Teacherid;

  const EditAttendance({
    super.key,
    required this.SchoolId,
    required this.Teacherid,
  });

  @override
  State<EditAttendance> createState() => _EditAttendanceState();
}

class _EditAttendanceState extends State<EditAttendance> {
  TextEditingController dateController = TextEditingController();
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString().split(" ")[0];
    loadSessions();
  }

  Future<void> loadSessions() async {
    sessions.clear();

    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolId}/Attendance/${dateController.text}",
    );

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      setState(() {});
      return;
    }

    final Map data = Map<String, dynamic>.from(snapshot.value as Map);
    final Set<String> uniqueKeys = {};

    data.forEach((id, value) {
      final record = Map<String, dynamic>.from(value);

      if (record["takenid"] != widget.Teacherid) return;

      String key =
          "${record["medium"]}_${record["standard"]}_${record["division"]}";

      if (uniqueKeys.add(key)) {
        sessions.add({
          "date": dateController.text,
          "medium": record["medium"],
          "standard": record["standard"],
          "division": record["division"],
        });
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Attendance"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                  loadSessions();
                }
              },
            ),
          ),

          Expanded(
            child: sessions.isEmpty
                ? const Center(child: Text("No Attendance Found"))
                : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.class_,
                        color: Colors.deepPurple),
                    title: Text(
                        "Std ${s["standard"]} - Div ${s["division"]}"),
                    subtitle: Text(
                        "${s["medium"]} Medium\nDate: ${s["date"]}"),
                    trailing:
                    const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAttendanceStudents(
                                schoolId: widget.SchoolId,
                                teacherId: widget.Teacherid,
                                date: s["date"],
                                medium: s["medium"],
                                standard: s["standard"],
                                division: s["division"],
                              ),
                        ),
                      );
                    },
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
class EditAttendanceStudents extends StatefulWidget {
  final String schoolId;
  final String teacherId;
  final String date;
  final String medium;
  final String standard;
  final String division;

  const EditAttendanceStudents({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.date,
    required this.medium,
    required this.standard,
    required this.division,
  });

  @override
  State<EditAttendanceStudents> createState() =>
      _EditAttendanceStudentsState();
}

class _EditAttendanceStudentsState extends State<EditAttendanceStudents> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceMap = {};

  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.schoolId}/Attendance/${widget.date}",
    );
    loadStudents();
  }

  Future<void> loadStudents() async {
    final snapshot = await ref.get();
    students.clear();
    attendanceMap.clear();

    if (!snapshot.exists) return;

    final Map data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((id, value) {
      final record = Map<String, dynamic>.from(value);

      if (record["takenid"] != widget.teacherId) return;
      if (record["medium"] != widget.medium) return;
      if (record["standard"] != widget.standard) return;
      if (record["division"] != widget.division) return;

      students.add({
        "id": id,
        "name": record["name"],
        "rollNo": record["rollNo"],
      });

      attendanceMap[id] = record["status"];
    });

    setState(() {});
  }

  Future<void> saveChanges() async {
    for (var student in students) {
      await ref.child(student["id"]).update({
        "status": attendanceMap[student["id"]],
        "timestamp": ServerValue.timestamp,
      });
    }
    await FirebaseDatabase.instance
        .ref("smart/user1/${widget.schoolId}/Attendance")
        .update({
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Std ${widget.standard} - Div ${widget.division}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];
                final status = attendanceMap[s["id"]];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(s["name"]),
                    subtitle: Text("Roll No: ${s["rollNo"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              attendanceMap[s["id"]] = "Present";
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: status == "Present"
                                ? Colors.green
                                : Colors.green.withOpacity(0.2),
                            child: status == "Present"
                                ? const Text("P",
                                style: TextStyle(
                                    color: Colors.white))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              attendanceMap[s["id"]] = "Absent";
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: status == "Absent"
                                ? Colors.red
                                : Colors.red.withOpacity(0.2),
                            child: status == "Absent"
                                ? const Text("A",
                                style: TextStyle(
                                    color: Colors.white))
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: saveChanges,
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }
}
class Accountpage extends StatefulWidget{
  final String SchoolId;
  final String Teacherid;
  final String title;
  final bool onlyview ;
  const Accountpage({super.key, required this.SchoolId,required this.Teacherid,required this.onlyview,required this.title});

  @override
  State<Accountpage> createState() => _Accountpage();
}
class _Accountpage extends State<Accountpage>{
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



  @override
  void initState() {
    super.initState();
    loadAdminData();
    loadProfileImage();
  }

  // ================= LOAD ADMIN DATA =================
  Future<void> loadAdminData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
      "smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}",
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
      "smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}",
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
      "smart/user1/${widget.SchoolId}/Teacher/${widget.Teacherid}",
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
class Timetables extends StatefulWidget{

  final String SchoolId;
  final String Title;
  final String userid;

  const Timetables({super.key, required this.SchoolId, required this.Title,required this.userid,});

  @override
  State<Timetables> createState() => _Timetables();
}
class _Timetables extends State<Timetables>{
  late DatabaseReference show= FirebaseDatabase.instance.ref("smart/user1/${widget.SchoolId}/TimeTable");

  Future<void> downloadTimeTable(String imageUrl) async {
    final Uri url = Uri.parse(imageUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to download Time Table")),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    updateSeen();
  }
  void updateSeen() async {

    await RedDotService.updateLastSeen(
      "smart/user1/${widget.SchoolId}/TimeTable",
      widget.userid,
    );
  }
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.Title),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [

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
                          final dt = timetableList[index]["DateTime"] != null
                              ? DateTime.parse(timetableList[index]["DateTime"])
                              : DateTime.now();

                          final tt = timetableList[index];


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
                                  Text("Date :- ${DateFormat('dd MMM yyyy').format(dt)}"),
                                  Text("Time: ${DateFormat('HH:mm').format(dt)}"),
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
class Details extends StatefulWidget{
  final String Schoolid;
  final String title;

  const Details({
    super.key,
    required this.Schoolid,
    required this.title,
  });

  @override
  State<Details> createState() => _Details();
}
class _Details extends State<Details>{
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
                                  Teacherid:users[index]["key"],
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