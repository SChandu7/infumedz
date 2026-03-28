import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:infumedz/library.dart';
import 'package:infumedz/loginsignup.dart';
import 'dart:async';
import 'package:infumedz/views.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:video_player/video_player.dart';
import 'cart.dart';
import 'main.dart';
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';

class MedicalStoreScreen extends StatefulWidget {
  final String initialCategory; // 👈 NEW

  const MedicalStoreScreen({
    super.key,
    this.initialCategory = "All", // 👈 default
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
  String selectedCategoryName = "All";

  // loading states
  bool loadingCategories = true;
  bool loadingCourses = true;
  bool loadingBooks = true;

  String _searchQuery = "";
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _searchSuggestions = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        final allItems = [...courses, ...books];
        _searchSuggestions = allItems
            .where(
              (item) => (item["title"] ?? "").toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  Widget _shimmerBox({double? width, double? height, double radius = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      onEnd: () {
        if (mounted) setState(() {});
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE8EDF5),
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── thumbnail placeholder ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              child: _shimmerBox(
                height: 160,
                width: double.infinity,
                radius: 0,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title line 1
                  _shimmerBox(height: 14, width: double.infinity),
                  const SizedBox(height: 6),
                  // title line 2
                  _shimmerBox(height: 14, width: 200),
                  const SizedBox(height: 10),
                  // rating + price row
                  Row(
                    children: [
                      _shimmerBox(height: 12, width: 60),
                      const Spacer(),
                      _shimmerBox(height: 12, width: 80),
                      const Spacer(),
                      _shimmerBox(height: 12, width: 60),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories));
    if (res.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));

      setState(() {
        categories = data;

        // ✅ IF ALL → DO NOT SELECT ANY CATEGORY
        if (selectedCategoryName == "All") {
          selectedCategoryId = null;
        } else {
          final match = data.firstWhere(
            (c) => c["name"] == selectedCategoryName,
            orElse: () => data.first,
          );
          selectedCategoryId = match["id"];
          selectedCategoryName = match["name"];
        }

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
                children: [
                  /// ✅ ALL OPTION
                  ChoiceChip(
                    label: const Text("All"),
                    selected: selectedCategoryName == "All",
                    selectedColor: const Color(0xFF0E5FD8),
                    labelStyle: TextStyle(
                      color: selectedCategoryName == "All"
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategoryName = "All";
                        selectedCategoryId = null;
                      });
                      Navigator.pop(context);
                    },
                  ),

                  /// EXISTING CATEGORIES
                  ...categories.map((cat) {
                    final name = cat["name"];
                    final active = selectedCategoryName == name;

                    return ChoiceChip(
                      label: Text(name),
                      selected: active,
                      selectedColor: const Color(0xFF0E5FD8),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategoryName = name;
                          selectedCategoryId = cat["id"];
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
          final safeItem = {
            "id": item["id"] ?? "",
            "title": item["title"] ?? "Untitled",
            "image":
                item["image"] ??
                item["thumbnail_url"] ??
                "assets/images/placeholder.png",
            "price": item["price"]?.toString() ?? "0",
          };
          CartStore.addCourse(safeItem);
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

    final data = selectedCategoryName == "All"
        ? rawData
        : rawData
              .where((item) => item["category_name"] == selectedCategoryName)
              .toList();

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
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: false,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CartBottomSheet(
                      initialItems: CartStore.items, // ✅ IMPORTANT
                      onCartUpdated: (updated) {
                        // optional sync if needed later
                      },
                    ),
                  );
                },
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0E5FD8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search courses, books..",
                        border: InputBorder.none,
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.black45,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged("");
                                },
                              )
                            : null,
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

          /// SEARCH RESULTS or NORMAL VIEW
          if (_isSearching) ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _searchSuggestions.isEmpty
                    ? 1
                    : _searchSuggestions.length,
                itemBuilder: (context, i) {
                  if (_searchSuggestions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "No results found",
                        style: TextStyle(color: Colors.black45),
                      ),
                    );
                  }
                  final item = _searchSuggestions[i];
                  final isBook = item.containsKey("pdfs");
                  return ListTile(
                    leading: Icon(
                      isBook ? Icons.menu_book : Icons.play_circle_outline,
                      color: const Color(0xFF0E5FD8),
                    ),
                    title: Text(
                      item["title"] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(isBook ? "Book" : "Course"),
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged("");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            data: item,
                            option: isBook ? "Books" : "Courses",
                            isLocked: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ] else ...[
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
                          color: active
                              ? const Color(0xFF0E5FD8)
                              : Colors.white,
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
                    selectedCategoryName == "All"
                        ? "Showing $selectedType"
                        : "Showing $selectedType for ",
                    style: const TextStyle(fontSize: 17, color: Colors.black54),
                  ),
                  InkWell(
                    onTap: _openFilterSheet,
                    child: Text(
                      selectedCategoryName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E5FD8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// LIST
            /// LIST
            Expanded(
              child: (loadingCourses || loadingBooks)
                  ? _buildStoreSkeletonList()
                  : ListView.builder(
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
                                  isLocked: true,
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
                          onAddToCart: () {},
                        );
                      },
                    ),
            ),
            const SizedBox(height: 65),
          ],
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
          margin: const EdgeInsets.only(bottom: 26, left: 10, right: 10),
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
                          "${(data["videos"] as List).length} videos",
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

// ignore: must_be_immutable
class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  List<Map<String, dynamic>> videos = [];
  final String option;
  bool isLocked;

  // ✅ FIX

  CourseDetailScreen({
    super.key,
    required this.data,
    required this.option,
    required this.isLocked,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool isPlaying = false;
  double averageRating = 0;
  int totalReviews = 0;
  List<dynamic> reviewList = [];
  String? _phone;
  String? _email;
  bool _isAdmin = false;
  // ADD below existing Razorpay fields

  int selectedRating = 5;
  TextEditingController reviewController = TextEditingController();
  bool isSubmittingReview = false;
  bool hasAccess = false;
  bool checkingAccess = true;

  bool get isBook => widget.option == "Books";
  String _getYoutubeThumbnail(String url) {
    if (url.isEmpty || !url.contains("youtu")) return "";

    final uri = Uri.tryParse(url);
    if (uri == null) return "";

    String? videoId;

    if (uri.host.contains("youtu.be")) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else {
      videoId = uri.queryParameters["v"];
    }

    if (videoId == null || videoId.isEmpty) return "";
    return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
  }

  Future<void> buyCourse() async {
    final userId = await UserSession.getUserId();
    print("-===========---------------======================-----------------");
    print(userId);
    print(widget.data["id"]);

    if (userId == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    startPayment();
  }

  Future<void> _loadSession() async {
    final phone = await UserSession.getUserphonenumber();
    final email = await UserSession.getUseremail();

    setState(() {
      _phone = phone;
      _email = email;

      _isAdmin =
          phone == "9949597079" ||
          phone == "9167459168" ||
          phone == "9167459138" ||
          email == "chandrasekharsuragani532@gmail.com";
    });
    if (_isAdmin) {
      print("Admin access granted-----------------------------------------");
      widget.isLocked = false;
    }
  }

  @override
  void initState() {
    _loadSession();
    checkAccess();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    print(widget.data);

    if (Platform.isIOS) {}

    print(widget.data);
    if (widget.option == "Books") {
      widget.videos = List<Map<String, dynamic>>.from(
        widget.data["pdfs"] ?? [],
      );
    } else {
      widget.videos = List<Map<String, dynamic>>.from(
        widget.data["videos"] ?? [],
      );
    }

    // ✅ Sort alphabetically by title
    widget.videos.sort((a, b) {
      final titleA = (a["title"] ?? "").toString().toLowerCase();
      final titleB = (b["title"] ?? "").toString().toLowerCase();
      return titleA.compareTo(titleB);
    });

    fetchReviews();

    super.initState();
  }

  Future<void> checkAccess() async {
    final userId = await UserSession.getUserId();

    if (userId == null) {
      setState(() => checkingAccess = false);
      return;
    }

    final type = widget.option == "Books" ? "book" : "course";

    final res = await http.get(
      Uri.parse(
        "https://api.chandus7.in/api/infumedz/check-access/$userId/$type/${widget.data["id"]}/",
      ),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        hasAccess = data["has_access"];
        checkingAccess = false;
      });
    } else {
      setState(() => checkingAccess = false);
    }
  }

  Future<void> submitReview() async {
    final userId = await UserSession.getUserId();

    if (userId == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    if (reviewController.text.trim().isEmpty) return;

    setState(() => isSubmittingReview = true);

    final url = isBook
        ? "https://api.chandus7.in/api/infumedz/book/review/add/"
        : "https://api.chandus7.in/api/infumedz/course/review/add/";

    final body = isBook
        ? {
            "user_id": userId,
            "book_id": widget.data["id"],
            "rating": selectedRating,
            "comment": reviewController.text.trim(),
          }
        : {
            "user_id": userId,
            "course_id": widget.data["id"],
            "rating": selectedRating,
            "comment": reviewController.text.trim(),
          };

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() => isSubmittingReview = false);

    if (res.statusCode == 200) {
      reviewController.clear();
      fetchReviews();
    }
  }

  Future<Map<String, dynamic>?> fetchCourseById(String id) async {
    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/courses/"),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      final course = data.firstWhere(
        (item) => item["id"].toString() == id,
        orElse: () => null,
      );

      return course;
    }

    return null;
  }

  Future<void> fetchReviews() async {
    final url = isBook
        ? "https://api.chandus7.in/api/infumedz/book/${widget.data["id"]}/reviews/"
        : "https://api.chandus7.in/api/infumedz/course/${widget.data["id"]}/reviews/";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        averageRating = data["average_rating"];
        totalReviews = data["total_reviews"];
        reviewList = data["reviews"];
      });
    }
  }

