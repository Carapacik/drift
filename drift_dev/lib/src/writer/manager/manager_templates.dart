part of "database_manager_writer.dart";

/// A class which contains utility functions to generate manager class names
///
/// This is used by the [DatabaseManagerWriter] to generate code for the manager classes
class _ManagerCodeTemplates {
  _ManagerCodeTemplates(this._scope);

  /// A Scope class which contains the current scope of the generation
  ///
  /// Used to generating names which require import prefixes
  final Scope _scope;

  /// Returns the name of the manager class for a table
  ///
  /// This classes acts as container for all the table managers
  ///
  /// E.g. `AppDatabaseManager`
  String databaseManagerName(String dbClassName) {
    // This class must be public, remove all _ prefixes
    return '${dbClassName}Manager'.replaceAll(RegExp(r'^_+'), "");
  }

  /// How the database will represented in the generated code
  ///
  /// When doing modular generation the table doesnt have direct access to the database class
  /// so it will use `GeneratedDatabase` as the generic type in such cases
  ///
  /// E.g. `i0.GeneratedDatabase` or `AppDatabase`
  String databaseType(TextEmitter leaf, String dbClassName) {
    return switch (_scope.generationOptions.isModular) {
      true => leaf.drift("GeneratedDatabase"),
      false => dbClassName,
    };
  }

  /// Returns the name of the root manager class for a table
  ///
  /// One of these classes is generated for each table in the database
  ///
  /// E.g. `\$UserTableManager`
  String rootTableManagerName(DriftTable table) {
    return '\$${table.entityInfoName}TableManager';
  }

