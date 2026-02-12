import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infumedz/loginsignup.dart';
import 'package:http/http.dart' as http;

class UserChatScreen extends StatefulWidget {
  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  List messages = [];
  List suggestions = [];
  TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> loadHistory() async {
    final userId = await UserSession.getUserId();

    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/chat/history/$userId/"),
    );

    if (res.statusCode == 200) {
      setState(() {
        messages = jsonDecode(res.body);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> sendMessage(String text) async {
    final userId = await UserSession.getUserId();

    setState(() {
      messages.add({"message": text, "message_type": "USER"});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    final res = await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/chat/message/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "message": text}),
    );

    final data = jsonDecode(res.body);

    if (data["type"] == "BOT") {
      setState(() {
        messages.add({"message": data["reply"], "message_type": "BOT"});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      // Add fallback bot message
      setState(() {
        messages.add({
          "message":
              "Your query was not understood. Would you like to contact academic support?",
          "message_type": "BOT_FALLBACK",
        });
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void showTicketDialog() {
    final TextEditingController ticketController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contact Academic Support",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ticketController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter your detailed query...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (ticketController.text.trim().isEmpty) return;

                      Navigator.pop(context);

                      final userId = await UserSession.getUserId();

                      final res = await http.post(
                        Uri.parse(
                          "https://api.chandus7.in/api/infumedz/chat/ticket/create/",
                        ),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "user_id": userId,
                          "subject": "Academic Support",
                          "message": ticketController.text.trim(),
                        }),
                      );

                      if (res.statusCode == 200) {
                        setState(() {
                          messages.add({
                            "message":
                                "Support ticket submitted successfully. Our academic team will contact you soon.",
                            "message_type": "BOT",
                          });

                          messages.add({
                            "message": ticketController.text.trim(),
                            "message_type": "USER_TICKET",
                          });
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error submitting ticket"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5FD8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Submit Ticket"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMessage(Map msg) {
    String type = msg["message_type"];

    bool isUser = msg["message_type"].toString().startsWith("USER");

    bool isFallback = type == "BOT_FALLBACK";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0E5FD8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.05)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg["message"],
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),

            if (isFallback) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => showTicketDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5FD8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Contact Academic Support"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0E5FD8),
        title: const Text(
          "InfuMedz Academic Support",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          /// CHAT AREA
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      "Ask your academic question below",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => buildMessage(messages[i]),
                  ),
          ),

          /// INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type your question...",
                      filled: true,
                      fillColor: const Color(0xFFF2F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0E5FD8),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      sendMessage(controller.text.trim());
                      controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Color(0xFF0E5FD8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            adminCard(
              title: "Support Tickets",
              icon: Icons.support_agent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminTicketScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            adminCard(
              title: "Manage FAQ",
              icon: Icons.question_answer,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminFAQScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget adminCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Color(0xFF0E5FD8)),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminFAQScreen extends StatefulWidget {
  @override
  _AdminFAQScreenState createState() => _AdminFAQScreenState();
}

class _AdminFAQScreenState extends State<AdminFAQScreen> {
  TextEditingController question = TextEditingController();
  TextEditingController answer = TextEditingController();

  List faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFAQs();
  }

  Future<void> loadFAQs() async {
    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/faq/list/"),
    );

    if (res.statusCode == 200) {
      setState(() {
        faqs = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  Future<void> addFAQ() async {
    if (question.text.trim().isEmpty || answer.text.trim().isEmpty) return;

    final adminId = await UserSession.getUserId();

    await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/faq/add/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "admin_id": adminId,
        "question": question.text.trim(),
        "answer": answer.text.trim(),
      }),
    );

    question.clear();
    answer.clear();
    loadFAQs();
  }

  Future<void> deleteFAQ(String id) async {
    await http.delete(
      Uri.parse("https://api.chandus7.in/api/infumedz/faq/delete/$id/"),
    );

    loadFAQs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("Manage Chatbot FAQ"),
        backgroundColor: const Color(0xFF0E5FD8),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 🔹 ADD NEW FAQ CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Add New FAQ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: question,
                          decoration: InputDecoration(
                            labelText: "User Question",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: answer,
                          decoration: InputDecoration(
                            labelText: "Bot Reply",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: addFAQ,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5FD8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Add FAQ"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// 🔹 LIST ALL EXISTING FAQS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Existing FAQs",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ...faqs.map((faq) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.04),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  faq["question"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteFAQ(faq["id"]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            faq["answer"],
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}

class AdminTicketScreen extends StatefulWidget {
  @override
  _AdminTicketScreenState createState() => _AdminTicketScreenState();
}

class _AdminTicketScreenState extends State<AdminTicketScreen> {
  List tickets = [];

  @override
  void initState() {
    super.initState();
    loadTickets();
  }

  Future<void> loadTickets() async {
    final adminId = await UserSession.getUserId();

    final res = await http.get(
      Uri.parse(
        "https://api.chandus7.in/api/infumedz/tickets/?user_id=$adminId",
      ),
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
        reverse: true,

        itemCount: tickets.length,
        itemBuilder: (_, i) {
          final ticket = tickets[i];

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(ticket["user_name"]),
              subtitle: Text(ticket["message"]),
              trailing: Text(ticket["status"]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminReplyScreen(ticket: ticket),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminReplyScreen extends StatefulWidget {
  final Map ticket;

  const AdminReplyScreen({super.key, required this.ticket});

  @override
  State<AdminReplyScreen> createState() => _AdminReplyScreenState();
}

class _AdminReplyScreenState extends State<AdminReplyScreen> {
  final TextEditingController replyController = TextEditingController();
  bool isSending = false;

  Future<void> sendReply() async {
    if (replyController.text.trim().isEmpty) return;

    setState(() => isSending = true);

    final adminId = await UserSession.getUserId();

    final res = await http.post(
      Uri.parse("https://api.chandus7.in/api/infumedz/ticket/reply/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "admin_id": adminId,
        "ticket_id": widget.ticket["id"],
        "reply": replyController.text.trim(),
      }),
    );

    setState(() => isSending = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reply Sent Successfully")));

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error sending reply")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("Ticket Details"),
        backgroundColor: const Color(0xFF0E5FD8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Ticket Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User: ${ticket["user_name"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "Subject: ${ticket["subject"] ?? "General Support"}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "User Message:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    ticket["message"],
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Status: "),
                      Text(
                        ticket["status"],
                        style: TextStyle(
                          color: ticket["status"] == "RESOLVED"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Reply Box
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Admin Reply",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: TextField(
                      controller: replyController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: "Type your response to the user...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending ? null : sendReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5FD8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Send Reply",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