  late Razorpay _razorpay;

  String? _orderId;
  bool _loading = false;
  String _status = "Ready";

  @override
  void dispose() {
    _razorpay.clear();

    super.dispose();
  }

  // BEFORE — two separate methods buyCourse() and startPayment()
  // REPLACE BOTH with this single method:

  Future<void> startPayment() async {
    final userId = await UserSession.getUserId();
    if (userId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    if (Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please visit our website to enroll"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    } else {
      // ── Android: Razorpay (existing logic) ──
      final isBook = widget.option == "Books";
      final url = isBook
          ? "https://api.chandus7.in/api/infumedz/payment/create-book-order/"
          : "https://api.chandus7.in/api/infumedz/payment/create-course-order/";
      final body = isBook
          ? {"user": userId, "book_id": widget.data["id"]}
          : {"user": userId, "course_id": widget.data["id"]};

      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err["error"] ?? "Payment failed")),
        );
        return;
      }

      final data = jsonDecode(res.body);
      _orderId = data["order_id"];
      _openRazorpay(data["key"]); // existing method — no change
    }
  }

  // =====================================================
  // STEP 1: CREATE ORDER
  // =====================================================

  // =====================================================
  // STEP 2: OPEN RAZORPAY
  // =====================================================
  void _openRazorpay(String key) {
    _status = "Opening payment gateway…";

    _razorpay.open({
      'key': key,
      'order_id': _orderId,
      'amount': 200,
      'currency': 'INR',
      'name': "Infumedz Payment",
      'description': 'UPI / Card Payment',
      'timeout': 180,
      'retry': {'enabled': false},
      'prefill': {
        'contact': '${UserSession.getUserphonenumber()}',
        'email': '${UserSession.getUseremail()}',
      },
    });
  }

  // =====================================================
  // STEP 3: SDK SUCCESS CALLBACK (NOT FINAL TRUTH)
  // =====================================================
  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _status = "Verifying payment…";
    });

    // ⚠️ ONLY NOW we talk to backend
    final res = await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/payment/verify-payment/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "order_id": _orderId,
        "payment_id": response.paymentId,
        "signature": response.signature,
      }),
    );

    if (res.statusCode == 200) {
      setState(() {
        _status = "✅ Payment Successful";
        _loading = false;
      });
    } else {
      // Signature failed or backend rejected
      setState(() {
        _status = "⚠️ Payment processing. Please refresh.";
        _loading = false;
      });
    }
  }

  // =====================================================
  // STEP 4: SDK ERROR / BANKING BUG / UPI ISSUE
  // =====================================================
  void _onError(PaymentFailureResponse response) {
    // ❌ DO NOT mark failed immediately
    setState(() {
      _status = "⚠️ Payment not completed / cancelled";
      _loading = false;
    });
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
              child: Builder(
                builder: (_) {
                  // 🔄 Checking access (API call running)
                  if (checkingAccess) {
                    return const Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  // ✅ USER ALREADY PURCHASED
                  if (hasAccess) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        if (widget.videos.isEmpty) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LibraryPage()),
                        );
                      },
                      child: const Text(
                        "Continue Learning",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  // 💳 NOT PURCHASED → SHOW BUY BUTTON
                  return Platform.isIOS
                      ? ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please visit our website to enroll",
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text(
                            "Enroll via Website",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueAccent,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _purchaseLoading ? null : startPayment,
                          child: _purchaseLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Buy • ${widget.data["price"] ?? "0"}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                        );
                },
              ),
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          /// 🔹 HERO APP BAR
          SliverAppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final id = widget.data["id"];
                  final name = widget.data["title"];
                  final link = "https://www.chandus7.in/course/$id";

                  Share.share("Check this course on InfuMedz: $name \n$link");
                },
              ),
            ],
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
                        if (widget.videos.isNotEmpty) {
                          final String videoUrl =
                              widget.videos.first["video_url"]?.toString() ??
                              "";

                          if (videoUrl.isEmpty) {
                            print(widget.data["video_url"]);
                            return const Center(
                              child: Text(
                                "Invalid video URL",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return InlineVideoPlayer(
                            url: videoUrl,
                            title: widget.data["title"] ?? "",
                          );
                        } else {
                          return const Center(
                            child: Text(
                              "No Data available",
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
                          final isBook = widget.option == "Books";

                          if (isBook) {
                            // 📄 OPEN FIRST PDF
                            if (widget.videos.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No books available"),
                                ),
                              );
                              return;
                            }
                            print("------------44444444444----------");
                            print(widget.data["pdf_url"]);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfScreen(
                                  pdfUrl: widget.videos.first["pdf_url"],
                                  title: widget.data["title"],
                                ),
                              ),
                            );
                          } else {
                            // 🎥 PLAY VIDEO INLINE
                            if (widget.videos.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No videos available"),
                                ),
                              );
                              return;
                            }

                            setState(() => isPlaying = true);
                          }
                        },
                        child: Icon(
                          widget.option == "Books"
                              ? Icons.picture_as_pdf
                              : Icons.play_circle_fill,
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
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
                    const SizedBox(height: 4),
                    const Text(
                      "Course content",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.videos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = widget.videos[index];

                        final title = item["title"] ?? "Untitled";

                        if (isBook) {
                          // 📄 BOOK / PDF

                          return YoutubeStyleCourseCard3(
                            title: title,
                            views: "Document ${index + 1}",
                            meta: "PDF",
                            price: "",
                            thumbnail:
                                "https://cdn-icons-png.flaticon.com/512/337/337946.png",
                            onTap: () {
                              if (!widget.isLocked) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfScreen(
                                      pdfUrl: item["pdf_url"],
                                      title: title,
                                    ),
                                  ),
                                );
                              }
                            },
                            isBook: isBook,
                          );
                        } else {
                          // 🎥 VIDEO
                          final String videoUrl =
                              item["video_url"]?.toString() ?? "";
                          final thumbnail =
                              item["thumbnail_url"] ??
                              _getYoutubeThumbnail(videoUrl);

                          return YoutubeStyleCourseCard3(
                            title: title,
                            views: "Lecture ${index + 1}",
                            meta: "Video",
                            price: "",
                            thumbnail: thumbnail,
                            onTap: () {
                              if (videoUrl.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Invalid video URL"),
                                  ),
                                );
                                return;
                              }
                              if (!widget.isLocked) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoPlayerScreen(
                                      url: videoUrl,
                                      title: title,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Buy Course to unlock content",
                                    ),
                                  ),
                                );
                              }
                            },

                            isBook: isBook,
                          );
                        }
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

                  SizedBox(height: 10),
                  const SizedBox(height: 30),

                  /// ⭐ REVIEWS SECTION
                  const Text(
                    "Ratings & Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        averageRating.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "($totalReviews reviews)",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),

                  /// COMMENT LIST
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviewList.length,
                    itemBuilder: (context, index) {
                      final review = reviewList[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  review["user_name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Row(
                              children: List.generate(
                                review["rating"],
                                (i) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(review["comment"]),
                          ],
                        ),
                      );
                    },
                  ),

                  /// ADD REVIEW BOX
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Write a Review",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),

                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                setState(() => selectedRating = index + 1);
                              },
                            );
                          }),
                        ),

                        TextField(
                          controller: reviewController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Share your experience...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: isSubmittingReview ? null : submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              128,
                              132,
                              216,
                            ),
                          ),
                          child: isSubmittingReview
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Submit Review",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
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

