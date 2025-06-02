# Cloudflare D1 Flutter Package

A Flutter package for interacting with Cloudflare D1 databases via REST API.

## Features

- ✅ **Type Safety**: Strongly typed responses and configurations
- ✅ **High-Level Operations**: Built-in methods for common database operations
- ✅ **Batch Operations**: Execute multiple queries efficiently
- ✅ **Error Handling**: Comprehensive error handling with custom exceptions
- ✅ **Prepared Statements**: Support for parameterized queries
- ✅ **Schema Management**: Table creation, modification, and introspection

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  cloudflare_d1:
    git:
      url: https://github.com/username/repository.git
      ref: nome-branch
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Configuration

```dart
final config = D1Config(
  accountId: 'your-cloudflare-account-id',
  databaseId: 'your-d1-database-id',
  apiToken: 'your-cloudflare-api-token',
);
```

### 2. Initialize Client and Database

```dart
final client = D1Client(config: config);
final database = D1Database(client);
```

### 3. Basic Operations

#### Create a Table

```dart
await database.createTable(
  'users',
  {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'email': 'TEXT UNIQUE NOT NULL',
    'created_at': 'DATETIME DEFAULT CURRENT_TIMESTAMP',
  },
);
```

#### Insert Data

```dart
final response = await database.insert('users', {
  'name': 'John Doe',
  'email': 'john@example.com',
});

print('Inserted with ID: ${response.lastRowId}');
```

#### Query Data

```dart
// Select all users
final allUsers = await database.select('users');

// Select with conditions
final activeUsers = await database.select(
  'users',
  where: 'status = ?',
  whereParams: ['active'],
  orderBy: 'created_at DESC',
  limit: 10,
);

// Find by ID
final user = await database.findById('users', 1);
```

#### Update Data

```dart
final response = await database.update(
  'users',
  {'name': 'Jane Doe', 'email': 'jane@example.com'},
  where: 'id = ?',
  whereParams: [1],
);

print('Updated ${response.changes} rows');
```

#### Delete Data

```dart
final response = await database.delete(
  'users',
  where: 'id = ?',
  whereParams: [1],
);

print('Deleted ${response.changes} rows');
```

## Advanced Usage

### Raw SQL Queries

```dart
// Simple query
final response = await database.execute('SELECT * FROM users WHERE age > 18');

// Parameterized query
final response = await database.execute(
  'SELECT * FROM users WHERE status = ? AND created_at > ?',
  ['active', DateTime.now().subtract(Duration(days: 30)).toIso8601String()],
);

// Access results
for (final row in response.allResults) {
  print('User: ${row['name']} (${row['email']})');
}
```

### Batch Operations

```dart
final queries = [
  D1Query.simple('SELECT COUNT(*) FROM users'),
  D1Query.simple('SELECT COUNT(*) FROM posts'),
  D1Query.withParams('SELECT * FROM users WHERE id = ?', [1]),
];

final results = await database.batch(queries);
for (final result in results) {
  print('Query result: ${result.allResults}');
}
```

### Schema Introspection

```dart
// Check if table exists
final exists = await database.tableExists('users');

// Get table schema
final schema = await database.getTableSchema('users');
for (final column in schema) {
  print('Column: ${column['name']} (${column['type']})');
}
```

## Error Handling

The package provides comprehensive error handling:

```dart
try {
  final result = await database.execute('SELECT * FROM non_existent_table');
} on D1Exception catch (e) {
  switch (e.runtimeType) {
    case D1Exception:
      if (e.statusCode != null) {
        print('API Error ${e.statusCode}: ${e.message}');
      } else {
        print('Database Error: ${e.message}');
      }
      if (e.details != null) {
        print('Details: ${e.details}');
      }
      break;
    default:
      print('Unknown error: $e');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Configuration Options

### D1Config Properties

| Property | Type | Description |
|----------|------|-------------|
| `accountId` | `String?` | Cloudflare account ID (for REST API) |
| `databaseId` | `String?` | D1 database ID (for REST API) |
| `apiToken` | `String?` | Cloudflare API token (for REST API) |
| `customHeaders` | `Map<String, String>` | Additional headers for requests |
| `timeout` | `Duration` | Request timeout (default: 30 seconds) |

## API Reference

### D1Database Methods

#### Query Operations
- `execute(sql, [params])` - Execute raw SQL
- `select(table, {options})` - Select records
- `insert(table, data)` - Insert a record
- `update(table, data, {where, whereParams})` - Update records
- `delete(table, {where, whereParams})` - Delete records
- `count(table, {where, whereParams})` - Count records

#### Utility Operations
- `findById(table, id)` - Find record by ID
- `findBy(table, field, value)` - Find records by field
- `first(table, {options})` - Get first matching record
- `exists(table, {where, whereParams})` - Check if records exist

#### Schema Operations
- `createTable(name, columns, {options})` - Create table
- `dropTable(name, {ifExists})` - Drop table
- `tableExists(name)` - Check if table exists
- `getTableSchema(name)` - Get table schema

#### Batch Operations
- `batch(queries)` - Execute multiple queries
