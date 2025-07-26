import 'package:flutter/material.dart';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OfficersTablePage extends StatefulWidget {
  final List<dynamic>? initialSelectedOfficers;

  const OfficersTablePage({Key? key, this.initialSelectedOfficers})
      : super(key: key);

  @override
  State<OfficersTablePage> createState() => _OfficersTablePageState();
}

class _OfficersTablePageState extends State<OfficersTablePage> {
  List<dynamic> allOfficers = [];
  bool officersLoaded = false;
  List<dynamic> selectedOfficers = [];
  List<dynamic> filteredOfficers = [];
  List<dynamic> filteredSelectedOfficers = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _selectedSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllUsers(context);
    selectedOfficers = widget.initialSelectedOfficers ?? [];
    filteredSelectedOfficers = List.from(selectedOfficers);
    _searchController.addListener(_filterOfficers);
    _selectedSearchController.addListener(_filterSelectedOfficers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedSearchController.dispose();
    super.dispose();
  }

  void _filterOfficers() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredOfficers = List.from(allOfficers.where((officer) =>
            !selectedOfficers
                .any((selected) => selected["_id"] == officer["_id"])));
      });
      return;
    }

    setState(() {
      filteredOfficers = allOfficers.where((officer) {
        return !selectedOfficers
                .any((selected) => selected["_id"] == officer["_id"]) &&
            officer.values.any((value) =>
                value != null &&
                value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  void _filterSelectedOfficers() {
    final query = _selectedSearchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredSelectedOfficers = List.from(selectedOfficers);
      });
      return;
    }

    setState(() {
      filteredSelectedOfficers = selectedOfficers.where((officer) {
        return officer.values.any((value) =>
            value != null && value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  void _addOfficer(Map<String, dynamic> officer) {
    setState(() {
      selectedOfficers.add(officer);
      filteredSelectedOfficers = List.from(selectedOfficers);
      filteredOfficers.removeWhere((o) => o["_id"] == officer["_id"]);
    });
  }

  void _removeOfficer(Map<String, dynamic> officer) {
    setState(() {
      selectedOfficers.removeWhere((o) => o["_id"] == officer["_id"]);
      filteredSelectedOfficers = List.from(selectedOfficers);
      if (!allOfficers.any((o) => o["_id"] == officer["_id"])) {
        allOfficers.add(officer);
      }
      filteredOfficers = List.from(allOfficers.where((o) =>
          !selectedOfficers.any((selected) => selected["_id"] == o["_id"])));
    });
  }

  Future<void> getAllUsers(BuildContext context) async {
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          allOfficers = responseData['data'] ?? [];
          filteredOfficers = List.from(allOfficers.where((officer) =>
              !selectedOfficers
                  .any((selected) => selected["_id"] == officer["_id"])));
          officersLoaded = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load officers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Officer Selection',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 67, 156, 234),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  indicatorColor: Colors.white,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.people_outline,
                        color: Colors.white,
                      ),
                      text: 'Available',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      text: 'Selected',
                    ),
                  ],
                ),
                Container(
                  height: 48, // Fixed height for the button row
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Selected: ${selectedOfficers.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      if (selectedOfficers.isNotEmpty)
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, selectedOfficers),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            'Confirm Selection',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Available Officers Tab
            _buildOfficerTab(
              controller: _searchController,
              hintText: 'Search available officers...',
              officersList: filteredOfficers,
              isSelectedTab: false,
              isLoading: !officersLoaded,
              isEmpty: allOfficers.isEmpty,
            ),
            // Selected Officers Tab
            _buildOfficerTab(
              controller: _selectedSearchController,
              hintText: 'Search selected officers...',
              officersList: filteredSelectedOfficers,
              isSelectedTab: true,
              isLoading: false,
              isEmpty: selectedOfficers.isEmpty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerTab({
    required TextEditingController controller,
    required String hintText,
    required List<dynamic> officersList,
    required bool isSelectedTab,
    required bool isLoading,
    required bool isEmpty,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => controller.clear(),
                    )
                  : null,
            ),
          ),
          SizedBox(height: 16),
          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading officers...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelectedTab
                          ? Icons.people_outline
                          : Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      isSelectedTab
                          ? 'No officers selected yet'
                          : 'No officers available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: isSmallScreen
                  ? _buildMobileList(officersList, isSelectedTab)
                  : _buildDataTable(officersList, isSelectedTab),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> officersList, bool isSelectedTab) {
    return SingleChildScrollView(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            dataRowHeight: 64,
            headingRowHeight: 56,
            headingRowColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.grey.shade100,
            ),
            columns: [
              DataColumn(label: _buildHeaderText("ID")),
              DataColumn(label: _buildHeaderText("Name")),
              DataColumn(label: _buildHeaderText("Badge")),
              DataColumn(label: _buildHeaderText("Phone")),
              DataColumn(label: _buildHeaderText("")),
            ],
            rows: officersList.map((officer) {
              return DataRow(
                cells: [
                  DataCell(_buildCellText(officer["_id"]?.toString() ?? 'N/A')),
                  DataCell(
                      _buildCellText(officer["name"]?.toString() ?? 'N/A')),
                  DataCell(_buildCellText(
                      officer["badgeNumber"]?.toString() ?? 'N/A')),
                  DataCell(_buildCellText(
                      officer["phoneNumber"]?.toString() ?? 'N/A')),
                  DataCell(
                    isSelectedTab
                        ? _buildActionButton(
                            text: 'Remove',
                            icon: Icons.remove_circle_outline,
                            color: Colors.red,
                            onPressed: () => _removeOfficer(officer),
                          )
                        : _buildActionButton(
                            text: 'Add',
                            icon: Icons.add_circle_outline,
                            color: Theme.of(context).primaryColor,
                            onPressed: () => _addOfficer(officer),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<dynamic> officersList, bool isSelectedTab) {
    return ListView.builder(
      itemCount: officersList.length,
      itemBuilder: (context, index) {
        final officer = officersList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileRow("ID", officer["_id"]?.toString() ?? 'N/A'),
                _buildMobileRow("Name", officer["name"]?.toString() ?? 'N/A'),
                _buildMobileRow(
                    "Badge", officer["badgeNumber"]?.toString() ?? 'N/A'),
                _buildMobileRow(
                    "Phone", officer["phoneNumber"]?.toString() ?? 'N/A'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: isSelectedTab
                      ? _buildActionButton(
                          text: 'Remove',
                          icon: Icons.remove_circle_outline,
                          color: Colors.red,
                          onPressed: () => _removeOfficer(officer),
                        )
                      : _buildActionButton(
                          text: 'Add',
                          icon: Icons.add_circle_outline,
                          color: Theme.of(context).primaryColor,
                          onPressed: () => _addOfficer(officer),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMobileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCellText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14),
    );
  }
}