class YoutubeStyleCourseCard3 extends StatelessWidget {
  final String title;
  final String views;
  final String meta;
  final String price;
  final String thumbnail;
  final VoidCallback onTap;
  final bool isBook;

  const YoutubeStyleCourseCard3({
    super.key,
    required this.title,
    required this.views,
    required this.meta,
    required this.price,
    required this.thumbnail,
    required this.onTap,
    required this.isBook,
  });

  Widget _fallbackThumb() {
    return Container(
      width: 140,
      height: 80,
      color: Colors.black12,
      alignment: Alignment.center,
      child: Icon(
        isBook ? Icons.picture_as_pdf : Icons.play_circle,
        size: 36,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // ✅ whole row tap
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  thumbnail.isNotEmpty
                      ? Image.network(
                          thumbnail,
                          width: 140,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackThumb(),
                        )
                      : _fallbackThumb(),

                  Container(
                    width: 140,
                    height: 80,
                    color: Colors.black.withOpacity(0.15),
                  ),
                  Icon(
                    isBook ? Icons.picture_as_pdf : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 📄 Title + Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    views,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),

            // ⋮ YOUTUBE STYLE MENU
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.black54,
              ),
              onSelected: (value) {
                if (value == "share") {
                  // TODO: share
                } else if (value == "save") {
                  // TODO: save
                } else if (value == "report") {
                  // TODO: report
                }
              },
              itemBuilder: (context) => [],
            ),
          ],
        ),
      ),
    );
  }
}

