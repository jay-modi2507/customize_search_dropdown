import 'package:customize_search_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Dropdown Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Demo Data Models
  String? _selectedLocalItem;
  User? _selectedApiItem;
  List<String> _selectedMultiItems = [];

  // Local Data
  final List<String> _localItems = [
    "Apple",
    "Banana",
    "Cherry",
    "Date",
    "Elderberry",
    "Fig",
    "Grape",
    "Honeydew",
    "Kiwi",
    "Lemon",
    "Mango",
    "Nectarine",
    "Orange",
    "Papaya",
    "Quince",
    "Raspberry",
    "Strawberry",
    "Tangerine",
    "Ugli Fruit",
    "Vanilla Bean",
    "Watermelon",
  ];

  // API Simulation
  Future<List<User>> _getUsers(int page, String? query) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Simulate a large database of users
    final List<User> allUsers = List.generate(
      100,
      (index) =>
          User(id: index, name: "User $index", email: "user$index@example.com"),
    );

    // Filter
    final filtered =
        query == null || query.isEmpty
            ? allUsers
            : allUsers
                .where(
                  (u) => u.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

    // Pagination
    const pageSize = 10;
    final start = (page - 1) * pageSize;
    if (start >= filtered.length) return [];

    final end = start + pageSize;
    return filtered.sublist(
      start,
      end > filtered.length ? filtered.length : end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Dropdown Demo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "1. Simple Local Data Dropdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            CustomDropdown<String>(
              hintText: "Select Fruit",
              items: _localItems,
              selectedItem: _selectedLocalItem,
              onChanged: (value) {
                setState(() => _selectedLocalItem = value);
              },
              headerDecoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "2. Multi-Selection Dropdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            CustomDropdown<String>(
              hintText: "Select Multiple Fruits",
              items: _localItems,
              enableMultiSelection: true,
              selectedItems: _selectedMultiItems,
              onListChanged: (value) {
                setState(() => _selectedMultiItems = value);
              },
              headerDecoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "3. API Pagination + Search Dropdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Simulates network delay and pagination (10 per page)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            CustomDropdown<User>(
              hintText: "Select User (Async)",
              searchHintText: "Search by name...",
              futureRequest: _getUsers,
              itemsPerPage: 10,
              selectedItem: _selectedApiItem,

              // Custom Label Function
              itemLabel: (user) => user.name,

              onChanged: (value) {
                setState(() => _selectedApiItem = value);
              },

              // Custom List Item using the builder
              listItemBuilder: (context, item, isSelected, onTap) {
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.deepPurple.withValues(alpha: 0.1),
                  onTap: onTap,
                  leading: CircleAvatar(child: Text(item.name[0])),
                  title: Text(item.name),
                  subtitle: Text(item.email),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check, color: Colors.deepPurple)
                          : null,
                );
              },
            ),

            const SizedBox(height: 40),

            const Text(
              "4. Custom Styling & Header",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            CustomDropdown<String>(
              hintText: "Styled Dropdown",
              items: _localItems,
              selectedItem: _selectedLocalItem,
              onChanged: (value) {
                setState(() => _selectedLocalItem = value);
              },
              headerBuilder: (context, selectedItem, selectedItems) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedItem ?? "Choose Awesome Fruit",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_circle,
                        color: Colors.white,
                      ),
                    ],
                  ),
                );
              },
              dropdownDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 400), // Spacing to test scrolling behavior
          ],
        ),
      ),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  @override
  String toString() => name;
}
