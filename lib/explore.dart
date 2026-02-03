import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:infumedz/views.dart';
import 'package:video_player/video_player.dart';
import 'admin.dart';
import 'cart.dart';
import 'main.dart';

class MedicalStoreScreen extends StatefulWidget {
  final String initialCategory; // 👈 NEW

  const MedicalStoreScreen({
    super.key,
    this.initialCategory = "MBBS", // 👈 default
  });

  @override
  State<MedicalStoreScreen> createState() => _MedicalStoreScreenState();
}

class _MedicalStoreScreenState extends State<MedicalStoreScreen> {
  String selectedType = "Courses";
  final List<Map<String, dynamic>> wishlistItems = [];

  // backend data
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> books = [];

  // selection state
  int? selectedCategoryId;
  String selectedCategoryName = "MBBS";

  // loading states
  bool loadingCategories = true;
  bool loadingCourses = true;
  bool loadingBooks = true;

  double get cartTotal {
    double total = 0;
    for (var item in CartStore.items) {
      final price =
          double.tryParse(
            item["price"].replaceAll("₹", "").replaceAll(",", ""),
          ) ??
          0;
      total += price;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    selectedCategoryName = widget.initialCategory;

    fetchCategories();
    fetchCourses();
    fetchBooks();
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories));
    if (res.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));

      setState(() {
        categories = data;

        // auto select initial category
        final match = data.firstWhere(
          (c) => c["name"] == selectedCategoryName,
          orElse: () => data.first,
        );

        selectedCategoryId = match["id"];
        selectedCategoryName = match["name"];
        loadingCategories = false;
      });
    }
  }

  Future<void> fetchCourses() async {
    final res = await http.get(Uri.parse(ApiConfig.courses));
    if (res.statusCode == 200) {
      setState(() {
        courses = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        loadingCourses = false;
      });
    }
  }

  Future<void> fetchBooks() async {
    final res = await http.get(Uri.parse(ApiConfig.books));
    if (res.statusCode == 200) {
      setState(() {
        books = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        loadingBooks = false;
      });
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text(
                "Select Level",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: ["MBBS", "MD/MS", "DM/DrNB"].map((level) {
                  final active = selectedCategoryName == level;
                  return ChoiceChip(
                    label: Text(level),
                    selected: active,
                    selectedColor: const Color(0xFF0E5FD8),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategoryName = level;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CartBottomSheet(
        initialItems: CartStore.items,
        onCartUpdated: (updated) {
          setState(() {
            CartStore.clear();
            for (final item in updated) {
              CartStore.add(item);
            }
          });
        },
      ),
    );
  }

  void _openWishlist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => WishlistBottomSheet(
        initialItems: wishlistItems,
        onAddToCart: (item) {
          CartStore.add(item);
        },
        onWishlistUpdated: (updated) {
          setState(() {
            wishlistItems
              ..clear()
              ..addAll(updated);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawData = selectedType == "Courses" ? courses : books;

    final data = rawData
        .where((item) => item["category_name"] == selectedCategoryName)
        .toList();

    if (loadingCategories || loadingCourses || loadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Explore Learning",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F3C68),
          ),
        ),
        actions: [
          /// ❤️ Wishlist
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF0E5FD8)),
            onPressed: _openWishlist,
          ),

          /// 🛒 Cart
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF0E5FD8),
                ),
                onPressed: () => _openCart(context),
              ),

              if (CartStore.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      CartStore.items.length.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0E5FD8)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search courses, books, subjects…",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF0E5FD8)),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),
          ),

          /// COURSE / BOOK TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ["Courses", "Books"].map((type) {
                final active = selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0E5FD8) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          /// CATEGORY FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: Color(0xFF0E5FD8),
                ),
                const SizedBox(width: 6),
                Text(
                  "Showing $selectedType for ",
                  style: const TextStyle(fontSize: 17, color: Colors.black54),
                ),
                Text(
                  selectedCategoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final item = data[i];
                return _CourseListCard(
                  data: {
                    "title": item["title"],
                    "image": item["thumbnail_url"],
                    "price": "₹${item["price"]}",
                    "learners": item["learners"] ?? "",
                    "videos": item["videos"] ?? [],
                  },

                  isWishlisted: wishlistItems.contains(item),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(
                          data: item,
                          option: selectedType,
                        ),
                      ),
                    );
                  },

                  onWishlist: () {
                    setState(() {
                      if (wishlistItems.contains(item)) {
                        wishlistItems.remove(item);
                      } else {
                        wishlistItems.add(item);
                      }
                    });
                  },

                  onAddToCart: () {
                    setState(() {
                      if (!CartStore.items.contains(item)) {
                        CartStore.add(item);
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to cart")),
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

class _CourseListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddToCart;
  final bool isWishlisted;

  _CourseListCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onWishlist,
    this.onAddToCart,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 THUMBNAIL (REDUCED HEIGHT)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: Image.network(
                      data["image"],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade300),
                    ),
                  ),

                  /// ▶ Play icon
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                  /// ❤️ Wishlist
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? Colors.red : Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  /// 🎬 VIDEO COUNT BADGE
                  if (true)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${((data["videos"] as List).length)} videos",

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${data["videoCount"]} videos",

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  /// 🏷 Tag
                  if (data["tag"] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data["tag"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              /// 🔹 DETAILS
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Text(
                      data["title"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F3C68),
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// Cost + ⭐ RATING + 👥 LEARNERS (SINGLE ROW)
                    Row(
                      children: [
                        /// ⭐ LEFT — Rating
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "4.8",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// 👥 CENTER — Learners
                        Expanded(
                          child: Text(
                            data["learners"] ?? "",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        /// 💰 RIGHT — Price
                        Expanded(
                          child: Text(
                            data["price"],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E5FD8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// PRICE + CART
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartStore {
  static final List<Map<String, dynamic>> _items = [];

  static List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  /// returns true if added, false if already exists
  static bool add(Map<String, dynamic> item) {
    final exists = _items.any((e) => e["title"] == item["title"]);

    if (exists) return false;

    _items.add(item);
    return true;
  }

  static void remove(Map<String, dynamic> item) {
    _items.removeWhere((e) => e["title"] == item["title"]);
  }

  static void clear() {
    _items.clear();
  }

  static bool contains(Map<String, dynamic> item) {
    return _items.any((e) => e["title"] == item["title"]);
  }

  static double total() {
    double sum = 0;

    for (final item in _items) {
      final raw = item["price"];
      if (raw == null) continue;

      final cleaned = raw.toString().replaceAll("₹", "").replaceAll(",", "");

      sum += double.tryParse(cleaned) ?? 0;
    }

    return sum;
  }
}

// ignore: must_be_immutable
class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  List<Map<String, dynamic>> videos = [];
  final String option;
  // ✅ FIX

  CourseDetailScreen({super.key, required this.data, required this.option});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool isPlaying = false;
  @override
  void initState() {
    // TODO: implement initState
    if (widget.option == "Books") {
      widget.videos = List<Map<String, dynamic>>.from(
        widget.data["pdfs"] ?? [],
      );
    } else {
      widget.videos = List<Map<String, dynamic>>.from(
        widget.data["videos"] ?? [],
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      /// 🔹 BOTTOM ACTION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ❤️ Wishlist
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0E5FD8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Color(0xFF0E5FD8),
              ),
            ),

            const SizedBox(width: 12),

            /// 🛒 Add to Cart
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  CartStore.add(widget.data);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5FD8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Add to Cart • ${widget.data["price"] ?? "0"}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          /// 🔹 HERO APP BAR
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white, // 👈 makes it white
              ),
              onPressed: () {
                setState(() => isPlaying = false);
                Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isPlaying)
                    Image.network(
                      widget.data["thumbnail_url"] ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.black),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final List videos = widget.data["videos"] ?? [];

                        if (videos.isNotEmpty) {
                          return InlineVideoPlayer(
                            url: videos.first["video_url"],
                            title: videos.first["title"] ?? "",
                          );
                        } else {
                          return const Center(
                            child: Text(
                              "No videos available",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                      },
                    ),

                  if (!isPlaying)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),

                  if (!isPlaying)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          final title = widget.data["title"]
                              .toString()
                              .toLowerCase();

                          final isPdfType =
                              title.contains("pdf") ||
                              title.contains("Based") ||
                              title.contains("notes") ||
                              title.contains("Rapid") ||
                              title.contains("rapid revise") ||
                              title.contains("case based") ||
                              title.contains("case based") ||
                              title.contains("case based") ||
                              title.contains("handbook");

                          if (isPdfType) {
                            /// 📄 OPEN PDF PAGE (NO setState)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfScreen(
                                  pdfUrl:
                                      "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/pdfs/54cfac91-079b-481d-8d8c-9916924954f0_CASTOR.pdf",
                                  title: title,
                                ),
                              ),
                            );
                          } else {
                            /// 🎥 PLAY VIDEO INLINE
                            final videos = widget.data["videos"] as List? ?? [];

                            if (videos.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No videos available"),
                                ),
                              );
                            } else {
                              setState(() => isPlaying = true);
                            }
                          }
                        },
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// 🔹 CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  Text(
                    widget.data["title"],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F3C68),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// RATING + LEARNERS
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        "4.8",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "(12,400 ratings)",
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "1200+ Learners",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// META INFO
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: const [
                      _MetaItem(icon: Icons.language, text: "English"),
                      _MetaItem(
                        icon: Icons.update,
                        text: "Last updated Jan 2026",
                      ),
                      _MetaItem(icon: Icons.school, text: "Medical Education"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CREATED BY
                  const Text(
                    "Created by",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "InfuMedz Academic Faculty",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0E5FD8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// DESCRIPTION
                  const Text(
                    "About this course",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.data["description"] ?? "No description available",
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.videos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Course content",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.videos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final video = widget.videos[index];

                        return YoutubeStyleCourseCard(
                          title: video["title"],
                          views: "Lecture ${index + 1}",
                          meta: "Video lecture",
                          price: "", // no price here
                          thumbnail: widget.data["thumbnail_url"],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(
                                  url: video["video_url"],
                                  title: video["title"],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    const Text(
                      "No videos available for this course",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// WHAT YOU’LL LEARN
                  const Text(
                    "What you'll learn",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  const _BulletPoint(
                    text:
                        "Develop strong conceptual clarity with clinical relevance",
                  ),
                  const _BulletPoint(
                    text: "Understand diagnostic and treatment strategies",
                  ),
                  const _BulletPoint(
                    text:
                        "Prepare effectively for university & competitive exams",
                  ),
                  const _BulletPoint(
                    text: "Access curated PDFs, videos, and revision materials",
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

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const InlineVideoPlayer({super.key, required this.url, required this.title});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _openFullscreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(url: widget.url, title: widget.title),
      ),
    );

    // resume inline playback after fullscreen exit
    if (mounted) {
      setState(() {});
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          /// 🧩 CONTROLS
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// ▶️ / ⏸
                    IconButton(
                      iconSize: 42,
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),

                    const SizedBox(width: 24),

                    /// ⛶ FULLSCREEN
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _openFullscreen,
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF0E5FD8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