class UserChatScreen extends StatefulWidget {
  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final userId = await UserSession.getUserId();

    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/chat/history/$userId/"),
    );

    if (res.statusCode == 200) {
      setState(() {
        messages = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> sendMessage() async {
    final userId = await UserSession.getUserId();
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    final res = await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/chat/message/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "message": text}),
    );

    final data = jsonDecode(res.body);

    setState(() {
      messages.add({"message": text, "type": "USER"});
    });

    if (data["type"] == "BOT") {
      setState(() {
        messages.add({"message": data["reply"], "type": "BOT"});
      });
    } else {
      showEscalateDialog(text);
    }
  }

  void showEscalateDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Contact Support?"),
        content: Text("Would you like to send this to admin support?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await http.post(
                Uri.parse(
                  "https://api.chandus7.in/api/infumedz/support/create/",
                ),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "user_id": await UserSession.getUserId(),
                  "message": message,
                }),
              );
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("InfuMedz Support")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                bool isUser = msg["type"] == "USER";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Color(0xFF0E5FD8) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["message"],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: controller)),
              IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminTicketListScreen extends StatefulWidget {
  @override
  _AdminTicketListScreenState createState() => _AdminTicketListScreenState();
}

class _AdminTicketListScreenState extends State<AdminTicketListScreen> {
  List tickets = [];

  @override
  void initState() {
    super.initState();
    loadTickets();
  }

  Future<void> loadTickets() async {
    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/support/tickets/"),
    );

    if (res.statusCode == 200) {
      setState(() {
        tickets = jsonDecode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Support Tickets")),
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (_, index) {
          final ticket = tickets[index];

          return ListTile(
            title: Text(ticket["user_name"]),
            subtitle: Text(ticket["message"]),
            trailing: ticket["resolved"]
                ? Icon(Icons.check, color: Colors.green)
                : Icon(Icons.pending),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReplyScreen(ticket: ticket),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminReplyScreen extends StatelessWidget {
  final Map ticket;
  final TextEditingController replyController = TextEditingController();

  AdminReplyScreen({required this.ticket});

  Future<void> sendReply() async {
    await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/support/reply/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ticket_id": ticket["id"],
        "reply": replyController.text.trim(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reply")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("User: ${ticket["user_name"]}"),
            SizedBox(height: 10),
            Text(ticket["message"]),
            TextField(controller: replyController),
            ElevatedButton(onPressed: sendReply, child: Text("Send Reply")),
          ],
        ),
      ),
    );
  }
}
