---

title: DateTime Storage
description: A guide on how Drift stores `DateTime` values and how to migrate between the two storage modes.

---

## Storage modes

Drift supports two approaches of storing `DateTime` values in SQL:

1. __As unix timestamp__ (the default): In this mode, drift stores date time
   values as an SQL `INTEGER` containing the unix timestamp (in seconds).
   When date times are mapped from SQL back to Dart, drift always returns a
   non-UTC value. So even when UTC date times are stored, this information is
   lost when retrieving rows.
2. __As ISO 8601 string__: In this mode, datetime values are stored in a
   textual format based on `DateTime.toIso8601String()`: UTC values are stored
   unchanged (e.g. `2022-07-25 09:28:42.015Z`), while local values have their
   UTC offset appended (e.g. `2022-07-25T11:28:42.015 +02:00`).
   Most of sqlite3's date and time functions operate on UTC values, but parsing
   datetimes in SQL respects the UTC offset added to the value.
   When reading values back from the database, drift will use `DateTime.parse`
   as following:
    - If the textual value ends with `Z`, drift will use `DateTime.parse`
      directly. The `Z` suffix will be recognized and a UTC value is returned.
    - If the textual value ends with a UTC offset (e.g. `+02:00`), drift first
      uses `DateTime.parse` which respects the modifier but returns a UTC
      datetime. Drift then calls `toLocal()` on this intermediate result to
      return a local value.
    - If the textual value neither has a `Z` suffix nor a UTC offset, drift
      will parse it as if it had a `Z` modifier, returning a UTC datetime.
      The motivation for this is that the `datetime` function in sqlite3 returns
      values in this format and uses UTC by default.
   This behavior works well with the date functions in sqlite3 while also
   preserving "UTC-ness" for stored values.

The mode can be changed with the `store_date_time_values_as_text` [build option](../generation_options/index.md).

Regardless of the option used, drift's builtin support for
[date and time functions](../dart_api/expressions.md#date-and-time)
return an equivalent values. Drift internally inserts the `unixepoch`
[modifier](https://sqlite.org/lang_datefunc.html#modifiers) when unix timestamps
are used to make the date functions work. When comparing dates stored as text,
drift will compare their `julianday` values behind the scenes.

## Migrate

While making drift change the date time modes is as simple as changing a build
option, toggling this behavior is not compatible with existing database schemas:

1. Depending on the build option, drift expects strings or integers for datetime
   values. So you need to migrate stored columns to the new format when changing
   the option.
2. If you are using SQL statements defined in `.drift` files, use custom SQL
  at runtime or manually invoke datetime expressions with a direct
  `FunctionCallExpression` instead of using the higher-level date time APIs, you
  may have to adapt those usages.
  For instance, comparison operators like `<` work on unix timestamps, but they
  will compare textual datetime values lexicographically. So depending on the
  mode used, you will have to wrap the value in `unixepoch` or `julianday` to
  make them comparable.

As the second point is specific to usages in your app, this documentation only
describes how to migrate stored columns between the format:



Note that the JSON serialization generated by default is not affected by the
datetime mode chosen. By default, drift will serialize `DateTime` values to a
unix timestamp in milliseconds. You can change this by creating a
`ValueSerializer.defaults(serializeDateTimeValuesAsString: true)` and assigning
it to `driftRuntimeOptions.defaultSerializer`.

### ...to text

To migrate from using timestamps (the default option) to storing datetimes as
text, follow these steps:

1. Enable the `store_date_time_values_as_text` build option.
2. Add the following method (or an adaption of it suiting your needs) to your
   database class.
3. Increment the `schemaVersion` in your database class.
4. Write a migration step in `onUpgrade` that calls
  `migrateFromUnixTimestampsToText` for this schema version increase.
  __Remember that triggers, views or other custom SQL entries in your database
  will require a custom migration that is not covered by this guide.__

{{ load_snippet('unix-to-text','lib/snippets/dart_api/datetime_conversion.dart.excerpt.json') }}

### ...to unix timestamps

To migrate from datetimes stored as text back to unix timestamps, follow these
steps:

1. Disable the `store_date_time_values_as_text` build option.
2. Add the following method (or an adaption of it suiting your needs) to your
   database class.
3. Increment the `schemaVersion` in your database class.
4. Write a migration step in `onUpgrade` that calls
  `migrateFromTextDateTimesToUnixTimestamps` for this schema version increase.
  __Remember that triggers, views or other custom SQL entries in your database
  will require a custom migration that is not covered by this guide.__

{{ load_snippet('text-to-unix','lib/snippets/dart_api/datetime_conversion.dart.excerpt.json') }}

Note that this snippet uses the `unixepoch` sqlite3 function, which has been
added in sqlite 3.38. To support older sqlite3 versions, you can use `strftime`
and cast to an integer instead:

{{ load_snippet('text-to-unix-old','lib/snippets/dart_api/datetime_conversion.dart.excerpt.json') }}

When using a `NativeDatabase` with a recent dependency on the
`sqlite3_flutter_libs` package, you can safely assume that you are on a recent
sqlite3 version with support for `unixepoch`.