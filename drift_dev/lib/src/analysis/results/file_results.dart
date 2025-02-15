import '../driver/error.dart';
import '../driver/state.dart';
import 'element.dart';
import 'query.dart';

class FileAnalysisResult {
  final List<DriftAnalysisError> analysisErrors = [];

  /// All elements either declared in this file or transitively imported.
  final List<DriftElement> allAvailableElements = [];

  final Map<DriftElementId, SqlQuery> resolvedQueries = {};
  final Map<DriftElementId, ResolvedDatabaseAccessor> resolvedDatabases = {};
}

class ResolvedDatabaseAccessor {
  Map<String, SqlQuery> definedQueries;
  final List<FileState> knownImports;
  final List<DriftElement> availableElements;

  ResolvedDatabaseAccessor(
      this.definedQueries, this.knownImports, this.availableElements);
}
