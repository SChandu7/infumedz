import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:infumedz/library.dart';
import 'package:infumedz/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'loginsignup.dart';


/// =======================================================
/// USER SESSION (FIXED KEYS)
/// =======================================================



/// =======================================================
/// MAIN PROFILE SCREEN
/// =======================================================
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ProfileHeader(),

            SizedBox(height: 28),
            _SectionTitle("Account"),
            SizedBox(height: 12),
            _AccountCard(),

            SizedBox(height: 28),
            _SectionTitle("Support"),
            SizedBox(height: 12),
            _SupportCard(),
             SizedBox(height: 40),
 _AppFooter(),
 SizedBox(height: 54),

          ],
        ),
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

 

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// APP NAME
          Center(
            child: const Text(
              "InfuMedz",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: const Text(
              "Smart Medical Learning Platform",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// QUICK LINKS
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: const [
                _FooterLink("About Us"),
                _FooterLink("Privacy Policy"),
               
              ],
            ),
          ),
                    const SizedBox(height: 10),

           Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: const [
               
                _FooterLink("Terms & Conditions"),
                _FooterLink("Help Center"),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),

          const SizedBox(height: 14),

          /// SUPPORT
          const Text(
            "Support",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "support@infumedz.com",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          const Text(
            "+91 9XXXXXXXXX",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),


          /// LOGOUT BUTTON
         

          const SizedBox(height: 14),

          /// COPYRIGHT
          Center(
            child: Text(
              "© 2026 InfuMedz. All rights reserved.",
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4F46E5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


/// ==============
/// =======================================================
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  String name = "User";
  String email = "user@email.com";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    name = await UserSession.getUsername() ?? name;
    email = await UserSession.getUseremail() ?? email;
    setState(() {});
  }

  void _edit(BuildContext context) {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(n, "Name", Icons.person),
            const SizedBox(height: 14),
            _field(e, "Email", Icons.email),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await UserSession.saveUsername(n.text.trim());
              await UserSession.saveUseremail(e.text.trim());
              name = n.text.trim();
              email = e.text.trim();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFEEF2FF),
            child: ClipOval(
              child: Image.asset(
                "assets/imgicon1.png",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit),
            label: const Text("Edit"),
          )
        ],
      ),
    );
  }
}


/// =======================================================
/// ACCOUNT CARD (DIALOG FIXED)
/// =======================================================
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  void _openAccountDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const UserAccountDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _Tile(Icons.person_outline, "Account Information",
              () => _openAccountDialog(context)),
          const _Divider(),
          _Tile(Icons.shopping_bag_outlined, "My Orders", () {
            Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => const LibraryPage(),
    ),
  );
          }),
          const _Divider(),
          _Tile(Icons.settings_outlined, "Settings", () {}),
        ],
      ),
    );
  }
}


/// =======================================================
/// ACCOUNT DETAILS DIALOG (API CONNECTED)
/// =======================================================
class UserAccountDialog extends StatefulWidget {
  const UserAccountDialog({super.key});

  @override
  State<UserAccountDialog> createState() => _UserAccountDialogState();
}

class _UserAccountDialogState extends State<UserAccountDialog> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await UserSession.getUserId();
    final res = await http.get(Uri.parse("https://api.chandus7.in/user/?user_id=$id"));

    if (res.statusCode == 200) {
      user = jsonDecode(res.body)["user"];
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _info("Name", user?["name"]),
                  _info("Email", user?["email"]),
                  _info("Phone", user?["phone"]),
                  _info("User ID", user?["id"]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  )
                ],
              ),
      ),
    );
  }

  Widget _info(String l, String? v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(color: Colors.grey)),
          Text(v ?? "-", style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}


/// =======================================================
/// SUPPORT CARD
/// =======================================================
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _Tile(Icons.help_outline, "Help Center", () {}),
          const _Divider(),
          _Tile(Icons.logout, "Logout", () async {
           showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: const Text(
        "Are you sure you want to logout?",
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("No"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            await UserSession.logout();

            Navigator.pop(context); // close dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          },
          child: const Text(
            "Yes, Logout",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
          }, isLogout: false),
        ],
      ),
    );
  }
}


/// =======================================================
/// REUSABLE WIDGETS
/// =======================================================
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _Tile(this.icon, this.title, this.onTap, {this.isLogout = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blueGrey),
      title: Text(title,
          style: TextStyle(color: isLogout ? Colors.red : Colors.black)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

Widget _field(TextEditingController c, String l, IconData i) => TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}

class _SectionTitle extends StatelessWidget {
  final String t;
  const _SectionTitle(this.t);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(left: 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)));
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
    );
