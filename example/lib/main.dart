import 'package:flutter/material.dart';
import 'package:cloudflare_d1/cloudflare_d1.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloudflare D1 Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: D1ExamplePage(),
    );
  }
}

class D1ExamplePage extends StatefulWidget {
  @override
  _D1ExamplePageState createState() => _D1ExamplePageState();
}

class _D1ExamplePageState extends State<D1ExamplePage> {
  late D1Database database;
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void _initializeDatabase() {

    final config = D1Config(
      accountId: 'your-account-id',
      databaseId: 'your-database-id',
      apiToken: 'your-api-token',
    );

    final client = D1Client(config: config);
    database = D1Database(client);

    _setupDatabase();
  }

  Future<void> _setupDatabase() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Create users table if it doesn't exist
      await database.createTable(
        'users',
        {
          'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
          'name': 'TEXT NOT NULL',
          'email': 'TEXT UNIQUE NOT NULL',
          'created_at': 'DATETIME DEFAULT CURRENT_TIMESTAMP',
        },
      );

      await _loadUsers();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final results = await database.select(
        'users',
        orderBy: 'created_at DESC',
      );

      setState(() {
        users = results;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> _addUser(String name, String email) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      await database.insert('users', {
        'name': name,
        'email': email,
      });

      await _loadUsers();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      await database.delete(
        'users',
        where: 'id = ?',
        whereParams: [id],
      );

      await _loadUsers();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isNotEmpty && email.isNotEmpty) {
                Navigator.pop(context);
                _addUser(name, email);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cloudflare D1 Example'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          if (error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Text(
                'Error: $error',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),

          if (isLoading)
            LinearProgressIndicator(),

          Expanded(
            child: users.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some users to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user['name']),
                    subtitle: Text(user['email']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    database.dispose();
    super.dispose();
  }
}