  /// Returns the name of the manager class for a table
  ///
  /// When using modular generation the manager class will contain the correct prefix
  /// to access the table manager
  ///
  /// E.g. `i0.UserTableTableManager` or `\$UserTableTableManager`
  String rootTableManagerWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, rootTableManagerName(table)));
  }

  /// Class which represents a table in the database
  /// Contains the prefix if the generation is modular
  /// E.g. `i0.UserTable`
  String tableClassWithPrefix(DriftTable table, TextEmitter leaf) =>
      leaf.dartCode(leaf.entityInfoType(table));

  /// Class which represents a row in the table
  /// Contains the prefix if the generation is modular
  /// E.g. `i0.User`
  String rowClassWithPrefix(DriftTable table, TextEmitter leaf) =>
      leaf.dartCode(leaf.writer.rowType(table));

  /// Name of this tables filter composer class
  String filterComposerNameWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, filterComposerName(table)));
  }

  /// Name of this tables filter composer class
  String filterComposerName(
    DriftTable table,
  ) {
    return '\$${table.entityInfoName}FilterComposer';
  }

  /// Name of this tables annotation composer class
  String annotationComposerNameWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, annotationComposerName(table)));
  }

  /// Name of this tables annotation composer class
  String annotationComposerName(
    DriftTable table,
  ) {
    return '\$${table.entityInfoName}AnnotationComposer';
  }

  /// Name of this tables ordering composer class
  String orderingComposerNameWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, orderingComposerName(table)));
  }

  /// Name of this tables ordering composer class
  String orderingComposerName(DriftTable table) {
    return '\$${table.entityInfoName}OrderingComposer';
  }

  /// Name of the typedef for the create companion builder for a table
  ///
  /// This is the name of the typedef of a function that creates new rows in the table
  String createCompanionBuilderTypeDef(DriftTable table) {
    return '\$${table.entityInfoName}CreateCompanionBuilder';
  }

  /// Name of the typedef for the update companion builder for a table
  ///
  /// This is the name of the typedef of a function that updates rows in the table
  String updateCompanionBuilderTypeDefName(DriftTable table) {
    return '\$${table.entityInfoName}UpdateCompanionBuilder';
  }

  /// Build the builder for a companion class
  /// This is used to build the create and update companions
  /// Returns a tuple with the typedef and the builder
  /// Use [isUpdate] to determine if the builder is for an update or create companion
  ({String typeDefinition, String companionBuilder}) companionBuilder(
      DriftTable table, TextEmitter leaf,
      {required bool isUpdate}) {
    // Get the name of the typedef
    final typedefName = isUpdate
        ? updateCompanionBuilderTypeDefName(table)
        : createCompanionBuilderTypeDef(table);

    // Get the companion class name
    final companionClassName = leaf.dartCode(leaf.companionType(table));

    // Build the typedef and the builder in 3 parts
    // 1. The typedef definition
    // 2. The arguments for the builder
    // 3. The body of the builder
    final companionBuilderTypeDef =
        StringBuffer('typedef $typedefName = $companionClassName Function({');
    final companionBuilderArguments = StringBuffer('({');
    final StringBuffer companionBuilderBody;
    if (isUpdate) {
      companionBuilderBody = StringBuffer('=> $companionClassName(');
    } else {
      companionBuilderBody = StringBuffer('=> $companionClassName.insert(');
    }
    for (final column in UpdateCompanionWriter(table, _scope).columns) {
      final value = leaf.drift('Value');
      final param = column.nameInDart;
      final typeName = leaf.dartCode(leaf.dartType(column));

      companionBuilderBody.write('$param: $param,');

      // When writing an update companion builder, all fields are optional
      // they are all therefor defaulted to absent
      if (isUpdate) {
        companionBuilderTypeDef.write('$value<$typeName> $param,');
        companionBuilderArguments
            .write('$value<$typeName> $param = const $value.absent(),');
      } else {
        // Otherwise, for create companions, required fields are required
        // and optional fields are defaulted to absent
        if (!column.isImplicitRowId &&
            table.isColumnRequiredForInsert(column)) {
          companionBuilderTypeDef.write('required $typeName $param,');
          companionBuilderArguments.write('required $typeName $param,');
        } else {
          companionBuilderTypeDef.write('$value<$typeName> $param,');
          companionBuilderArguments
              .write('$value<$typeName> $param = const $value.absent(),');
        }
      }
    }
    companionBuilderTypeDef.write('});');
    companionBuilderArguments.write('})');
    companionBuilderBody.write(")");
    return (
      typeDefinition: companionBuilderTypeDef.toString(),
      companionBuilder:
          companionBuilderArguments.toString() + companionBuilderBody.toString()
    );
  }

  /// Generic type arguments for the root and processed table manager
  String _tableManagerTypeArguments(
    DriftTable table,
    String dbClassName,
    TextEmitter leaf,
    List<_Relation> relations,
  ) {
    final String rowClassWithReferences = rowReferencesClassName(
        table: table,
        relations: relations,
        dbClassName: dbClassName,
        leaf: leaf,
        withTypeArgs: true);
    return """
    <${databaseType(leaf, dbClassName)},
    ${tableClassWithPrefix(table, leaf)},
    ${rowClassWithPrefix(table, leaf)},
    ${filterComposerNameWithPrefix(table, leaf)},
    ${orderingComposerNameWithPrefix(table, leaf)},
    ${annotationComposerNameWithPrefix(table, leaf)},
    ${createCompanionBuilderTypeDef(table)},
    ${updateCompanionBuilderTypeDefName(table)},
    (${rowClassWithPrefix(table, leaf)},$rowClassWithReferences),
    ${rowClassWithPrefix(table, leaf)},
    ${createCreatePrefetchHooksCallbackType(currentTable: table, relations: relations, leaf: leaf, dbClassName: dbClassName)}
    >""";
  }

  /// Code for getting a table from inside a composer
  /// handles modular generation correctly
  String _referenceTableFromComposer(DriftTable table, TextEmitter leaf) {
    return leaf.dartCode(leaf.referenceElement(table, '\$db'));
  }

  /// Returns code for the root table manager class
  String rootTableManager({
    required DriftTable table,
    required String dbClassName,
    required TextEmitter leaf,
    required String updateCompanionBuilder,
    required String createCompanionBuilder,
    required List<_Relation> relations,
  }) {
    final forwardRelations = relations.where((e) => !e.isReverse).toList();
    final reverseRelations = relations.where((e) => e.isReverse).toList();
    return """class ${rootTableManagerName(table)} extends ${leaf.drift("RootTableManager")}${_tableManagerTypeArguments(table, dbClassName, leaf, relations)} {
    ${rootTableManagerName(table)}(${databaseType(leaf, dbClassName)} db, ${tableClassWithPrefix(table, leaf)} table) : super(
      ${leaf.drift("TableManagerState")}(
        db: db,
        table: table,
        createFilteringComposer: () => ${filterComposerNameWithPrefix(table, leaf)}(\$db: db,\$table:table),
        createOrderingComposer: () => ${orderingComposerNameWithPrefix(table, leaf)}(\$db: db,\$table:table),
        createComputedFieldComposer: () => ${annotationComposerNameWithPrefix(table, leaf)}(\$db: db,\$table:table),
        updateCompanionCallback: $updateCompanionBuilder,
        createCompanionCallback: $createCompanionBuilder,
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), ${rowReferencesClassName(table: table, relations: relations, dbClassName: dbClassName, leaf: leaf, withTypeArgs: false)}(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: ${relations.isEmpty ? 'null' : """
        (${"{${relations.map(
                  (e) => "${e.fieldName} = false",
                ).join(",")}}"}){
          return ${leaf.drift("PrefetchHooks")}(
            db: db,
            explicitlyWatchedTables: [
             ${reverseRelations.map((relation) {
                final table =
                    leaf.referenceElement(relation.referencedTable, 'db');
                return "if (${relation.fieldName}) ${leaf.dartCode(table)}";
              }).join(',')}
            ],
            addJoins: ${forwardRelations.isEmpty ? 'null' : """
<T extends ${leaf.drift("TableManagerState")}<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                ${forwardRelations.map((relation) {
                    final referencesClassName = rowReferencesClassName(
                        table: table,
                        relations: relations,
                        dbClassName: dbClassName,
                        leaf: leaf,
                        withTypeArgs: false);
                    return """
                  if (${relation.fieldName}){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.${relation.currentColumn.nameInDart},
                    referencedTable:
                        $referencesClassName._${relation.fieldName}Table(db),
                    referencedColumn:
                        $referencesClassName._${relation.fieldName}Table(db).${relation.referencedColumn.nameInDart},
                  ) as T;
               }""";
                  }).join('\n')}

                return state;
              }
"""},
            getPrefetchedDataCallback: (items) async {
            return [
            ${reverseRelations.map((relation) {
                final referencesClassName = rowReferencesClassName(
                    table: table,
                    relations: relations,
                    dbClassName: dbClassName,
                    leaf: leaf,
                    withTypeArgs: false);

                final currentDataClass = leaf.dartCode(leaf.rowType(table));
                final currentTable = leaf.dartCode(leaf.entityInfoType(table));
                final referencedDataClass =
                    leaf.dartCode(leaf.rowType(relation.referencedTable));

                return """
          if (${relation.fieldName}) await ${leaf.drift("\$_getPrefetchedData")}
            <$currentDataClass, $currentTable, $referencedDataClass>(
                  currentTable: table,
                  referencedTable:
                      $referencesClassName._${relation.fieldName}Table(db),
                  managerFromTypedResult: (p0) =>
                      $referencesClassName(db, table, p0).${relation.fieldName},
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.${relation.referencedColumn.nameInDart} == item.${relation.currentColumn.nameInDart}),
                  typedResults: items)
            """;
              }).join(',')}
                ];
              },
          );
        }
