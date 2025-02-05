import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(include: {'src/tables.drift'})
class MyDatabase extends _$MyDatabase {
  MyDatabase(DatabaseConnection super.e);

  @override
  int get schemaVersion => 1;
}
