import 'dart:typed_data';
import 'dart:convert' as convert;

import 'package:sqlite3/common.dart' as sqlite3 show jsonb;

import '../../dsl/dsl.dart';
import '../data_class.dart';

/// Maps a custom dart object of type [D] into a primitive type [S] understood
/// by the sqlite backend.
///
/// Dart currently supports [DateTime], [double], [int], [Uint8List], [bool]
/// and [String] for [S].
///
/// Using a type converter does not impact the way drift serializes data classes to
/// JSON by default. To control that, use a [JsonTypeConverter] or a custom
/// [ValueSerializer].
///
/// Also see [BuildGeneralColumn.map] for details.
abstract class TypeConverter<D, S> {
  /// Empty constant constructor so that subclasses can have a constant
  /// constructor.
  const TypeConverter();

  /// Map a value from an object in Dart into something that will be understood
  /// by the database.
  S toSql(D value);

  /// Maps a column from the database back to Dart.
  D fromSql(S fromDb);

  /// Creates a type converter for storing complex Dart objects in a text column
  /// by serializing them as JSON text.
  ///
  /// This requires supplying [fromJson], a function responsible for mapping the
  /// parsed JSON structure to the Dart type [D]. Optionally, you can also
  /// be explicit about the other direction via [toJson]. By default, Dart's
  /// JSON encoder simply calls `toJson()` on the object.
  ///
  /// Finally, the [json] codec itself can be customized as well if needed.
  ///
  /// For sqlite3 databases, [jsonb] can be used as an alternative encoding for
  /// binary columns.
  ///
  /// ### Deprecated
  ///
  /// This method is deprecated because it always maps values to [String]s when
  /// [JsonTypeConverter.toJson] is called. This is typically undesired
  /// behavior, as it leads to double encodings. Consider this table:
  ///
  /// ```dart
  /// class MyValue {
  ///   // ...
  ///   factory MyValue.fromJson(Object? json) {
  ///     // ...
  ///   }
  ///
  ///   Object? toJson() => {'foo': 'bar'};
  /// }
  ///
  /// class MyTable extends Table {
  ///   TextColumn get col => text().map(TypeConverter.json<MyValue>(
  ///     fromJson: MyValue.fromJson,
  ///   ))();
  /// }
  /// ```
  ///
  /// Here, calling `MyTableData.toJson` will report a value like the following:
  ///
  /// ```json
  /// {
  ///   "col": "{\"foo\": \"bar\"}"
  /// }
  /// ```
  ///
  /// Note that the actual value has been converted to JSON twice.
  /// Using [TypeConverter.json2] fixes the issue, and will properly encode the
  /// value as:
  ///
  /// ```json
  /// {
  ///   "col": {
  ///     "foo": "bar"
  ///   }
  /// }
  /// ```
  ///
  /// Given the different formats, migrating from [TypeConverter.json] to
  /// [json2] can be a breaking change.
  @Deprecated(
    'Use TypeConverter.json2 instead. This converter causes a double JSON '
    'conversion when serializing drift row classes to JSON.',
  )
  static JsonTypeConverter<D, String> json<D>({
    required D Function(dynamic json) fromJson,
    dynamic Function(D column)? toJson,
    convert.JsonCodec json = convert.json,
  }) {
    return _LegacyJsonConverter<D>(
      mapFromJson: fromJson,
      mapToJson: toJson ?? (value) => value,
      json: json,
    );
  }

  /// Creates a type converter for storing complex Dart objects in a text column
  /// by serializing them as JSON.
  ///
  /// This requires supplying [fromJson], a function responsible for mapping the
  /// parsed JSON structure to the Dart type [D]. Optionally, you can also
  /// be explicit about the other direction via [toJson]. By default, Dart's
  /// JSON encoder simply calls `toJson()` on the object.
  ///
  /// Finally, the [json] codec itself can be customized as well if needed.
  ///
  /// For sqlite3 databases, [jsonb] can be used as an alternative encoding for
  /// binary columns.
  static JsonTypeConverter2<D, String, Object?> json2<D>({
    required D Function(Object? json) fromJson,
    Object? Function(D column)? toJson,
    convert.JsonCodec json = convert.json,
  }) {
    return _DefaultJsonConverter<D, String, Object?>(
      mapFromJson: fromJson,
      mapToJson: toJson ?? (value) => value,
      jsonForDb: json,
    );
  }

  /// Creates a type converter for storing complex Dart objects in a binary
  /// column by serializing them into the [JSONB representation] used by SQLite.
  ///
  /// This requires supplying [fromJson], a function responsible for mapping the
  /// parsed JSON structure to the Dart type [D]. Optionally, you can also
  /// be explicit about the other direction via [toJson]. By default, the JSONB
  /// encoder simply calls `toJson()` on the object.
  ///
  /// Note that this representation is primarily useful when [JSON operators]
  /// are commonly used on the column to extract individual fields. The main
  /// advantage of the JSONB representation is that those operators can be
  /// implemented more efficiently. For the common case where entire JSON values
  /// are inserted and selected, prefer using a textual [json2] converter for
  /// better compatibility with standard formats.
  ///
  /// [JSONB representation]: https://sqlite.org/jsonb.html
  /// [JSON operators]: https://sqlite.org/json1.html
  static JsonTypeConverter2<D, Uint8List, Object?> jsonb<D>({
    required D Function(Object? json) fromJson,
    Object? Function(D column)? toJson,
  }) {
    return _DefaultJsonConverter<D, Uint8List, Object?>(
      mapFromJson: fromJson,
      mapToJson: toJson ?? (value) => value,
      jsonForDb: sqlite3.jsonb,
    );
  }

