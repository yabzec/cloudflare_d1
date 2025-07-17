import 'package:cloudflare_d1/cloudflare_d1.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'd1_database.test.mocks.dart';

@GenerateNiceMocks([MockSpec<D1Client>()])
void main() {
  late D1Database db;
  late MockD1Client client;

  setUp(() async {
    client = MockD1Client();
    db = D1Database(client);
    when(
      client.query(any, any),
    ).thenAnswer((_) => Future.value(D1Response(success: true, results: [])));
  });

  test("SELECT string composition", () async {
    final List<dynamic> whereParams = ["user_test", true];
    await db.select(
      "sessions",
      columns: ["id"],
      where: "username = ? AND active = ?",
      whereParams: whereParams,
      groupBy: "id",
      orderBy: "date",
      limit: 5,
      offset: 1,
      distinct: true,
    );
    verify(
      client.query(
        "SELECT DISTINCT id FROM sessions WHERE username = ? AND active = ? GROUP BY id ORDER BY date LIMIT 5 OFFSET 1",
        whereParams,
      ),
    );
  });

  test("SELECT result has values", () async {
    final List<Map<String, dynamic>> results = [
      {"a": "test", "b": "test1"},
      {"a": "test3", "b": "test4"},
    ];
    final List<dynamic> whereParams = ["user_test", true];
    when(client.query(argThat(startsWith("SELECT")), any)).thenAnswer(
      (_) => Future.value(D1Response(success: true, results: results)),
    );
    expect(
      await db.select(
        "sessions",
        columns: ["id"],
        where: "username = ? AND active = ?",
        whereParams: whereParams,
        groupBy: "id",
        orderBy: "date",
        limit: 5,
        offset: 1,
        distinct: true,
      ),
      results,
    );
  });

  test("EXECUTE should not modify the query", () async {
    final List<dynamic> whereParams = [1];
    await db.execute("SELECT a FROM b WHERE c = ?", whereParams);
    verify(client.query("SELECT a FROM b WHERE c = ?", whereParams));
  });

  test("INSERT string composition", () async {
    await db.insert("a", {"b": 1, "c": 2});
    verify(client.query("INSERT INTO a (b, c) VALUES (?, ?)", [1, 2]));
  });

  test("UPDATE string composition", () async {
    await db.update(
      "a",
      {"b": 1, "c": 2},
      where: "d = ?",
      whereParams: ["test"],
    );
    verify(
      client.query("UPDATE a SET b = ?, c = ? WHERE d = ?", [1, 2, "test"]),
    );
  });

  test("DELETE string composition", () async {
    await db.delete("a", where: "d = ?", whereParams: ["test"]);
    verify(client.query("DELETE FROM a WHERE d = ?", ["test"]));
  });

  test("COUNT string composition", () async {
    await db.count("a", where: "d = ?", whereParams: ["test"]);
    verify(
      client.query("SELECT COUNT(*) as count FROM a WHERE d = ?", ["test"]),
    );
  });

  group("COUNT returns number of rows", () {
    test("COUNT result does not have values", () async {
      expect(await db.count("a", where: "d = ?", whereParams: ["test"]), 0);
    });

    test("COUNT result has values", () async {
      when(client.query(argThat(startsWith("SELECT COUNT")), any)).thenAnswer(
        (_) => Future.value(
          D1Response(
            success: true,
            results: [
              {"count": 10},
            ],
          ),
        ),
      );
      expect(await db.count("a", where: "d = ?", whereParams: ["test"]), 10);
    });
  });

  test("TABLE EXISTS string composition", () async {
    final String tableName = "a";
    await db.tableExists(tableName);
    verify(
      client.query(
        '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name=?
    ''',
        [tableName],
      ),
    );
  });

  group("TABLE EXISTS returns boolean", () {
    test("Table does not exists", () async {
      expect(await db.tableExists("my_table"), false);
    });

    test("Table exists", () async {
      when(
        client.query(
          argThat(
            startsWith('''
      SELECT name FROM sqlite_master'''),
          ),
          any,
        ),
      ).thenAnswer(
        (_) => Future.value(
          D1Response(
            success: true,
            results: [
              {"name": "my_table"},
            ],
          ),
        ),
      );
      expect(await db.tableExists("my_table"), true);
    });
  });

  test("TABLE SCHEMA string composition", () async {
    final String tableName = "a";
    await db.getTableSchema(tableName);
    verify(client.query("PRAGMA table_info($tableName)"));
  });

  group("TABLE SCHEMA returns data", () {
    test("Table does not exists", () async {
      expect(await db.getTableSchema("my_table"), []);
    });

    test("Table exists", () async {
      final List<Map<String, dynamic>> results = [
        {"name": "my_table"},
      ];
      when(
        client.query(argThat(startsWith("PRAGMA table_info")), any),
      ).thenAnswer(
        (_) => Future.value(D1Response(success: true, results: results)),
      );
      expect(await db.getTableSchema("my_table"), results);
    });
  });

  test("CREATE TABLE string composition", () async {
    final String tableName = "a";
    await db.createTable(
      tableName,
      {"a": "INTEGER", "b": "TEXT", "c": "DATETIME"},
      primaryKey: "a",
      uniqueColumns: ["b"],
      foreignKeys: {"c": "test.d"},
    );
    verify(
      client.query(
        "CREATE TABLE a (a INTEGER, b TEXT, c DATETIME, PRIMARY KEY (a), UNIQUE (b), FOREIGN KEY (c) REFERENCES test.d)",
      ),
    );
  });

  group("DROP TABLE string composition", () {
    test("if exists true", () async {
      final String tableName = "a";
      await db.dropTable(tableName);
      verify(client.query("DROP TABLE IF EXISTS a"));
    });

    test("if exists false", () async {
      final String tableName = "a";
      await db.dropTable(tableName, ifExists: false);
      verify(client.query("DROP TABLE a"));
    });
  });

  group("FIND BY ID string composition", () {
    test("default id column name", () async {
      final int id = 10;
      await db.findById("a", id);
      verify(client.query("SELECT * FROM a WHERE id = ? LIMIT 1", [id]));
    });

    test("custom id column name", () async {
      final int id = 10;
      final String idColumn = "test";
      await db.findById("a", id, idColumn: idColumn);
      verify(client.query("SELECT * FROM a WHERE $idColumn = ? LIMIT 1", [id]));
    });
  });

  test("FIND BY string composition", () async {
    final int id = 10;
    await db.findBy("a", "b", id, columns: ["d"], limit: 10, orderBy: "c");
    verify(
      client.query("SELECT d FROM a WHERE b = ? ORDER BY c LIMIT 10", [id]),
    );
  });

  test("EXISTS string composition", () async {
    final List<int> params = [10];
    await db.exists("a", where: "b = ?", whereParams: params);
    verify(client.query("SELECT COUNT(*) as count FROM a WHERE b = ?", params));
  });

  test("FIRST string composition", () async {
    final List<int> params = [10];
    await db.first("a", where: "b = ?", whereParams: params, orderBy: "d");
    verify(
      client.query("SELECT * FROM a WHERE b = ? ORDER BY d LIMIT 1", params),
    );
  });
}
