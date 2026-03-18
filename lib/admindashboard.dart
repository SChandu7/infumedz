// =====================================================
// lib/screens/admin_dashboard_screen.dart
// =====================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── Change this to your actual base URL ──────────────
const String kBaseUrl = 'https://api.chandus7.in';

// =====================================================
// DATA MODELS
// =====================================================

class DashboardStats {
  final int totalUsers;
  final int totalVideos;
  final int totalCourses;
  final int totalBooks;
  final int totalBuyers;
  final double totalRevenue;

  DashboardStats({
    required this.totalUsers,
    required this.totalVideos,
    required this.totalCourses,
    required this.totalBooks,
    required this.totalBuyers,
    required this.totalRevenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalVideos: json['total_videos'] ?? 0,
      totalCourses: json['total_courses'] ?? 0,
      totalBooks: json['total_books'] ?? 0,
      totalBuyers: json['total_buyers'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}

class RecentUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String joined;

  RecentUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.joined,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      joined: json['joined'] ?? '',
    );
  }
}

class RecentOrder {
  final String orderId;
  final String userName;
  final String userEmail;
  final String itemType;
  final String itemTitle;
  final String amount;
  final String status;
  final String purchasedAt;

  RecentOrder({
    required this.orderId,
    required this.userName,
    required this.userEmail,
    required this.itemType,
    required this.itemTitle,
    required this.amount,
    required this.status,
    required this.purchasedAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderId: json['order_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      itemType: json['item_type'] ?? '',
      itemTitle: json['item_title'] ?? '',
      amount: json['amount'] ?? '0',
      status: json['status'] ?? '',
      purchasedAt: json['purchased_at'] ?? '',
    );
  }
}

// =====================================================
// API SERVICE
// =====================================================

class DashboardService {
  static Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('$kBaseUrl/api/infumedz/dashboard/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
  }
}

// =====================================================
// MAIN SCREEN
// =====================================================

class AdminDashboarddetailsScreen extends StatefulWidget {
  const AdminDashboarddetailsScreen({super.key});

  @override
  State<AdminDashboarddetailsScreen> createState() =>
      _AdminDashboarddetailsScreenState();
}

class _AdminDashboarddetailsScreenState
    extends State<AdminDashboarddetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  DashboardStats? _stats;
  List<RecentUser> _recentUsers = [];
  List<RecentOrder> _recentOrders = [];
  List<RecentUser> _allUsers = [];

  late TabController _tabController;

  // Search / filter
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await DashboardService.fetchDashboard();

      setState(() {
        _stats = DashboardStats.fromJson(data['stats']);
        _recentUsers = (data['recent_users'] as List)
            .map((e) => RecentUser.fromJson(e))
            .toList();
        _recentOrders = (data['recent_orders'] as List)
            .map((e) => RecentOrder.fromJson(e))
            .toList();
        _allUsers = (data['all_users'] as List)
            .map((e) => RecentUser.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Theme colours ─────────────────────────────────
  static const Color _bg = Color(0xFF0F1117);
  static const Color _card = Color(0xFF1A1D27);
  static const Color _accent = Color(0xFF6C63FF);
  static const Color _green = Color(0xFF00D68F);
  static const Color _orange = Color(0xFFFF8C42);
  static const Color _pink = Color(0xFFFF4D6D);
  static const Color _blue = Color(0xFF4DC9FF);
  static const Color _text = Color(0xFFE8E8F0);
  static const Color _subtext = Color(0xFF8888AA);

  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        title: const Text(
          'Infumedz Admin',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _accent),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: _subtext,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrdersTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  // ── ERROR STATE ───────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _pink, size: 56),
          const SizedBox(height: 16),
          Text(
            'Could not load dashboard',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: const TextStyle(color: _subtext, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TAB 1 — OVERVIEW
  // =====================================================
  Widget _buildOverviewTab() {
    final s = _stats!;
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STAT CARDS GRID ──────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _statCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Total Users',
                  value: '${s.totalUsers}',
                  color: _blue,
                ),
                _statCard(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'Total Videos',
                  value: '${s.totalVideos}',
                  color: _orange,
                ),
                _statCard(
                  icon: Icons.school_rounded,
                  label: 'Courses',
                  value: '${s.totalCourses}',
                  color: _accent,
                ),
                _statCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Books',
                  value: '${s.totalBooks}',
                  color: _pink,
                ),
                _statCard(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Buyers',
                  value: '${s.totalBuyers}',
                  color: _green,
                ),
                _statCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Revenue',
                  value: '₹${_formatNumber(s.totalRevenue)}',
                  color: const Color(0xFFFFD700),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── RECENT SIGNUPS ───────────────────────
            _sectionHeader(
              'Recent Signups',
              Icons.person_add_alt_1_rounded,
              _blue,
            ),
            const SizedBox(height: 12),
            ..._recentUsers.map((u) => _userTile(u, showJoined: true)),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TAB 2 — ORDERS
  // =====================================================
  Widget _buildOrdersTab() {
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _loadDashboard,
      child: _recentOrders.isEmpty
          ? const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(color: _subtext, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _recentOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _orderTile(_recentOrders[i]),
            ),
    );
  }

  // =====================================================
  // TAB 3 — ALL USERS
  // =====================================================
  Widget _buildUsersTab() {
    final filtered = _allUsers
        .where(
          (u) =>
              u.name.toLowerCase().contains(_userSearch.toLowerCase()) ||
              u.email.toLowerCase().contains(_userSearch.toLowerCase()) ||
              u.phone.contains(_userSearch),
        )
        .toList();

    return Column(
      children: [
        // search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _userSearch = v),
            style: const TextStyle(color: _text),
            decoration: InputDecoration(
              hintText: 'Search by name, email or phone…',
              hintStyle: const TextStyle(color: _subtext, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _subtext),
              filled: true,
              fillColor: _card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // count chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length} users',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // list
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            backgroundColor: _card,
            onRefresh: _loadDashboard,
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: _subtext),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _userTile(filtered[i], showJoined: true),
                  ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // WIDGETS
  // =====================================================

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // ← fixes overflow
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _subtext,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // ← fixes overflow
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _userTile(RecentUser u, {bool showJoined = false}) {
    final initials = u.name.isNotEmpty
        ? u.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '??';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  u.email,
                  style: const TextStyle(color: _subtext, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  u.phone,
                  style: const TextStyle(color: _subtext, fontSize: 12),
                ),
              ],
            ),
          ),
          if (showJoined)
            Flexible(
              child: Text(
                u.joined,
                style: const TextStyle(color: _subtext, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderTile(RecentOrder o) {
    final isCourse = o.itemType == 'COURSE';
    final color = isCourse ? _accent : _orange;
    final icon = isCourse ? Icons.school_rounded : Icons.menu_book_rounded;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.itemTitle,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  o.userName,
                  style: const TextStyle(color: _subtext, fontSize: 13),
                ),
                Text(
                  o.userEmail,
                  style: const TextStyle(color: _subtext, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(o.itemType, color),
                    const SizedBox(width: 6),
                    _chip('₹${o.amount}', _green),
                    const Spacer(),
                    Text(
                      o.purchasedAt,
                      style: const TextStyle(color: _subtext, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────
  String _formatNumber(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