  /// A type converter mapping [extension types] to their underlying
  /// representation to store them in databases.
  ///
  /// Here, [ExtType] is the extension type to use in Dart classes, and [Inner]
  /// is the underlying type stored in the database. For instance, if you had
  /// a type to represent ids in a database:
  ///
  /// ```dart
  /// extension type IdNumber(int id) {}
  /// ```
  ///
  /// You could use `TypeConverter.extensionType<IdNumber, int>()` in a column
  /// definition:
  ///
  /// ```dart
  /// class Users extends Table {
  ///   IntColumn get id => integer()
  ///       .autoIncrement()
  ///       .map(TypeConverter.extensionType<IdNumber, int>())();
  ///   TextColumn get name => text()();
  /// }
  /// ```
  ///
  /// [extension types]: https://dart.dev/language/extension-types
  static JsonTypeConverter<ExtType, Inner>
      extensionType<ExtType, Inner extends Object>() {
    return _ExtensionTypeConverter();
  }
}

/// A mixin for [TypeConverter]s that should also apply to drift's builtin
/// JSON serialization of data classes.
///
/// Unlike the old [JsonTypeConverter] mixin, this more general mixin allows
/// using a different type when serializing to JSON ([J]) than the type used in
/// SQL ([S]).
/// For the cases where the JSON serialization and the mapping to SQL use the
/// same types, it may be more convenient to mix-in [JsonTypeConverter] instead.
mixin JsonTypeConverter2<D, S, J> on TypeConverter<D, S> {
  /// Map a value from the Data class to json.
  ///
  /// Defaults to doing the same conversion as for Dart -> SQL, [toSql].
  J toJson(D value);

  /// Map a value from json to something understood by the data class.
  ///
  /// Defaults to doing the same conversion as for SQL -> Dart, [toSql].
  D fromJson(J json);

  /// Wraps an [inner] type converter that only considers non-nullable values
  /// as a type converter that handles null values too.
  ///
  /// The returned type converter will use the [inner] type converter for non-
  /// null values. Further, `null` is mapped to `null` in both directions (from
  /// Dart to SQL and vice-versa).
  static JsonTypeConverter2<D?, S?, J?>
      asNullable<D, S extends Object, J extends Object>(
          JsonTypeConverter2<D, S, J?> inner) {
    return _NullWrappingTypeConverterWithJson(inner);
  }
}

/// A mixin for [TypeConverter]s that should also apply to drift's builtin
/// JSON serialization of data classes.
///
/// By default, a [TypeConverter] only applies to the serialization from Dart
/// to SQL (and vice-versa).
/// When a [BuildGeneralColumn.map] column (or a `MAPPED BY` constraint in
/// `.drift` files) refers to a type converter that inherits from
/// [JsonTypeConverter], it will also be used for the conversion from and to
/// JSON.
///
/// If the serialized JSON has a different type than the type in SQL ([S]), use
/// a [JsonTypeConverter2]. For instance, this could be useful if your type
/// converter between Dart and SQL maps to a string in SQL, but to a `Map` in
/// JSON.
mixin JsonTypeConverter<D, S> implements JsonTypeConverter2<D, S, S> {
  @override
  S toJson(D value) => toSql(value);

  @override
  D fromJson(S json) => fromSql(json);
}

/// Implementation for an enum to int converter that uses the index of the enum
/// as the value stored in the database.
class EnumIndexConverter<T extends Enum> extends TypeConverter<T, int>
    with JsonTypeConverter<T, int> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumIndexConverter(this.values);

  @override
  T fromSql(int fromDb) {
    return values[fromDb];
  }

  @override
  int toSql(T value) {
    return value.index;
  }
}

/// Implementation for an enum to string converter that uses the name of the
/// enum as the value stored in the database.
class EnumNameConverter<T extends Enum> extends TypeConverter<T, String>
    with JsonTypeConverter<T, String> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumNameConverter(this.values);

  @override
  T fromSql(String fromDb) {
    return values.byName(fromDb);
  }

  @override
  String toSql(T value) {
    return value.name;
  }
}

