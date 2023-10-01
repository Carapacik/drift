import 'package:test/test.dart';
import 'package:drift_dev/api/migrations.dart';

import '../migrations.dart';
import 'generated_migrations/schema.dart';

// #docregion imports
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
// #enddocregion imports

// #docregion main
void main() {
// #enddocregion main
  late SchemaVerifier verifier;

  setUpAll(() {
    // GeneratedHelper() was generated by drift, the verifier is an api
    // provided by drift_dev.
    verifier = SchemaVerifier(GeneratedHelper());
  });

// #docregion main
  // ...
  test('upgrade from v1 to v2', () async {
    final schema = await verifier.schemaAt(1);

    // Add some data to the table being migrated
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.into(oldDb.todos).insert(v1.TodosCompanion.insert(
          title: 'my first todo entry',
          content: 'should still be there after the migration',
        ));
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = MyDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();

    // Make sure the entry is still here
    final migratedDb = v2.DatabaseAtV2(schema.newConnection());
    final entry = await migratedDb.select(migratedDb.todos).getSingle();
    expect(entry.id, 1);
    expect(entry.dueDate, isNull); // default from the migration
    await migratedDb.close();
  });
}
// #enddocregion main