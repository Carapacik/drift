import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'model.dart';

class MoorTrigger implements MoorSchemaEntity {
  @override
  final String displayName;

  @override
  final Declaration declaration;

  /// The table on which this trigger operates.
  ///
  /// This field can be null in case the table wasn't resolved.
  MoorTable on;

  MoorTrigger(this.displayName, this.declaration, this.on);

  factory MoorTrigger.fromMoor(CreateTriggerStatement stmt, FoundFile file) {
    return MoorTrigger(
      stmt.triggerName,
      MoorTriggerDeclaration.fromNodeAndFile(stmt, file),
      null, // must be resolved later
    );
  }

  @override
  Iterable<MoorSchemaEntity> get references => [on];
}
