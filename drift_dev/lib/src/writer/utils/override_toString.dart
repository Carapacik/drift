// ignore_for_file: file_names

import '../../utils/string_escaper.dart';

/// Generates a `toString` override into the [into] buffer.
///
/// The override looks like this:
///
/// ```dart
/// @override
/// String toString() {
///   return (StringBuffer('ClassName(')
///     ..write('property1: $property1')
///     ..write('property2: $property2')
///     ..write(')')
///   ).toString();
/// }
/// ```
void overrideToString(
  String className,
  List<String> properties,
  StringBuffer into,
) {
  into
    ..write('@override\nString toString() {')
    ..write("return (StringBuffer('${escapeForDart(className)}(')");

  for (var i = 0; i < properties.length; i++) {
    final property = properties[i];

    if (property.contains(r'$')) {
      final asKey = property.replaceAll('\$', '\\\$');
      into.write("..write('$asKey: \${$property}");
    } else {
      into.write("..write('$property: \$$property");
    }

    if (i != properties.length - 1) into.write(', ');

    into.write("')");
  }

  into
    ..write("..write(')')).toString();")
    ..writeln('}');
}