"""},
        ));
        }
    """;
  }

  /// Returns the code for a tables filter composer
  String filterComposer({
    required DriftTable table,
    required TextEmitter leaf,
    required String dbClassName,
    required List<String> columnFilters,
  }) {
    return """class ${filterComposerName(table)} extends ${leaf.drift("Composer")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)}> {
        ${filterComposerName(table)}({
    required super.\$db,
    required super.\$table,
    super.joinBuilder,
    super.\$addJoinBuilderToRootComposer,
    super.\$removeJoinBuilderFromRootComposer,
  });
          ${columnFilters.join('\n')}
        }
      """;
  }

  /// Returns the code for a tables annotation composer
  String annotationComposer({
    required DriftTable table,
    required TextEmitter leaf,
    required String dbClassName,
    required List<String> columnAnnotations,
  }) {
    return """class ${annotationComposerName(table)} extends ${leaf.drift("Composer")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)}> {
        ${annotationComposerName(table)}({
    required super.\$db,
    required super.\$table,
    super.joinBuilder,
    super.\$addJoinBuilderToRootComposer,
    super.\$removeJoinBuilderFromRootComposer,
  });
          ${columnAnnotations.join('\n')}
        }
      """;
  }

  /// Returns the code for a tables ordering composer
  String orderingComposer(
      {required DriftTable table,
      required TextEmitter leaf,
      required String dbClassName,
      required List<String> columnOrderings}) {
    return """class ${orderingComposerName(table)} extends ${leaf.drift("Composer")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)}> {
        ${orderingComposerName(table)}({
    required super.\$db,
    required super.\$table,
    super.joinBuilder,
    super.\$addJoinBuilderToRootComposer,
    super.\$removeJoinBuilderFromRootComposer,
  });
          ${columnOrderings.join('\n')}
        }
      """;
  }

  /// Code for a annotations for a standard column (no relations or type convertions)
  String standardColumnAnnotation(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;

    return """${leaf.drift("GeneratedColumn")}<$type> get $filterName => \$composableBuilder(
      column: \$table.$columnGetter,
      builder: (column) => column);
      """;
  }

  /// Code for a annotations for a column that has a type converter
  String columnWithTypeConverterAnnotations(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;
    final converterType = leaf.dartCode(leaf.writer.dartType(column));
    return """
          ${leaf.drift("GeneratedColumnWithTypeConverter")}<$converterType,$type> get $filterName => \$composableBuilder(
      column: \$table.$columnGetter,
      builder: (column) => column);
      """;
  }

  /// Code for a annotations which works over a reference
  String relatedAnnotations(
      {required _Relation relation, required TextEmitter leaf}) {
    if (relation.isReverse) {
      return """
        ${leaf.drift("Expression")}<T> ${relation.fieldName}<T extends Object>(
          ${leaf.drift("Expression")}<T> Function( ${annotationComposerNameWithPrefix(relation.referencedTable, leaf)} a) f
        ) {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: annotationComposerNameWithPrefix(relation.referencedTable, leaf))}
          return f(composer);
        }
""";
    } else {
      return """
        ${annotationComposerNameWithPrefix(relation.referencedTable, leaf)} get ${relation.fieldName} {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: annotationComposerNameWithPrefix(relation.referencedTable, leaf))}
          return composer;
        }""";
    }
  }

  /// Code for a filter for a standard column (no relations or type convertions)
  String standardColumnFilters(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;

    return """${leaf.drift("ColumnFilters")}<$type> get $filterName => \$composableBuilder(
      column: \$table.$columnGetter,
      builder: (column) =>
      ${leaf.drift("ColumnFilters")}(column));
      """;
  }

  /// Code for a filter for a column that has a type converter
  String columnWithTypeConverterFilters(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;
    final converterType = leaf.dartCode(leaf.writer.dartType(column));
    final nonNullableConverterType = converterType.replaceFirst("?", "");
    return """
          ${leaf.drift("ColumnWithTypeConverterFilters")}<$converterType,$nonNullableConverterType,$type> get $filterName => \$composableBuilder(
      column: \$table.$columnGetter,
      builder: (column) =>
      ${leaf.drift("ColumnWithTypeConverterFilters")}(column));
      """;
  }

  /// Code for a filter which works over a reference
  String relatedFilter(
      {required _Relation relation, required TextEmitter leaf}) {
    if (relation.isReverse) {
      return """
        ${leaf.drift("Expression")}<bool> ${relation.fieldName}(
          ${leaf.drift("Expression")}<bool> Function( ${filterComposerNameWithPrefix(relation.referencedTable, leaf)} f) f
        ) {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: filterComposerNameWithPrefix(relation.referencedTable, leaf))}
          return f(composer);
        }
""";
    } else {
      return """
        ${filterComposerNameWithPrefix(relation.referencedTable, leaf)} get ${relation.fieldName} {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: filterComposerNameWithPrefix(relation.referencedTable, leaf))}
          return composer;
        }""";
    }
  }

  /// Code for a orderings for a standard column (no relations)
  String standardColumnOrderings(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;

    return """${leaf.drift("ColumnOrderings")}<$type> get $filterName => \$composableBuilder(
      column: \$table.$columnGetter,
      builder: (column) =>
      ${leaf.drift("ColumnOrderings")}(column));
      """;
  }

  /// Code for a ordering which works over a reference
  String relatedOrderings(
      {required _Relation relation, required TextEmitter leaf}) {
    assert(relation.isReverse == false,
        "Don't generate orderings for reverse relations");
    return """
        ${orderingComposerNameWithPrefix(relation.referencedTable, leaf)} get ${relation.fieldName} {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: orderingComposerNameWithPrefix(relation.referencedTable, leaf))}
          return composer;
        }""";
  }

  /// Code for creating a referenced composer, used by forward and reverse filters
  String _referencedComposer(
      {required _Relation relation,
      required TextEmitter leaf,
      required String composerName}) {
    return """
      final $composerName composer = \$composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.${relation.currentColumn.nameInDart},
      referencedTable: ${_referenceTableFromComposer(relation.referencedTable, leaf)},
      getReferencedColumn: (t) => t.${relation.referencedColumn.nameInDart},
      builder: (joinBuilder,{\$addJoinBuilderToRootComposer,\$removeJoinBuilderFromRootComposer }) =>
      $composerName(
              \$db: \$db,
              \$table: ${_referenceTableFromComposer(relation.referencedTable, leaf)},
              \$addJoinBuilderToRootComposer: \$addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              \$removeJoinBuilderFromRootComposer:
                  \$removeJoinBuilderFromRootComposer,
        ));""";
  }

  /// Returns the name of the processed table manager class for a table
  ///
  /// This does not contain any prefixes, as this will always be generated in the same file
  /// as the table manager and is not used outside of the file
  ///
  /// E.g. `$UserTableProcessedTableManager`
  String processedTableManagerTypedefName(DriftTable table, TextEmitter leaf,
      {bool forDefinition = false}) {
    final name = '\$${table.entityInfoName}ProcessedTableManager';
    return forDefinition
        ? name
        : leaf.dartCode(leaf.generatedElement(table, name));
  }

  /// Code for a processed table manager typedef
  String processedTableManagerTypeDef({
    required DriftTable table,
    required String dbClassName,
    required TextEmitter leaf,
    required List<_Relation> relations,
  }) {
    return """typedef ${processedTableManagerTypedefName(table, leaf, forDefinition: true)} = ${leaf.drift("ProcessedTableManager")}${_tableManagerTypeArguments(table, dbClassName, leaf, relations)};""";
  }

  /// Name of the class which is used to represent a rows references
  ///
  /// If there are no relations, or if generation is modular, we will generate a base class instead.
  String rowReferencesClassName({
    required DriftTable table,
    required List<_Relation> relations,
    required String dbClassName,
    required TextEmitter leaf,
    required bool withTypeArgs,
    bool forDefinition = false,
  }) {
    if (relations.isNotEmpty) {
      final basename = '\$${table.entityInfoName}References';

      if (forDefinition) {
        return basename;
      } else {
        return leaf.dartCode(leaf.generatedElement(table, basename));
      }
    } else {
      if (withTypeArgs) {
        return "${leaf.drift('BaseReferences')}<${databaseType(leaf, dbClassName)},${tableClassWithPrefix(table, leaf)},${rowClassWithPrefix(table, leaf)}>";
      } else {
        return leaf.drift('BaseReferences');
      }
    }
  }

  // The name of the type defenition to use for the callback that creates the prefetches class
  String createCreatePrefetchHooksCallbackType(
      {required DriftTable currentTable,
      required List<_Relation> relations,
      required TextEmitter leaf,
      required String dbClassName}) {
    return "${leaf.drift("PrefetchHooks")} Function(${relations.isEmpty ? '' : '{${relations.map((e) => 'bool ${e.fieldName}').join(',')}}'})";
  }

  /// Name of the class which is used to represent a rows references
  ///
  /// If there are no relations, or if generation is modular, we will generate a base class instead.
  String rowReferencesClass(
      {required DriftTable table,
      required List<_Relation> relations,
      required String dbClassName,
      required TextEmitter leaf}) {
    final String rowClassWithReferencesName = rowReferencesClassName(
        table: table,
        relations: relations,
        dbClassName: dbClassName,
        leaf: leaf,
        withTypeArgs: false,
        forDefinition: true);

    final body = relations.map(
      (relation) {
        final dbName = databaseType(leaf, dbClassName);
        final referencedTable = leaf
            .dartCode(leaf.referenceElement(relation.referencedTable, 'db'));
        final currentTable =
            leaf.dartCode(leaf.referenceElement(relation.currentTable, 'db'));
        final currentColumnType =
            leaf.dartCode(leaf.innerColumnType(relation.currentColumn.sqlType));
        var itemColumn =
            '\$_itemColumn<$currentColumnType>(${asDartLiteral(relation.currentColumn.nameInSql)})';
        if (!relation.currentColumn.nullable) {
          itemColumn += '!';
        }

        if (relation.isReverse) {
          final aliasedTableMethod = """
        static ${leaf.drift("MultiTypedResultKey")}<
          ${tableClassWithPrefix(relation.referencedTable, leaf)},
          List<${rowClassWithPrefix(relation.referencedTable, leaf)}>
        > _${relation.fieldName}Table($dbName db) =>
          ${leaf.drift("MultiTypedResultKey")}.fromTable(
          $referencedTable,
          aliasName: ${leaf.drift("\$_aliasNameGenerator")}(
            $currentTable.${relation.currentColumn.nameInDart},
            $referencedTable.${relation.referencedColumn.nameInDart})
        );""";

          return """
          $aliasedTableMethod

          ${processedTableManagerTypedefName(relation.referencedTable, leaf)} get ${relation.fieldName} {
        final manager = ${rootTableManagerWithPrefix(relation.referencedTable, leaf)}(
            \$_db, ${leaf.dartCode(leaf.referenceElement(relation.referencedTable, r'$_db'))}
            ).filter(
              (f) => f.${relation.referencedColumn.nameInDart}.${relation.currentColumn.nameInDart}.sqlEquals(
                $itemColumn
            )
          );

          final cache = \$_typedResult.readTableOrNull(_${relation.fieldName}Table(\$_db));
          return ${leaf.drift("ProcessedTableManager")}(manager.\$state.copyWith(prefetchedData: cache));
        }
        """;
        } else {
          final referenceTableType =
              tableClassWithPrefix(relation.referencedTable, leaf);

          final aliasedTableMethod = """
          static $referenceTableType _${relation.fieldName}Table($dbName db) =>
            $referencedTable.createAlias(${leaf.drift("\$_aliasNameGenerator")}(
            $currentTable.${relation.currentColumn.nameInDart},
            $referencedTable.${relation.referencedColumn.nameInDart}));
          """;

          return """
        $aliasedTableMethod

        ${processedTableManagerTypedefName(relation.referencedTable, leaf)}${relation.currentColumn.nullable ? "?" : ""} get ${relation.fieldName} {
          final \$_column = $itemColumn;
          ${relation.currentColumn.nullable ? "if (\$_column == null) return null;" : ""}
          final manager = ${rootTableManagerWithPrefix(relation.referencedTable, leaf)}(\$_db, ${leaf.dartCode(leaf.referenceElement(relation.referencedTable, r'$_db'))}).filter((f) => f.${relation.referencedColumn.nameInDart}.sqlEquals(\$_column));
          final item = \$_typedResult.readTableOrNull(_${relation.fieldName}Table(\$_db));
          if (item == null) return manager;
          return ${leaf.drift("ProcessedTableManager")}(manager.\$state.copyWith(prefetchedData: [item]));
        }
""";
        }
      },
    ).join('\n');

    return """
      final class $rowClassWithReferencesName extends ${leaf.drift("BaseReferences")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)},
        ${rowClassWithPrefix(table, leaf)}> {
        $rowClassWithReferencesName(super.\$_db, super.\$_table, super.\$_typedResult);

        $body

      }""";
  }
}
