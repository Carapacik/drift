import 'package:sqlparser/sqlparser.dart';

/// Static analysis support for SQL functions available when using a
/// `NativeDatabase` or a `WasmDatabase` in drift.
class DriftNativeExtension implements Extension {
  const DriftNativeExtension();

  @override
  void register(SqlEngine engine) {
    engine.registerFunctionHandler(const _MoorFfiFunctions());
  }
}

class _MoorFfiFunctions with ArgumentCountLinter implements FunctionHandler {
  const _MoorFfiFunctions();

  static const Set<String> _unaryFunctions = {
    'sqrt',
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan'
  };

  @override
  Set<String> get functionNames {
    return const {'pow', 'current_time_millis', ..._unaryFunctions};
  }

  @override
  int? argumentCountFor(String function) {
    if (_unaryFunctions.contains(function)) {
      return 1;
    } else if (function == 'pow') {
      return 2;
    } else if (function == 'current_time_millis') {
      return 0;
    } else {
      return null;
    }
  }

  @override
  ResolveResult inferArgumentType(
      TypeInferenceSession session, SqlInvocation call, Expression argument) {
    return const ResolveResult(
        ResolvedType(type: BasicType.real, nullable: false));
  }

  @override
  ResolveResult inferReturnType(TypeInferenceSession session,
      SqlInvocation call, List<Typeable> expandedArgs) {
    if (call.name == 'current_time_millis') {
      return const ResolveResult(
          ResolvedType(type: BasicType.int, nullable: false));
    }

    return const ResolveResult(
        ResolvedType(type: BasicType.real, nullable: true));
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {
    reportMismatches(call, context);
  }
}
