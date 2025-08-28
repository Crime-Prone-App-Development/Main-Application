import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:mainapp/token_helper.dart';

class DeleteUserPage extends StatefulWidget {
  const DeleteUserPage({super.key});

  @override
  State<DeleteUserPage> createState() => _DeleteUserPageState();
}

class _DeleteUserPageState extends State<DeleteUserPage> {
  List<Map<String, dynamic>> users = [];
  String searchQuery = "";
  bool isLoading = true;

  Future<void> fetchUsers() async {
    try {
      final token = await TokenHelper.getToken();
      final response = await http.get(
        Uri.parse("${dotenv.env["BACKEND_URI"]}/users"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          users = data
              .map((user) => {
                    "id": user["_id"].toString(),
                    "name": user["name"],
                    "badge": user["badgeNumber"].toString(),
                    "phone": user["phoneNumber"].toString(),
                  })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch users");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteUser(String id, String name) async {
    try {
      final token = await TokenHelper.getToken();
      final response = await http.delete(
        Uri.parse("${dotenv.env["BACKEND_URI"]}/users/$id"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          users.removeWhere((u) => u["id"] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name deleted successfully")),
        );
      } else {
        throw Exception("Failed to delete user");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((user) {
      final query = searchQuery.toLowerCase();
      return user["name"].toLowerCase().contains(query) ||
          user["badge"].toLowerCase().contains(query) ||
          user["phone"].toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Users",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 2,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: "Search by name, badge, phone...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),

                // 🖥️ Responsive Users List
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // If width > 600 → show DataTable (desktop/tablet)
                      if (constraints.maxWidth > 600) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.red.shade50),
                            columns: const [
                              DataColumn(label: Text("Name")),
                              DataColumn(label: Text("Badge")),
                              DataColumn(label: Text("Phone Number")),
                              DataColumn(label: Text("Action")),
                            ],
                            rows: filteredUsers.map((user) {
                              return DataRow(cells: [
                                DataCell(Text(user["name"])),
                                DataCell(Text(user["badge"])),
                                DataCell(Text(user["phone"])),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _confirmDelete(user);
                                    },
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        );
                      } else {
                        // Mobile / small screen → show cards
                        return filteredUsers.isEmpty
                            ? const Center(
                                child: Text(
                                  "No users found",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 3,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.red.shade200,
                                        child: Text(
                                          user["name"][0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        user["name"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text("Badge: ${user["badge"]}"),
                                          Text("Phone: ${user["phone"]}"),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 28),
                                        onPressed: () {
                                          _confirmDelete(user);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // 🗑️ Confirmation Dialog before delete
  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Confirm Delete"),
          ],
        ),
        content: Text("Are you sure you want to delete ${user["name"]}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteUser(user["id"], user["name"]);
            },
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
