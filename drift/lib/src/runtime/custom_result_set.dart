import 'package:drift/drift.dart';

/// Base class for classes generated by custom queries in `.drift` files.
abstract class CustomResultSet {
  /// The raw [QueryRow] from where this result set was extracted.
  final QueryRow row;

  /// Default constructor.
  CustomResultSet(this.row);
}