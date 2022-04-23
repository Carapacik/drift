// GENERATED CODE, DO NOT EDIT BY HAND.
//@dart=2.12
import 'package:drift/drift.dart';

class UsersData extends DataClass implements Insertable<UsersData> {
  final int id;
  final String name;
  final int? nextUser;
  UsersData({required this.id, required this.name, this.nextUser});
  factory UsersData.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return UsersData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      nextUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}next_user']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nextUser != null) {
      map['next_user'] = Variable<int?>(nextUser);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      nextUser: nextUser == null && nullToAbsent
          ? const Value.absent()
          : Value(nextUser),
    );
  }

  factory UsersData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nextUser: serializer.fromJson<int?>(json['nextUser']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nextUser': serializer.toJson<int?>(nextUser),
    };
  }

  UsersData copyWith({int? id, String? name, int? nextUser}) => UsersData(
        id: id ?? this.id,
        name: name ?? this.name,
        nextUser: nextUser ?? this.nextUser,
      );
  @override
  String toString() {
    return (StringBuffer('UsersData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nextUser: $nextUser')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nextUser);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersData &&
          other.id == this.id &&
          other.name == this.name &&
          other.nextUser == this.nextUser);
}

class UsersCompanion extends UpdateCompanion<UsersData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> nextUser;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nextUser = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nextUser = const Value.absent(),
  });
  static Insertable<UsersData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int?>? nextUser,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nextUser != null) 'next_user': nextUser,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<int?>? nextUser}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nextUser: nextUser ?? this.nextUser,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nextUser.present) {
      map['next_user'] = Variable<int?>(nextUser.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nextUser: $nextUser')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo<Users, UsersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: false,
      defaultValue: const Constant('name'));
  late final GeneratedColumn<int?> nextUser = GeneratedColumn<int?>(
      'next_user', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'REFERENCES users (id)');
  @override
  List<GeneratedColumn> get $columns => [id, name, nextUser];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return UsersData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => false;
}

class GroupsData extends DataClass implements Insertable<GroupsData> {
  final int id;
  final String title;
  final bool? deleted;
  final int owner;
  GroupsData(
      {required this.id,
      required this.title,
      this.deleted,
      required this.owner});
  factory GroupsData.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupsData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      deleted: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}deleted']),
      owner: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}owner'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || deleted != null) {
      map['deleted'] = Variable<bool?>(deleted);
    }
    map['owner'] = Variable<int>(owner);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      title: Value(title),
      deleted: deleted == null && nullToAbsent
          ? const Value.absent()
          : Value(deleted),
      owner: Value(owner),
    );
  }

  factory GroupsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupsData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      deleted: serializer.fromJson<bool?>(json['deleted']),
      owner: serializer.fromJson<int>(json['owner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'deleted': serializer.toJson<bool?>(deleted),
      'owner': serializer.toJson<int>(owner),
    };
  }

  GroupsData copyWith({int? id, String? title, bool? deleted, int? owner}) =>
      GroupsData(
        id: id ?? this.id,
        title: title ?? this.title,
        deleted: deleted ?? this.deleted,
        owner: owner ?? this.owner,
      );
  @override
  String toString() {
    return (StringBuffer('GroupsData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, deleted, owner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupsData &&
          other.id == this.id &&
          other.title == this.title &&
          other.deleted == this.deleted &&
          other.owner == this.owner);
}

class GroupsCompanion extends UpdateCompanion<GroupsData> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool?> deleted;
  final Value<int> owner;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.deleted = const Value.absent(),
    this.owner = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.deleted = const Value.absent(),
    required int owner,
  })  : title = Value(title),
        owner = Value(owner);
  static Insertable<GroupsData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool?>? deleted,
    Expression<int>? owner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (deleted != null) 'deleted': deleted,
      if (owner != null) 'owner': owner,
    });
  }

  GroupsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<bool?>? deleted,
      Value<int>? owner}) {
    return GroupsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      deleted: deleted ?? this.deleted,
      owner: owner ?? this.owner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool?>(deleted.value);
    }
    if (owner.present) {
      map['owner'] = Variable<int>(owner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }
}

class Groups extends Table with TableInfo<Groups, GroupsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<bool?> deleted = GeneratedColumn<bool?>(
      'deleted', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT FALSE',
      defaultValue: const CustomExpression<bool>('FALSE'));
  late final GeneratedColumn<int?> owner = GeneratedColumn<int?>(
      'owner', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users (id)');
  @override
  List<GeneratedColumn> get $columns => [id, title, deleted, owner];
  @override
  String get aliasedName => _alias ?? 'groups';
  @override
  String get actualTableName => 'groups';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupsData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY (id)'];
  @override
  bool get dontWriteConstraints => true;
}

class GroupCountData extends DataClass {
  final int id;
  final String name;
  final int? nextUser;
  final int groupCount;
  GroupCountData(
      {required this.id,
      required this.name,
      this.nextUser,
      required this.groupCount});
  factory GroupCountData.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupCountData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      nextUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}next_user']),
      groupCount: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}group_count'])!,
    );
  }
  factory GroupCountData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupCountData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nextUser: serializer.fromJson<int?>(json['nextUser']),
      groupCount: serializer.fromJson<int>(json['groupCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nextUser': serializer.toJson<int?>(nextUser),
      'groupCount': serializer.toJson<int>(groupCount),
    };
  }

  GroupCountData copyWith(
          {int? id, String? name, int? nextUser, int? groupCount}) =>
      GroupCountData(
        id: id ?? this.id,
        name: name ?? this.name,
        nextUser: nextUser ?? this.nextUser,
        groupCount: groupCount ?? this.groupCount,
      );
  @override
  String toString() {
    return (StringBuffer('GroupCountData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nextUser: $nextUser, ')
          ..write('groupCount: $groupCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nextUser, groupCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupCountData &&
          other.id == this.id &&
          other.name == this.name &&
          other.nextUser == this.nextUser &&
          other.groupCount == this.groupCount);
}

class GroupCount extends ViewInfo<GroupCount, GroupCountData>
    implements HasResultSet {
  final String? _alias;
  @override
  final DatabaseAtV5 attachedDatabase;
  GroupCount(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [id, name, nextUser, groupCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'group_count';
  @override
  String? get createViewStmt => null;
  @override
  GroupCount get asDslTable => this;
  @override
  GroupCountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupCountData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  late final GeneratedColumn<int?> id =
      GeneratedColumn<int?>('id', aliasedName, false, type: const IntType());
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType());
  late final GeneratedColumn<int?> nextUser = GeneratedColumn<int?>(
      'next_user', aliasedName, true,
      type: const IntType());
  late final GeneratedColumn<int?> groupCount = GeneratedColumn<int?>(
      'group_count', aliasedName, false,
      type: const IntType());
  @override
  GroupCount createAlias(String alias) {
    return GroupCount(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {};
}

class DatabaseAtV5 extends GeneratedDatabase {
  DatabaseAtV5(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  DatabaseAtV5.connect(DatabaseConnection c) : super.connect(c);
  late final Users users = Users(this);
  late final Groups groups = Groups(this);
  late final GroupCount groupCount = GroupCount(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [users, groups, groupCount];
  @override
  int get schemaVersion => 5;
}