/// A type converter automatically mapping `null` values to `null` in both
/// directions.
///
/// Instead of overriding  [fromSql] and [toSql], subclasses of this
/// converter should implement [requireFromSql] and [requireToSql], which
/// are used to map non-null values to and from sql values, respectively.
///
/// Apart from the implementation changes, subclasses of this converter can be
/// used just like all other type converters.
abstract class NullAwareTypeConverter<D, S extends Object>
    extends TypeConverter<D?, S?> {
  /// Constant default constructor, allowing subclasses to be constant.
  const NullAwareTypeConverter();

  /// Wraps an [inner] type converter that only considers non-nullable values
  /// as a type converter that handles null values too.
  ///
  /// The returned type converter will use the [inner] type converter for non-
  /// null values. Further, `null` is mapped to `null` in both directions (from
  /// Dart to SQL and vice-versa).
  const factory NullAwareTypeConverter.wrap(TypeConverter<D, S> inner) =
      _NullWrappingTypeConverter<D, S>;

  @override
  D? fromSql(S? fromDb) {
    return fromDb == null ? null : requireFromSql(fromDb);
  }

  /// Maps a non-null column from the database back to Dart.
  D requireFromSql(S fromDb);

  @override
  S? toSql(D? value) {
    return value == null ? null : requireToSql(value);
  }

  /// Map a non-null value from an object in Dart into something that will be
  /// understood by the database.
  S requireToSql(D value);

  /// Invokes a non-nullable [inner] type converter for a single conversion from
  /// SQL to Dart.
  ///
  /// Returns `null` if [sqlValue] is `null`, [TypeConverter.fromSql] otherwise.
  /// This method is mostly intended to be used for code generated by drift-dev.
  static D? wrapFromSql<D, S>(TypeConverter<D, S> inner, S? sqlValue) {
    return sqlValue == null ? null : inner.fromSql(sqlValue);
  }

  /// Invokes a non-nullable [inner] type converter for a single conversion from
  /// Dart to SQL.
  ///
  /// Returns `null` if [dartValue] is `null`, [TypeConverter.toSql] otherwise.
  /// This method is mostly intended to be used for code generated by drift-dev.
  static S? wrapToSql<D, S>(TypeConverter<D, S> inner, D? dartValue) {
    return dartValue == null ? null : inner.toSql(dartValue);
  }
}

@Deprecated(
  'Use _DefaultJsonConverter instead. This one is flawed, as it maps values to'
  'JSON strings for JSON serialization, leading to double serialiazion when '
  'serializing drift row classes.',
)
class _LegacyJsonConverter<D> extends TypeConverter<D, String>
    with JsonTypeConverter<D, String> {
  final D Function(dynamic json) mapFromJson;
  final dynamic Function(D column) mapToJson;
  final convert.JsonCodec json;

  _LegacyJsonConverter(
      {required this.mapFromJson, required this.mapToJson, required this.json});

  @override
  D fromSql(String fromDb) {
    return mapFromJson(json.decode(fromDb));
  }

  @override
  String toSql(D value) {
    return json.encode(mapToJson(value));
  }
}

class _DefaultJsonConverter<D, S, J> extends TypeConverter<D, S>
    with JsonTypeConverter2<D, S, J> {
  final D Function(J json) mapFromJson;
  final J Function(D column) mapToJson;
  final convert.Codec<Object?, S> jsonForDb;

  _DefaultJsonConverter(
      {required this.mapFromJson,
      required this.mapToJson,
      required this.jsonForDb});

  @override
  D fromSql(S fromDb) {
    return mapFromJson(jsonForDb.decode(fromDb) as J);
  }

  @override
  S toSql(D value) {
    return jsonForDb.encode(mapToJson(value));
  }

  @override
  D fromJson(J json) {
    return mapFromJson(json);
  }

  @override
  J toJson(D value) {
    return mapToJson(value);
  }
}

class _NullWrappingTypeConverter<D, S extends Object>
    extends NullAwareTypeConverter<D, S> {
  final TypeConverter<D, S> _inner;

  const _NullWrappingTypeConverter(this._inner);

  @override
  D requireFromSql(S fromDb) => _inner.fromSql(fromDb);

  @override
  S requireToSql(D value) => _inner.toSql(value);
}

class _NullWrappingTypeConverterWithJson<D, S extends Object, J>
    extends NullAwareTypeConverter<D, S>
    implements JsonTypeConverter2<D?, S?, J?> {
  final JsonTypeConverter2<D, S, J?> _inner;

  const _NullWrappingTypeConverterWithJson(this._inner);

  @override
  D requireFromSql(S fromDb) => _inner.fromSql(fromDb);

  @override
  S requireToSql(D value) => _inner.toSql(value);

  D requireFromJson(J json) => _inner.fromJson(json);

  @override
  D? fromJson(J? json) {
    return json == null ? null : requireFromJson(json);
  }

  J? requireToJson(D? value) => _inner.toJson(value as D);

  @override
  J? toJson(D? value) {
    return value == null ? null : requireToJson(value);
  }
}

class _ExtensionTypeConverter<ExtType, Inner extends Object>
    extends TypeConverter<ExtType, Inner>
    with JsonTypeConverter<ExtType, Inner> {
  const _ExtensionTypeConverter();

  @override
  ExtType fromSql(Inner fromDb) {
    return fromDb as ExtType;
  }

  @override
  Inner toSql(ExtType value) => value as Inner;
}
