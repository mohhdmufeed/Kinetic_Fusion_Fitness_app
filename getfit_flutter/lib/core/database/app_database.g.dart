// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _musclesMeta =
      const VerificationMeta('muscles');
  @override
  late final GeneratedColumn<String> muscles = GeneratedColumn<String>(
      'muscles', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _equipmentMeta =
      const VerificationMeta('equipment');
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
      'equipment', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, uuid, name, description, category, muscles, equipment, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('muscles')) {
      context.handle(_musclesMeta,
          muscles.isAcceptableOrUnknown(data['muscles']!, _musclesMeta));
    }
    if (data.containsKey('equipment')) {
      context.handle(_equipmentMeta,
          equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      muscles: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}muscles'])!,
      equipment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final String category;
  final String muscles;
  final String equipment;
  final String imageUrl;
  const Exercise(
      {required this.id,
      required this.uuid,
      required this.name,
      required this.description,
      required this.category,
      required this.muscles,
      required this.equipment,
      required this.imageUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['muscles'] = Variable<String>(muscles);
    map['equipment'] = Variable<String>(equipment);
    map['image_url'] = Variable<String>(imageUrl);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      description: Value(description),
      category: Value(category),
      muscles: Value(muscles),
      equipment: Value(equipment),
      imageUrl: Value(imageUrl),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      muscles: serializer.fromJson<String>(json['muscles']),
      equipment: serializer.fromJson<String>(json['equipment']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'muscles': serializer.toJson<String>(muscles),
      'equipment': serializer.toJson<String>(equipment),
      'imageUrl': serializer.toJson<String>(imageUrl),
    };
  }

  Exercise copyWith(
          {int? id,
          String? uuid,
          String? name,
          String? description,
          String? category,
          String? muscles,
          String? equipment,
          String? imageUrl}) =>
      Exercise(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        muscles: muscles ?? this.muscles,
        equipment: equipment ?? this.equipment,
        imageUrl: imageUrl ?? this.imageUrl,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      muscles: data.muscles.present ? data.muscles.value : this.muscles,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('muscles: $muscles, ')
          ..write('equipment: $equipment, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, uuid, name, description, category, muscles, equipment, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.muscles == this.muscles &&
          other.equipment == this.equipment &&
          other.imageUrl == this.imageUrl);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String> description;
  final Value<String> category;
  final Value<String> muscles;
  final Value<String> equipment;
  final Value<String> imageUrl;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.muscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.muscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.imageUrl = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? muscles,
    Expression<String>? equipment,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (muscles != null) 'muscles': muscles,
      if (equipment != null) 'equipment': equipment,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  ExercisesCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<String>? description,
      Value<String>? category,
      Value<String>? muscles,
      Value<String>? equipment,
      Value<String>? imageUrl}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      muscles: muscles ?? this.muscles,
      equipment: equipment ?? this.equipment,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (muscles.present) {
      map['muscles'] = Variable<String>(muscles.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('muscles: $muscles, ')
          ..write('equipment: $equipment, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, createdAt, pendingSync, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<Routine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final int id;
  final String name;
  final String description;
  final DateTime createdAt;
  final bool pendingSync;
  final bool isDeleted;
  const Routine(
      {required this.id,
      required this.name,
      required this.description,
      required this.createdAt,
      required this.pendingSync,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Routine copyWith(
          {int? id,
          String? name,
          String? description,
          DateTime? createdAt,
          bool? pendingSync,
          bool? isDeleted}) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        pendingSync: pendingSync ?? this.pendingSync,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, createdAt, pendingSync, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  RoutinesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Routine> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  RoutinesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<DateTime>? createdAt,
      Value<bool>? pendingSync,
      Value<bool>? isDeleted}) {
    return RoutinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDaysTable extends WorkoutDays
    with TableInfo<$WorkoutDaysTable, WorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
      'routine_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routines (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<String> dayOfWeek = GeneratedColumn<String>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, routineId, name, dayOfWeek, pendingSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_days';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}routine_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_of_week'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $WorkoutDaysTable createAlias(String alias) {
    return $WorkoutDaysTable(attachedDatabase, alias);
  }
}

class WorkoutDay extends DataClass implements Insertable<WorkoutDay> {
  final int id;
  final int routineId;
  final String name;
  final String dayOfWeek;
  final bool pendingSync;
  const WorkoutDay(
      {required this.id,
      required this.routineId,
      required this.name,
      required this.dayOfWeek,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['routine_id'] = Variable<int>(routineId);
    map['name'] = Variable<String>(name);
    map['day_of_week'] = Variable<String>(dayOfWeek);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  WorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaysCompanion(
      id: Value(id),
      routineId: Value(routineId),
      name: Value(name),
      dayOfWeek: Value(dayOfWeek),
      pendingSync: Value(pendingSync),
    );
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDay(
      id: serializer.fromJson<int>(json['id']),
      routineId: serializer.fromJson<int>(json['routineId']),
      name: serializer.fromJson<String>(json['name']),
      dayOfWeek: serializer.fromJson<String>(json['dayOfWeek']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routineId': serializer.toJson<int>(routineId),
      'name': serializer.toJson<String>(name),
      'dayOfWeek': serializer.toJson<String>(dayOfWeek),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  WorkoutDay copyWith(
          {int? id,
          int? routineId,
          String? name,
          String? dayOfWeek,
          bool? pendingSync}) =>
      WorkoutDay(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        name: name ?? this.name,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  WorkoutDay copyWithCompanion(WorkoutDaysCompanion data) {
    return WorkoutDay(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      name: data.name.present ? data.name.value : this.name,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDay(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('name: $name, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routineId, name, dayOfWeek, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDay &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.name == this.name &&
          other.dayOfWeek == this.dayOfWeek &&
          other.pendingSync == this.pendingSync);
}

class WorkoutDaysCompanion extends UpdateCompanion<WorkoutDay> {
  final Value<int> id;
  final Value<int> routineId;
  final Value<String> name;
  final Value<String> dayOfWeek;
  final Value<bool> pendingSync;
  const WorkoutDaysCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.name = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  WorkoutDaysCompanion.insert({
    this.id = const Value.absent(),
    required int routineId,
    this.name = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.pendingSync = const Value.absent(),
  }) : routineId = Value(routineId);
  static Insertable<WorkoutDay> custom({
    Expression<int>? id,
    Expression<int>? routineId,
    Expression<String>? name,
    Expression<String>? dayOfWeek,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (name != null) 'name': name,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  WorkoutDaysCompanion copyWith(
      {Value<int>? id,
      Value<int>? routineId,
      Value<String>? name,
      Value<String>? dayOfWeek,
      Value<bool>? pendingSync}) {
    return WorkoutDaysCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<String>(dayOfWeek.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaysCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('name: $name, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSlotsTable extends WorkoutSlots
    with TableInfo<$WorkoutSlotsTable, WorkoutSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
      'day_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_days (id)'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, dayId, exerciseId, order, pendingSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_slots';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSlot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
          _dayIdMeta, dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta));
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSlot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_id'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $WorkoutSlotsTable createAlias(String alias) {
    return $WorkoutSlotsTable(attachedDatabase, alias);
  }
}

class WorkoutSlot extends DataClass implements Insertable<WorkoutSlot> {
  final int id;
  final int dayId;
  final int exerciseId;
  final int order;
  final bool pendingSync;
  const WorkoutSlot(
      {required this.id,
      required this.dayId,
      required this.exerciseId,
      required this.order,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['order'] = Variable<int>(order);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  WorkoutSlotsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSlotsCompanion(
      id: Value(id),
      dayId: Value(dayId),
      exerciseId: Value(exerciseId),
      order: Value(order),
      pendingSync: Value(pendingSync),
    );
  }

  factory WorkoutSlot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSlot(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      order: serializer.fromJson<int>(json['order']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'order': serializer.toJson<int>(order),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  WorkoutSlot copyWith(
          {int? id,
          int? dayId,
          int? exerciseId,
          int? order,
          bool? pendingSync}) =>
      WorkoutSlot(
        id: id ?? this.id,
        dayId: dayId ?? this.dayId,
        exerciseId: exerciseId ?? this.exerciseId,
        order: order ?? this.order,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  WorkoutSlot copyWithCompanion(WorkoutSlotsCompanion data) {
    return WorkoutSlot(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      order: data.order.present ? data.order.value : this.order,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSlot(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('order: $order, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, exerciseId, order, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSlot &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.exerciseId == this.exerciseId &&
          other.order == this.order &&
          other.pendingSync == this.pendingSync);
}

class WorkoutSlotsCompanion extends UpdateCompanion<WorkoutSlot> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<int> exerciseId;
  final Value<int> order;
  final Value<bool> pendingSync;
  const WorkoutSlotsCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.order = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  WorkoutSlotsCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required int exerciseId,
    this.order = const Value.absent(),
    this.pendingSync = const Value.absent(),
  })  : dayId = Value(dayId),
        exerciseId = Value(exerciseId);
  static Insertable<WorkoutSlot> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<int>? exerciseId,
    Expression<int>? order,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (order != null) 'order': order,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  WorkoutSlotsCompanion copyWith(
      {Value<int>? id,
      Value<int>? dayId,
      Value<int>? exerciseId,
      Value<int>? order,
      Value<bool>? pendingSync}) {
    return WorkoutSlotsCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSlotsCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('order: $order, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $WorkoutLogsTable extends WorkoutLogs
    with TableInfo<$WorkoutLogsTable, WorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
      'sets', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exerciseId,
        routineId,
        weight,
        reps,
        sets,
        date,
        notes,
        pendingSync,
        serverId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('sets')) {
      context.handle(
          _setsMeta, sets.isAcceptableOrUnknown(data['sets']!, _setsMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_id'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}routine_id']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      sets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sets'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $WorkoutLogsTable createAlias(String alias) {
    return $WorkoutLogsTable(attachedDatabase, alias);
  }
}

class WorkoutLog extends DataClass implements Insertable<WorkoutLog> {
  final int id;
  final int exerciseId;
  final int? routineId;
  final double weight;
  final int reps;
  final int sets;
  final DateTime date;
  final String notes;
  final bool pendingSync;
  final int? serverId;
  const WorkoutLog(
      {required this.id,
      required this.exerciseId,
      this.routineId,
      required this.weight,
      required this.reps,
      required this.sets,
      required this.date,
      required this.notes,
      required this.pendingSync,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<int>(routineId);
    }
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<int>(reps);
    map['sets'] = Variable<int>(sets);
    map['date'] = Variable<DateTime>(date);
    map['notes'] = Variable<String>(notes);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    return map;
  }

  WorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutLogsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      weight: Value(weight),
      reps: Value(reps),
      sets: Value(sets),
      date: Value(date),
      notes: Value(notes),
      pendingSync: Value(pendingSync),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutLog(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      routineId: serializer.fromJson<int?>(json['routineId']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<int>(json['reps']),
      sets: serializer.fromJson<int>(json['sets']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      serverId: serializer.fromJson<int?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'routineId': serializer.toJson<int?>(routineId),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<int>(reps),
      'sets': serializer.toJson<int>(sets),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String>(notes),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'serverId': serializer.toJson<int?>(serverId),
    };
  }

  WorkoutLog copyWith(
          {int? id,
          int? exerciseId,
          Value<int?> routineId = const Value.absent(),
          double? weight,
          int? reps,
          int? sets,
          DateTime? date,
          String? notes,
          bool? pendingSync,
          Value<int?> serverId = const Value.absent()}) =>
      WorkoutLog(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        routineId: routineId.present ? routineId.value : this.routineId,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        sets: sets ?? this.sets,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        pendingSync: pendingSync ?? this.pendingSync,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  WorkoutLog copyWithCompanion(WorkoutLogsCompanion data) {
    return WorkoutLog(
      id: data.id.present ? data.id.value : this.id,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      sets: data.sets.present ? data.sets.value : this.sets,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLog(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('routineId: $routineId, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('sets: $sets, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, routineId, weight, reps, sets,
      date, notes, pendingSync, serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutLog &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.routineId == this.routineId &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.sets == this.sets &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.pendingSync == this.pendingSync &&
          other.serverId == this.serverId);
}

class WorkoutLogsCompanion extends UpdateCompanion<WorkoutLog> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<int?> routineId;
  final Value<double> weight;
  final Value<int> reps;
  final Value<int> sets;
  final Value<DateTime> date;
  final Value<String> notes;
  final Value<bool> pendingSync;
  final Value<int?> serverId;
  const WorkoutLogsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.sets = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  });
  WorkoutLogsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    this.routineId = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.sets = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  }) : exerciseId = Value(exerciseId);
  static Insertable<WorkoutLog> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<int>? routineId,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? sets,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<bool>? pendingSync,
    Expression<int>? serverId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (routineId != null) 'routine_id': routineId,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (sets != null) 'sets': sets,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (serverId != null) 'server_id': serverId,
    });
  }

  WorkoutLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? exerciseId,
      Value<int?>? routineId,
      Value<double>? weight,
      Value<int>? reps,
      Value<int>? sets,
      Value<DateTime>? date,
      Value<String>? notes,
      Value<bool>? pendingSync,
      Value<int?>? serverId}) {
    return WorkoutLogsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      routineId: routineId ?? this.routineId,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      pendingSync: pendingSync ?? this.pendingSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLogsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('routineId: $routineId, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('sets: $sets, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<double> energy = GeneratedColumn<double>(
      'energy', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _proteinMeta =
      const VerificationMeta('protein');
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
      'protein', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
      'carbs', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
      'fat', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _fiberMeta = const VerificationMeta('fiber');
  @override
  late final GeneratedColumn<double> fiber = GeneratedColumn<double>(
      'fiber', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sugarMeta = const VerificationMeta('sugar');
  @override
  late final GeneratedColumn<double> sugar = GeneratedColumn<double>(
      'sugar', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, energy, protein, carbs, fat, fiber, sugar, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(Insertable<Ingredient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('energy')) {
      context.handle(_energyMeta,
          energy.isAcceptableOrUnknown(data['energy']!, _energyMeta));
    }
    if (data.containsKey('protein')) {
      context.handle(_proteinMeta,
          protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta));
    }
    if (data.containsKey('carbs')) {
      context.handle(
          _carbsMeta, carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta));
    }
    if (data.containsKey('fat')) {
      context.handle(
          _fatMeta, fat.isAcceptableOrUnknown(data['fat']!, _fatMeta));
    }
    if (data.containsKey('fiber')) {
      context.handle(
          _fiberMeta, fiber.isAcceptableOrUnknown(data['fiber']!, _fiberMeta));
    }
    if (data.containsKey('sugar')) {
      context.handle(
          _sugarMeta, sugar.isAcceptableOrUnknown(data['sugar']!, _sugarMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      energy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}energy'])!,
      protein: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein'])!,
      carbs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs'])!,
      fat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat'])!,
      fiber: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fiber']),
      sugar: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sugar']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url'])!,
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final int id;
  final String name;
  final double energy;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final String imageUrl;
  const Ingredient(
      {required this.id,
      required this.name,
      required this.energy,
      required this.protein,
      required this.carbs,
      required this.fat,
      this.fiber,
      this.sugar,
      required this.imageUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['energy'] = Variable<double>(energy);
    map['protein'] = Variable<double>(protein);
    map['carbs'] = Variable<double>(carbs);
    map['fat'] = Variable<double>(fat);
    if (!nullToAbsent || fiber != null) {
      map['fiber'] = Variable<double>(fiber);
    }
    if (!nullToAbsent || sugar != null) {
      map['sugar'] = Variable<double>(sugar);
    }
    map['image_url'] = Variable<String>(imageUrl);
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      energy: Value(energy),
      protein: Value(protein),
      carbs: Value(carbs),
      fat: Value(fat),
      fiber:
          fiber == null && nullToAbsent ? const Value.absent() : Value(fiber),
      sugar:
          sugar == null && nullToAbsent ? const Value.absent() : Value(sugar),
      imageUrl: Value(imageUrl),
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      energy: serializer.fromJson<double>(json['energy']),
      protein: serializer.fromJson<double>(json['protein']),
      carbs: serializer.fromJson<double>(json['carbs']),
      fat: serializer.fromJson<double>(json['fat']),
      fiber: serializer.fromJson<double?>(json['fiber']),
      sugar: serializer.fromJson<double?>(json['sugar']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'energy': serializer.toJson<double>(energy),
      'protein': serializer.toJson<double>(protein),
      'carbs': serializer.toJson<double>(carbs),
      'fat': serializer.toJson<double>(fat),
      'fiber': serializer.toJson<double?>(fiber),
      'sugar': serializer.toJson<double?>(sugar),
      'imageUrl': serializer.toJson<String>(imageUrl),
    };
  }

  Ingredient copyWith(
          {int? id,
          String? name,
          double? energy,
          double? protein,
          double? carbs,
          double? fat,
          Value<double?> fiber = const Value.absent(),
          Value<double?> sugar = const Value.absent(),
          String? imageUrl}) =>
      Ingredient(
        id: id ?? this.id,
        name: name ?? this.name,
        energy: energy ?? this.energy,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber.present ? fiber.value : this.fiber,
        sugar: sugar.present ? sugar.value : this.sugar,
        imageUrl: imageUrl ?? this.imageUrl,
      );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      energy: data.energy.present ? data.energy.value : this.energy,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      fiber: data.fiber.present ? data.fiber.value : this.fiber,
      sugar: data.sugar.present ? data.sugar.value : this.sugar,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('energy: $energy, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('fiber: $fiber, ')
          ..write('sugar: $sugar, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, energy, protein, carbs, fat, fiber, sugar, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.energy == this.energy &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.fiber == this.fiber &&
          other.sugar == this.sugar &&
          other.imageUrl == this.imageUrl);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> energy;
  final Value<double> protein;
  final Value<double> carbs;
  final Value<double> fat;
  final Value<double?> fiber;
  final Value<double?> sugar;
  final Value<String> imageUrl;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.energy = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.fiber = const Value.absent(),
    this.sugar = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.energy = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.fiber = const Value.absent(),
    this.sugar = const Value.absent(),
    this.imageUrl = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Ingredient> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? energy,
    Expression<double>? protein,
    Expression<double>? carbs,
    Expression<double>? fat,
    Expression<double>? fiber,
    Expression<double>? sugar,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (energy != null) 'energy': energy,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (fiber != null) 'fiber': fiber,
      if (sugar != null) 'sugar': sugar,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  IngredientsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? energy,
      Value<double>? protein,
      Value<double>? carbs,
      Value<double>? fat,
      Value<double?>? fiber,
      Value<double?>? sugar,
      Value<String>? imageUrl}) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      energy: energy ?? this.energy,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      imageUrl: imageUrl ?? this.imageUrl,
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
    if (energy.present) {
      map['energy'] = Variable<double>(energy.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (fiber.present) {
      map['fiber'] = Variable<double>(fiber.value);
    }
    if (sugar.present) {
      map['sugar'] = Variable<double>(sugar.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('energy: $energy, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('fiber: $fiber, ')
          ..write('sugar: $sugar, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $NutritionPlansTable extends NutritionPlans
    with TableInfo<$NutritionPlansTable, NutritionPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('My Plan'));
  static const VerificationMeta _goalEnergyMeta =
      const VerificationMeta('goalEnergy');
  @override
  late final GeneratedColumn<double> goalEnergy = GeneratedColumn<double>(
      'goal_energy', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _goalProteinMeta =
      const VerificationMeta('goalProtein');
  @override
  late final GeneratedColumn<double> goalProtein = GeneratedColumn<double>(
      'goal_protein', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _goalCarbsMeta =
      const VerificationMeta('goalCarbs');
  @override
  late final GeneratedColumn<double> goalCarbs = GeneratedColumn<double>(
      'goal_carbs', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _goalFatMeta =
      const VerificationMeta('goalFat');
  @override
  late final GeneratedColumn<double> goalFat = GeneratedColumn<double>(
      'goal_fat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        description,
        goalEnergy,
        goalProtein,
        goalCarbs,
        goalFat,
        pendingSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_plans';
  @override
  VerificationContext validateIntegrity(Insertable<NutritionPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('goal_energy')) {
      context.handle(
          _goalEnergyMeta,
          goalEnergy.isAcceptableOrUnknown(
              data['goal_energy']!, _goalEnergyMeta));
    }
    if (data.containsKey('goal_protein')) {
      context.handle(
          _goalProteinMeta,
          goalProtein.isAcceptableOrUnknown(
              data['goal_protein']!, _goalProteinMeta));
    }
    if (data.containsKey('goal_carbs')) {
      context.handle(_goalCarbsMeta,
          goalCarbs.isAcceptableOrUnknown(data['goal_carbs']!, _goalCarbsMeta));
    }
    if (data.containsKey('goal_fat')) {
      context.handle(_goalFatMeta,
          goalFat.isAcceptableOrUnknown(data['goal_fat']!, _goalFatMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      goalEnergy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}goal_energy']),
      goalProtein: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}goal_protein']),
      goalCarbs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}goal_carbs']),
      goalFat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}goal_fat']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $NutritionPlansTable createAlias(String alias) {
    return $NutritionPlansTable(attachedDatabase, alias);
  }
}

class NutritionPlan extends DataClass implements Insertable<NutritionPlan> {
  final int id;
  final String description;
  final double? goalEnergy;
  final double? goalProtein;
  final double? goalCarbs;
  final double? goalFat;
  final bool pendingSync;
  const NutritionPlan(
      {required this.id,
      required this.description,
      this.goalEnergy,
      this.goalProtein,
      this.goalCarbs,
      this.goalFat,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || goalEnergy != null) {
      map['goal_energy'] = Variable<double>(goalEnergy);
    }
    if (!nullToAbsent || goalProtein != null) {
      map['goal_protein'] = Variable<double>(goalProtein);
    }
    if (!nullToAbsent || goalCarbs != null) {
      map['goal_carbs'] = Variable<double>(goalCarbs);
    }
    if (!nullToAbsent || goalFat != null) {
      map['goal_fat'] = Variable<double>(goalFat);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  NutritionPlansCompanion toCompanion(bool nullToAbsent) {
    return NutritionPlansCompanion(
      id: Value(id),
      description: Value(description),
      goalEnergy: goalEnergy == null && nullToAbsent
          ? const Value.absent()
          : Value(goalEnergy),
      goalProtein: goalProtein == null && nullToAbsent
          ? const Value.absent()
          : Value(goalProtein),
      goalCarbs: goalCarbs == null && nullToAbsent
          ? const Value.absent()
          : Value(goalCarbs),
      goalFat: goalFat == null && nullToAbsent
          ? const Value.absent()
          : Value(goalFat),
      pendingSync: Value(pendingSync),
    );
  }

  factory NutritionPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionPlan(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      goalEnergy: serializer.fromJson<double?>(json['goalEnergy']),
      goalProtein: serializer.fromJson<double?>(json['goalProtein']),
      goalCarbs: serializer.fromJson<double?>(json['goalCarbs']),
      goalFat: serializer.fromJson<double?>(json['goalFat']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'goalEnergy': serializer.toJson<double?>(goalEnergy),
      'goalProtein': serializer.toJson<double?>(goalProtein),
      'goalCarbs': serializer.toJson<double?>(goalCarbs),
      'goalFat': serializer.toJson<double?>(goalFat),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  NutritionPlan copyWith(
          {int? id,
          String? description,
          Value<double?> goalEnergy = const Value.absent(),
          Value<double?> goalProtein = const Value.absent(),
          Value<double?> goalCarbs = const Value.absent(),
          Value<double?> goalFat = const Value.absent(),
          bool? pendingSync}) =>
      NutritionPlan(
        id: id ?? this.id,
        description: description ?? this.description,
        goalEnergy: goalEnergy.present ? goalEnergy.value : this.goalEnergy,
        goalProtein: goalProtein.present ? goalProtein.value : this.goalProtein,
        goalCarbs: goalCarbs.present ? goalCarbs.value : this.goalCarbs,
        goalFat: goalFat.present ? goalFat.value : this.goalFat,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  NutritionPlan copyWithCompanion(NutritionPlansCompanion data) {
    return NutritionPlan(
      id: data.id.present ? data.id.value : this.id,
      description:
          data.description.present ? data.description.value : this.description,
      goalEnergy:
          data.goalEnergy.present ? data.goalEnergy.value : this.goalEnergy,
      goalProtein:
          data.goalProtein.present ? data.goalProtein.value : this.goalProtein,
      goalCarbs: data.goalCarbs.present ? data.goalCarbs.value : this.goalCarbs,
      goalFat: data.goalFat.present ? data.goalFat.value : this.goalFat,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionPlan(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('goalEnergy: $goalEnergy, ')
          ..write('goalProtein: $goalProtein, ')
          ..write('goalCarbs: $goalCarbs, ')
          ..write('goalFat: $goalFat, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, description, goalEnergy, goalProtein,
      goalCarbs, goalFat, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionPlan &&
          other.id == this.id &&
          other.description == this.description &&
          other.goalEnergy == this.goalEnergy &&
          other.goalProtein == this.goalProtein &&
          other.goalCarbs == this.goalCarbs &&
          other.goalFat == this.goalFat &&
          other.pendingSync == this.pendingSync);
}

class NutritionPlansCompanion extends UpdateCompanion<NutritionPlan> {
  final Value<int> id;
  final Value<String> description;
  final Value<double?> goalEnergy;
  final Value<double?> goalProtein;
  final Value<double?> goalCarbs;
  final Value<double?> goalFat;
  final Value<bool> pendingSync;
  const NutritionPlansCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.goalEnergy = const Value.absent(),
    this.goalProtein = const Value.absent(),
    this.goalCarbs = const Value.absent(),
    this.goalFat = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  NutritionPlansCompanion.insert({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.goalEnergy = const Value.absent(),
    this.goalProtein = const Value.absent(),
    this.goalCarbs = const Value.absent(),
    this.goalFat = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  static Insertable<NutritionPlan> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<double>? goalEnergy,
    Expression<double>? goalProtein,
    Expression<double>? goalCarbs,
    Expression<double>? goalFat,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (goalEnergy != null) 'goal_energy': goalEnergy,
      if (goalProtein != null) 'goal_protein': goalProtein,
      if (goalCarbs != null) 'goal_carbs': goalCarbs,
      if (goalFat != null) 'goal_fat': goalFat,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  NutritionPlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? description,
      Value<double?>? goalEnergy,
      Value<double?>? goalProtein,
      Value<double?>? goalCarbs,
      Value<double?>? goalFat,
      Value<bool>? pendingSync}) {
    return NutritionPlansCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      goalEnergy: goalEnergy ?? this.goalEnergy,
      goalProtein: goalProtein ?? this.goalProtein,
      goalCarbs: goalCarbs ?? this.goalCarbs,
      goalFat: goalFat ?? this.goalFat,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (goalEnergy.present) {
      map['goal_energy'] = Variable<double>(goalEnergy.value);
    }
    if (goalProtein.present) {
      map['goal_protein'] = Variable<double>(goalProtein.value);
    }
    if (goalCarbs.present) {
      map['goal_carbs'] = Variable<double>(goalCarbs.value);
    }
    if (goalFat.present) {
      map['goal_fat'] = Variable<double>(goalFat.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionPlansCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('goalEnergy: $goalEnergy, ')
          ..write('goalProtein: $goalProtein, ')
          ..write('goalCarbs: $goalCarbs, ')
          ..write('goalFat: $goalFat, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES nutrition_plans (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Meal'));
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
      'time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, planId, name, time, pendingSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(Insertable<Meal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final int id;
  final int planId;
  final String name;
  final String? time;
  final bool pendingSync;
  const Meal(
      {required this.id,
      required this.planId,
      required this.name,
      this.time,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      planId: Value(planId),
      name: Value(name),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      pendingSync: Value(pendingSync),
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      name: serializer.fromJson<String>(json['name']),
      time: serializer.fromJson<String?>(json['time']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'name': serializer.toJson<String>(name),
      'time': serializer.toJson<String?>(time),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  Meal copyWith(
          {int? id,
          int? planId,
          String? name,
          Value<String?> time = const Value.absent(),
          bool? pendingSync}) =>
      Meal(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        name: name ?? this.name,
        time: time.present ? time.value : this.time,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      name: data.name.present ? data.name.value : this.name,
      time: data.time.present ? data.time.value : this.time,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('time: $time, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, name, time, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.name == this.name &&
          other.time == this.time &&
          other.pendingSync == this.pendingSync);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<int> id;
  final Value<int> planId;
  final Value<String> name;
  final Value<String?> time;
  final Value<bool> pendingSync;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.name = const Value.absent(),
    this.time = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  MealsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    this.name = const Value.absent(),
    this.time = const Value.absent(),
    this.pendingSync = const Value.absent(),
  }) : planId = Value(planId);
  static Insertable<Meal> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? name,
    Expression<String>? time,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (name != null) 'name': name,
      if (time != null) 'time': time,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  MealsCompanion copyWith(
      {Value<int>? id,
      Value<int>? planId,
      Value<String>? name,
      Value<String?>? time,
      Value<bool>? pendingSync}) {
    return MealsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      time: time ?? this.time,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('time: $time, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $MealItemsTable extends MealItems
    with TableInfo<$MealItemsTable, MealItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES meals (id)'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100.0));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, mealId, ingredientId, amount, pendingSync, serverId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_items';
  @override
  VerificationContext validateIntegrity(Insertable<MealItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meal_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $MealItemsTable createAlias(String alias) {
    return $MealItemsTable(attachedDatabase, alias);
  }
}

class MealItem extends DataClass implements Insertable<MealItem> {
  final int id;
  final int mealId;
  final int ingredientId;
  final double amount;
  final bool pendingSync;
  final int? serverId;
  const MealItem(
      {required this.id,
      required this.mealId,
      required this.ingredientId,
      required this.amount,
      required this.pendingSync,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_id'] = Variable<int>(mealId);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['amount'] = Variable<double>(amount);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    return map;
  }

  MealItemsCompanion toCompanion(bool nullToAbsent) {
    return MealItemsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      ingredientId: Value(ingredientId),
      amount: Value(amount),
      pendingSync: Value(pendingSync),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory MealItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealItem(
      id: serializer.fromJson<int>(json['id']),
      mealId: serializer.fromJson<int>(json['mealId']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      amount: serializer.fromJson<double>(json['amount']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      serverId: serializer.fromJson<int?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealId': serializer.toJson<int>(mealId),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'amount': serializer.toJson<double>(amount),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'serverId': serializer.toJson<int?>(serverId),
    };
  }

  MealItem copyWith(
          {int? id,
          int? mealId,
          int? ingredientId,
          double? amount,
          bool? pendingSync,
          Value<int?> serverId = const Value.absent()}) =>
      MealItem(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        ingredientId: ingredientId ?? this.ingredientId,
        amount: amount ?? this.amount,
        pendingSync: pendingSync ?? this.pendingSync,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  MealItem copyWithCompanion(MealItemsCompanion data) {
    return MealItem(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      amount: data.amount.present ? data.amount.value : this.amount,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealItem(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, mealId, ingredientId, amount, pendingSync, serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealItem &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.ingredientId == this.ingredientId &&
          other.amount == this.amount &&
          other.pendingSync == this.pendingSync &&
          other.serverId == this.serverId);
}

class MealItemsCompanion extends UpdateCompanion<MealItem> {
  final Value<int> id;
  final Value<int> mealId;
  final Value<int> ingredientId;
  final Value<double> amount;
  final Value<bool> pendingSync;
  final Value<int?> serverId;
  const MealItemsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.amount = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  });
  MealItemsCompanion.insert({
    this.id = const Value.absent(),
    required int mealId,
    required int ingredientId,
    this.amount = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  })  : mealId = Value(mealId),
        ingredientId = Value(ingredientId);
  static Insertable<MealItem> custom({
    Expression<int>? id,
    Expression<int>? mealId,
    Expression<int>? ingredientId,
    Expression<double>? amount,
    Expression<bool>? pendingSync,
    Expression<int>? serverId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (amount != null) 'amount': amount,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (serverId != null) 'server_id': serverId,
    });
  }

  MealItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? mealId,
      Value<int>? ingredientId,
      Value<double>? amount,
      Value<bool>? pendingSync,
      Value<int?>? serverId}) {
    return MealItemsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      ingredientId: ingredientId ?? this.ingredientId,
      amount: amount ?? this.amount,
      pendingSync: pendingSync ?? this.pendingSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealItemsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }
}

class $NutritionDiaryTable extends NutritionDiary
    with TableInfo<$NutritionDiaryTable, NutritionDiaryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionDiaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100.0));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, planId, ingredientId, amount, date, pendingSync, serverId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_diary';
  @override
  VerificationContext validateIntegrity(Insertable<NutritionDiaryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionDiaryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionDiaryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id']),
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $NutritionDiaryTable createAlias(String alias) {
    return $NutritionDiaryTable(attachedDatabase, alias);
  }
}

class NutritionDiaryData extends DataClass
    implements Insertable<NutritionDiaryData> {
  final int id;
  final int? planId;
  final int ingredientId;
  final double amount;
  final DateTime date;
  final bool pendingSync;
  final int? serverId;
  const NutritionDiaryData(
      {required this.id,
      this.planId,
      required this.ingredientId,
      required this.amount,
      required this.date,
      required this.pendingSync,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    return map;
  }

  NutritionDiaryCompanion toCompanion(bool nullToAbsent) {
    return NutritionDiaryCompanion(
      id: Value(id),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      ingredientId: Value(ingredientId),
      amount: Value(amount),
      date: Value(date),
      pendingSync: Value(pendingSync),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory NutritionDiaryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionDiaryData(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int?>(json['planId']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      serverId: serializer.fromJson<int?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int?>(planId),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'serverId': serializer.toJson<int?>(serverId),
    };
  }

  NutritionDiaryData copyWith(
          {int? id,
          Value<int?> planId = const Value.absent(),
          int? ingredientId,
          double? amount,
          DateTime? date,
          bool? pendingSync,
          Value<int?> serverId = const Value.absent()}) =>
      NutritionDiaryData(
        id: id ?? this.id,
        planId: planId.present ? planId.value : this.planId,
        ingredientId: ingredientId ?? this.ingredientId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        pendingSync: pendingSync ?? this.pendingSync,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  NutritionDiaryData copyWithCompanion(NutritionDiaryCompanion data) {
    return NutritionDiaryData(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionDiaryData(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, planId, ingredientId, amount, date, pendingSync, serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionDiaryData &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.ingredientId == this.ingredientId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.pendingSync == this.pendingSync &&
          other.serverId == this.serverId);
}

class NutritionDiaryCompanion extends UpdateCompanion<NutritionDiaryData> {
  final Value<int> id;
  final Value<int?> planId;
  final Value<int> ingredientId;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<bool> pendingSync;
  final Value<int?> serverId;
  const NutritionDiaryCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  });
  NutritionDiaryCompanion.insert({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    required int ingredientId,
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  }) : ingredientId = Value(ingredientId);
  static Insertable<NutritionDiaryData> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? ingredientId,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<bool>? pendingSync,
    Expression<int>? serverId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (serverId != null) 'server_id': serverId,
    });
  }

  NutritionDiaryCompanion copyWith(
      {Value<int>? id,
      Value<int?>? planId,
      Value<int>? ingredientId,
      Value<double>? amount,
      Value<DateTime>? date,
      Value<bool>? pendingSync,
      Value<int?>? serverId}) {
    return NutritionDiaryCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      ingredientId: ingredientId ?? this.ingredientId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      pendingSync: pendingSync ?? this.pendingSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionDiaryCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, weight, date, notes, pendingSync, serverId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WeightEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;
  final double weight;
  final DateTime date;
  final String notes;
  final bool pendingSync;
  final int? serverId;
  const WeightEntry(
      {required this.id,
      required this.weight,
      required this.date,
      required this.notes,
      required this.pendingSync,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['weight'] = Variable<double>(weight);
    map['date'] = Variable<DateTime>(date);
    map['notes'] = Variable<String>(notes);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      weight: Value(weight),
      date: Value(date),
      notes: Value(notes),
      pendingSync: Value(pendingSync),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      weight: serializer.fromJson<double>(json['weight']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      serverId: serializer.fromJson<int?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weight': serializer.toJson<double>(weight),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String>(notes),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'serverId': serializer.toJson<int?>(serverId),
    };
  }

  WeightEntry copyWith(
          {int? id,
          double? weight,
          DateTime? date,
          String? notes,
          bool? pendingSync,
          Value<int?> serverId = const Value.absent()}) =>
      WeightEntry(
        id: id ?? this.id,
        weight: weight ?? this.weight,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        pendingSync: pendingSync ?? this.pendingSync,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      weight: data.weight.present ? data.weight.value : this.weight,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weight, date, notes, pendingSync, serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.weight == this.weight &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.pendingSync == this.pendingSync &&
          other.serverId == this.serverId);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<double> weight;
  final Value<DateTime> date;
  final Value<String> notes;
  final Value<bool> pendingSync;
  final Value<int?> serverId;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.weight = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required double weight,
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  }) : weight = Value(weight);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<double>? weight,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<bool>? pendingSync,
    Expression<int>? serverId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weight != null) 'weight': weight,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (serverId != null) 'server_id': serverId,
    });
  }

  WeightEntriesCompanion copyWith(
      {Value<int>? id,
      Value<double>? weight,
      Value<DateTime>? date,
      Value<String>? notes,
      Value<bool>? pendingSync,
      Value<int?>? serverId}) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      pendingSync: pendingSync ?? this.pendingSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }
}

class $MeasurementCategoriesTable extends MeasurementCategories
    with TableInfo<$MeasurementCategoriesTable, MeasurementCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cm'));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, name, unit, pendingSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurement_categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<MeasurementCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $MeasurementCategoriesTable createAlias(String alias) {
    return $MeasurementCategoriesTable(attachedDatabase, alias);
  }
}

class MeasurementCategory extends DataClass
    implements Insertable<MeasurementCategory> {
  final int id;
  final String name;
  final String unit;
  final bool pendingSync;
  const MeasurementCategory(
      {required this.id,
      required this.name,
      required this.unit,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  MeasurementCategoriesCompanion toCompanion(bool nullToAbsent) {
    return MeasurementCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      pendingSync: Value(pendingSync),
    );
  }

  factory MeasurementCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  MeasurementCategory copyWith(
          {int? id, String? name, String? unit, bool? pendingSync}) =>
      MeasurementCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  MeasurementCategory copyWithCompanion(MeasurementCategoriesCompanion data) {
    return MeasurementCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unit, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.pendingSync == this.pendingSync);
}

class MeasurementCategoriesCompanion
    extends UpdateCompanion<MeasurementCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> pendingSync;
  const MeasurementCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  MeasurementCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.unit = const Value.absent(),
    this.pendingSync = const Value.absent(),
  }) : name = Value(name);
  static Insertable<MeasurementCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  MeasurementCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? unit,
      Value<bool>? pendingSync}) {
    return MeasurementCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      pendingSync: pendingSync ?? this.pendingSync,
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
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES measurement_categories (id)'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, value, date, notes, pendingSync, serverId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<Measurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;
  final int categoryId;
  final double value;
  final DateTime date;
  final String notes;
  final bool pendingSync;
  final int? serverId;
  const Measurement(
      {required this.id,
      required this.categoryId,
      required this.value,
      required this.date,
      required this.notes,
      required this.pendingSync,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['value'] = Variable<double>(value);
    map['date'] = Variable<DateTime>(date);
    map['notes'] = Variable<String>(notes);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      value: Value(value),
      date: Value(date),
      notes: Value(notes),
      pendingSync: Value(pendingSync),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      value: serializer.fromJson<double>(json['value']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      serverId: serializer.fromJson<int?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'value': serializer.toJson<double>(value),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String>(notes),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'serverId': serializer.toJson<int?>(serverId),
    };
  }

  Measurement copyWith(
          {int? id,
          int? categoryId,
          double? value,
          DateTime? date,
          String? notes,
          bool? pendingSync,
          Value<int?> serverId = const Value.absent()}) =>
      Measurement(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        value: value ?? this.value,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        pendingSync: pendingSync ?? this.pendingSync,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      value: data.value.present ? data.value.value : this.value,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('value: $value, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, value, date, notes, pendingSync, serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.value == this.value &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.pendingSync == this.pendingSync &&
          other.serverId == this.serverId);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<double> value;
  final Value<DateTime> date;
  final Value<String> notes;
  final Value<bool> pendingSync;
  final Value<int?> serverId;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.value = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required double value,
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.serverId = const Value.absent(),
  })  : categoryId = Value(categoryId),
        value = Value(value);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<double>? value,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<bool>? pendingSync,
    Expression<int>? serverId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (value != null) 'value': value,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (serverId != null) 'server_id': serverId,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoryId,
      Value<double>? value,
      Value<DateTime>? date,
      Value<String>? notes,
      Value<bool>? pendingSync,
      Value<int?>? serverId}) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      value: value ?? this.value,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      pendingSync: pendingSync ?? this.pendingSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('value: $value, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('User'));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
      'birth_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unspecified'));
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<int> heightCm = GeneratedColumn<int>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _weightUnitMeta =
      const VerificationMeta('weightUnit');
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
      'weight_unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('kg'));
  static const VerificationMeta _activityLevelMeta =
      const VerificationMeta('activityLevel');
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
      'activity_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('moderate'));
  static const VerificationMeta _professionMeta =
      const VerificationMeta('profession');
  @override
  late final GeneratedColumn<String> profession = GeneratedColumn<String>(
      'profession', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _workHoursMeta =
      const VerificationMeta('workHours');
  @override
  late final GeneratedColumn<double> workHours = GeneratedColumn<double>(
      'work_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(8.0));
  static const VerificationMeta _workIntensityMeta =
      const VerificationMeta('workIntensity');
  @override
  late final GeneratedColumn<String> workIntensity = GeneratedColumn<String>(
      'work_intensity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('low'));
  static const VerificationMeta _sportHoursMeta =
      const VerificationMeta('sportHours');
  @override
  late final GeneratedColumn<double> sportHours = GeneratedColumn<double>(
      'sport_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  static const VerificationMeta _sportIntensityMeta =
      const VerificationMeta('sportIntensity');
  @override
  late final GeneratedColumn<String> sportIntensity = GeneratedColumn<String>(
      'sport_intensity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _freetimeHoursMeta =
      const VerificationMeta('freetimeHours');
  @override
  late final GeneratedColumn<double> freetimeHours = GeneratedColumn<double>(
      'freetime_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _freetimeIntensityMeta =
      const VerificationMeta('freetimeIntensity');
  @override
  late final GeneratedColumn<String> freetimeIntensity =
      GeneratedColumn<String>('freetime_intensity', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('low'));
  static const VerificationMeta _sleepHoursMeta =
      const VerificationMeta('sleepHours');
  @override
  late final GeneratedColumn<double> sleepHours = GeneratedColumn<double>(
      'sleep_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(8.0));
  static const VerificationMeta _dailyMoveGoalCaloriesMeta =
      const VerificationMeta('dailyMoveGoalCalories');
  @override
  late final GeneratedColumn<int> dailyMoveGoalCalories = GeneratedColumn<int>(
      'daily_move_goal_calories', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(400));
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _moveGoalReminderMeta =
      const VerificationMeta('moveGoalReminder');
  @override
  late final GeneratedColumn<bool> moveGoalReminder = GeneratedColumn<bool>(
      'move_goal_reminder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("move_goal_reminder" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _weightReminderDaysMeta =
      const VerificationMeta('weightReminderDays');
  @override
  late final GeneratedColumn<int> weightReminderDays = GeneratedColumn<int>(
      'weight_reminder_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _workoutReminderMeta =
      const VerificationMeta('workoutReminder');
  @override
  late final GeneratedColumn<bool> workoutReminder = GeneratedColumn<bool>(
      'workout_reminder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("workout_reminder" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
      'last_sync', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        email,
        birthDate,
        sex,
        heightCm,
        weightKg,
        weightUnit,
        activityLevel,
        profession,
        workHours,
        workIntensity,
        sportHours,
        sportIntensity,
        freetimeHours,
        freetimeIntensity,
        sleepHours,
        dailyMoveGoalCalories,
        notificationsEnabled,
        moveGoalReminder,
        weightReminderDays,
        workoutReminder,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
          _weightUnitMeta,
          weightUnit.isAcceptableOrUnknown(
              data['weight_unit']!, _weightUnitMeta));
    }
    if (data.containsKey('activity_level')) {
      context.handle(
          _activityLevelMeta,
          activityLevel.isAcceptableOrUnknown(
              data['activity_level']!, _activityLevelMeta));
    }
    if (data.containsKey('profession')) {
      context.handle(
          _professionMeta,
          profession.isAcceptableOrUnknown(
              data['profession']!, _professionMeta));
    }
    if (data.containsKey('work_hours')) {
      context.handle(_workHoursMeta,
          workHours.isAcceptableOrUnknown(data['work_hours']!, _workHoursMeta));
    }
    if (data.containsKey('work_intensity')) {
      context.handle(
          _workIntensityMeta,
          workIntensity.isAcceptableOrUnknown(
              data['work_intensity']!, _workIntensityMeta));
    }
    if (data.containsKey('sport_hours')) {
      context.handle(
          _sportHoursMeta,
          sportHours.isAcceptableOrUnknown(
              data['sport_hours']!, _sportHoursMeta));
    }
    if (data.containsKey('sport_intensity')) {
      context.handle(
          _sportIntensityMeta,
          sportIntensity.isAcceptableOrUnknown(
              data['sport_intensity']!, _sportIntensityMeta));
    }
    if (data.containsKey('freetime_hours')) {
      context.handle(
          _freetimeHoursMeta,
          freetimeHours.isAcceptableOrUnknown(
              data['freetime_hours']!, _freetimeHoursMeta));
    }
    if (data.containsKey('freetime_intensity')) {
      context.handle(
          _freetimeIntensityMeta,
          freetimeIntensity.isAcceptableOrUnknown(
              data['freetime_intensity']!, _freetimeIntensityMeta));
    }
    if (data.containsKey('sleep_hours')) {
      context.handle(
          _sleepHoursMeta,
          sleepHours.isAcceptableOrUnknown(
              data['sleep_hours']!, _sleepHoursMeta));
    }
    if (data.containsKey('daily_move_goal_calories')) {
      context.handle(
          _dailyMoveGoalCaloriesMeta,
          dailyMoveGoalCalories.isAcceptableOrUnknown(
              data['daily_move_goal_calories']!, _dailyMoveGoalCaloriesMeta));
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    if (data.containsKey('move_goal_reminder')) {
      context.handle(
          _moveGoalReminderMeta,
          moveGoalReminder.isAcceptableOrUnknown(
              data['move_goal_reminder']!, _moveGoalReminderMeta));
    }
    if (data.containsKey('weight_reminder_days')) {
      context.handle(
          _weightReminderDaysMeta,
          weightReminderDays.isAcceptableOrUnknown(
              data['weight_reminder_days']!, _weightReminderDaysMeta));
    }
    if (data.containsKey('workout_reminder')) {
      context.handle(
          _workoutReminderMeta,
          workoutReminder.isAcceptableOrUnknown(
              data['workout_reminder']!, _workoutReminderMeta));
    }
    if (data.containsKey('last_sync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date']),
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height_cm']),
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      weightUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weight_unit'])!,
      activityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_level'])!,
      profession: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profession'])!,
      workHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}work_hours'])!,
      workIntensity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}work_intensity'])!,
      sportHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sport_hours'])!,
      sportIntensity: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sport_intensity'])!,
      freetimeHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}freetime_hours'])!,
      freetimeIntensity: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}freetime_intensity'])!,
      sleepHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sleep_hours'])!,
      dailyMoveGoalCalories: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}daily_move_goal_calories'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
      moveGoalReminder: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}move_goal_reminder'])!,
      weightReminderDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}weight_reminder_days'])!,
      workoutReminder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}workout_reminder'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync']),
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final int id;
  final String username;
  final String email;
  final DateTime? birthDate;
  final String sex;
  final int? heightCm;
  final double? weightKg;
  final String weightUnit;
  final String activityLevel;
  final String profession;
  final double workHours;
  final String workIntensity;
  final double sportHours;
  final String sportIntensity;
  final double freetimeHours;
  final String freetimeIntensity;
  final double sleepHours;
  final int dailyMoveGoalCalories;
  final bool notificationsEnabled;
  final bool moveGoalReminder;
  final int weightReminderDays;
  final bool workoutReminder;
  final DateTime? lastSync;
  const UserProfileData(
      {required this.id,
      required this.username,
      required this.email,
      this.birthDate,
      required this.sex,
      this.heightCm,
      this.weightKg,
      required this.weightUnit,
      required this.activityLevel,
      required this.profession,
      required this.workHours,
      required this.workIntensity,
      required this.sportHours,
      required this.sportIntensity,
      required this.freetimeHours,
      required this.freetimeIntensity,
      required this.sleepHours,
      required this.dailyMoveGoalCalories,
      required this.notificationsEnabled,
      required this.moveGoalReminder,
      required this.weightReminderDays,
      required this.workoutReminder,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    map['sex'] = Variable<String>(sex);
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<int>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['weight_unit'] = Variable<String>(weightUnit);
    map['activity_level'] = Variable<String>(activityLevel);
    map['profession'] = Variable<String>(profession);
    map['work_hours'] = Variable<double>(workHours);
    map['work_intensity'] = Variable<String>(workIntensity);
    map['sport_hours'] = Variable<double>(sportHours);
    map['sport_intensity'] = Variable<String>(sportIntensity);
    map['freetime_hours'] = Variable<double>(freetimeHours);
    map['freetime_intensity'] = Variable<String>(freetimeIntensity);
    map['sleep_hours'] = Variable<double>(sleepHours);
    map['daily_move_goal_calories'] = Variable<int>(dailyMoveGoalCalories);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['move_goal_reminder'] = Variable<bool>(moveGoalReminder);
    map['weight_reminder_days'] = Variable<int>(weightReminderDays);
    map['workout_reminder'] = Variable<bool>(workoutReminder);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      username: Value(username),
      email: Value(email),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      sex: Value(sex),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      weightUnit: Value(weightUnit),
      activityLevel: Value(activityLevel),
      profession: Value(profession),
      workHours: Value(workHours),
      workIntensity: Value(workIntensity),
      sportHours: Value(sportHours),
      sportIntensity: Value(sportIntensity),
      freetimeHours: Value(freetimeHours),
      freetimeIntensity: Value(freetimeIntensity),
      sleepHours: Value(sleepHours),
      dailyMoveGoalCalories: Value(dailyMoveGoalCalories),
      notificationsEnabled: Value(notificationsEnabled),
      moveGoalReminder: Value(moveGoalReminder),
      weightReminderDays: Value(weightReminderDays),
      workoutReminder: Value(workoutReminder),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      email: serializer.fromJson<String>(json['email']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      sex: serializer.fromJson<String>(json['sex']),
      heightCm: serializer.fromJson<int?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      profession: serializer.fromJson<String>(json['profession']),
      workHours: serializer.fromJson<double>(json['workHours']),
      workIntensity: serializer.fromJson<String>(json['workIntensity']),
      sportHours: serializer.fromJson<double>(json['sportHours']),
      sportIntensity: serializer.fromJson<String>(json['sportIntensity']),
      freetimeHours: serializer.fromJson<double>(json['freetimeHours']),
      freetimeIntensity: serializer.fromJson<String>(json['freetimeIntensity']),
      sleepHours: serializer.fromJson<double>(json['sleepHours']),
      dailyMoveGoalCalories:
          serializer.fromJson<int>(json['dailyMoveGoalCalories']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
      moveGoalReminder: serializer.fromJson<bool>(json['moveGoalReminder']),
      weightReminderDays: serializer.fromJson<int>(json['weightReminderDays']),
      workoutReminder: serializer.fromJson<bool>(json['workoutReminder']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'email': serializer.toJson<String>(email),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'sex': serializer.toJson<String>(sex),
      'heightCm': serializer.toJson<int?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'profession': serializer.toJson<String>(profession),
      'workHours': serializer.toJson<double>(workHours),
      'workIntensity': serializer.toJson<String>(workIntensity),
      'sportHours': serializer.toJson<double>(sportHours),
      'sportIntensity': serializer.toJson<String>(sportIntensity),
      'freetimeHours': serializer.toJson<double>(freetimeHours),
      'freetimeIntensity': serializer.toJson<String>(freetimeIntensity),
      'sleepHours': serializer.toJson<double>(sleepHours),
      'dailyMoveGoalCalories': serializer.toJson<int>(dailyMoveGoalCalories),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'moveGoalReminder': serializer.toJson<bool>(moveGoalReminder),
      'weightReminderDays': serializer.toJson<int>(weightReminderDays),
      'workoutReminder': serializer.toJson<bool>(workoutReminder),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
    };
  }

  UserProfileData copyWith(
          {int? id,
          String? username,
          String? email,
          Value<DateTime?> birthDate = const Value.absent(),
          String? sex,
          Value<int?> heightCm = const Value.absent(),
          Value<double?> weightKg = const Value.absent(),
          String? weightUnit,
          String? activityLevel,
          String? profession,
          double? workHours,
          String? workIntensity,
          double? sportHours,
          String? sportIntensity,
          double? freetimeHours,
          String? freetimeIntensity,
          double? sleepHours,
          int? dailyMoveGoalCalories,
          bool? notificationsEnabled,
          bool? moveGoalReminder,
          int? weightReminderDays,
          bool? workoutReminder,
          Value<DateTime?> lastSync = const Value.absent()}) =>
      UserProfileData(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        birthDate: birthDate.present ? birthDate.value : this.birthDate,
        sex: sex ?? this.sex,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        weightKg: weightKg.present ? weightKg.value : this.weightKg,
        weightUnit: weightUnit ?? this.weightUnit,
        activityLevel: activityLevel ?? this.activityLevel,
        profession: profession ?? this.profession,
        workHours: workHours ?? this.workHours,
        workIntensity: workIntensity ?? this.workIntensity,
        sportHours: sportHours ?? this.sportHours,
        sportIntensity: sportIntensity ?? this.sportIntensity,
        freetimeHours: freetimeHours ?? this.freetimeHours,
        freetimeIntensity: freetimeIntensity ?? this.freetimeIntensity,
        sleepHours: sleepHours ?? this.sleepHours,
        dailyMoveGoalCalories:
            dailyMoveGoalCalories ?? this.dailyMoveGoalCalories,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        moveGoalReminder: moveGoalReminder ?? this.moveGoalReminder,
        weightReminderDays: weightReminderDays ?? this.weightReminderDays,
        workoutReminder: workoutReminder ?? this.workoutReminder,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      email: data.email.present ? data.email.value : this.email,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      weightUnit:
          data.weightUnit.present ? data.weightUnit.value : this.weightUnit,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      profession:
          data.profession.present ? data.profession.value : this.profession,
      workHours: data.workHours.present ? data.workHours.value : this.workHours,
      workIntensity: data.workIntensity.present
          ? data.workIntensity.value
          : this.workIntensity,
      sportHours:
          data.sportHours.present ? data.sportHours.value : this.sportHours,
      sportIntensity: data.sportIntensity.present
          ? data.sportIntensity.value
          : this.sportIntensity,
      freetimeHours: data.freetimeHours.present
          ? data.freetimeHours.value
          : this.freetimeHours,
      freetimeIntensity: data.freetimeIntensity.present
          ? data.freetimeIntensity.value
          : this.freetimeIntensity,
      sleepHours:
          data.sleepHours.present ? data.sleepHours.value : this.sleepHours,
      dailyMoveGoalCalories: data.dailyMoveGoalCalories.present
          ? data.dailyMoveGoalCalories.value
          : this.dailyMoveGoalCalories,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      moveGoalReminder: data.moveGoalReminder.present
          ? data.moveGoalReminder.value
          : this.moveGoalReminder,
      weightReminderDays: data.weightReminderDays.present
          ? data.weightReminderDays.value
          : this.weightReminderDays,
      workoutReminder: data.workoutReminder.present
          ? data.workoutReminder.value
          : this.workoutReminder,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('profession: $profession, ')
          ..write('workHours: $workHours, ')
          ..write('workIntensity: $workIntensity, ')
          ..write('sportHours: $sportHours, ')
          ..write('sportIntensity: $sportIntensity, ')
          ..write('freetimeHours: $freetimeHours, ')
          ..write('freetimeIntensity: $freetimeIntensity, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('dailyMoveGoalCalories: $dailyMoveGoalCalories, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('moveGoalReminder: $moveGoalReminder, ')
          ..write('weightReminderDays: $weightReminderDays, ')
          ..write('workoutReminder: $workoutReminder, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        username,
        email,
        birthDate,
        sex,
        heightCm,
        weightKg,
        weightUnit,
        activityLevel,
        profession,
        workHours,
        workIntensity,
        sportHours,
        sportIntensity,
        freetimeHours,
        freetimeIntensity,
        sleepHours,
        dailyMoveGoalCalories,
        notificationsEnabled,
        moveGoalReminder,
        weightReminderDays,
        workoutReminder,
        lastSync
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.username == this.username &&
          other.email == this.email &&
          other.birthDate == this.birthDate &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.weightUnit == this.weightUnit &&
          other.activityLevel == this.activityLevel &&
          other.profession == this.profession &&
          other.workHours == this.workHours &&
          other.workIntensity == this.workIntensity &&
          other.sportHours == this.sportHours &&
          other.sportIntensity == this.sportIntensity &&
          other.freetimeHours == this.freetimeHours &&
          other.freetimeIntensity == this.freetimeIntensity &&
          other.sleepHours == this.sleepHours &&
          other.dailyMoveGoalCalories == this.dailyMoveGoalCalories &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.moveGoalReminder == this.moveGoalReminder &&
          other.weightReminderDays == this.weightReminderDays &&
          other.workoutReminder == this.workoutReminder &&
          other.lastSync == this.lastSync);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> email;
  final Value<DateTime?> birthDate;
  final Value<String> sex;
  final Value<int?> heightCm;
  final Value<double?> weightKg;
  final Value<String> weightUnit;
  final Value<String> activityLevel;
  final Value<String> profession;
  final Value<double> workHours;
  final Value<String> workIntensity;
  final Value<double> sportHours;
  final Value<String> sportIntensity;
  final Value<double> freetimeHours;
  final Value<String> freetimeIntensity;
  final Value<double> sleepHours;
  final Value<int> dailyMoveGoalCalories;
  final Value<bool> notificationsEnabled;
  final Value<bool> moveGoalReminder;
  final Value<int> weightReminderDays;
  final Value<bool> workoutReminder;
  final Value<DateTime?> lastSync;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.profession = const Value.absent(),
    this.workHours = const Value.absent(),
    this.workIntensity = const Value.absent(),
    this.sportHours = const Value.absent(),
    this.sportIntensity = const Value.absent(),
    this.freetimeHours = const Value.absent(),
    this.freetimeIntensity = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.dailyMoveGoalCalories = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.moveGoalReminder = const Value.absent(),
    this.weightReminderDays = const Value.absent(),
    this.workoutReminder = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.profession = const Value.absent(),
    this.workHours = const Value.absent(),
    this.workIntensity = const Value.absent(),
    this.sportHours = const Value.absent(),
    this.sportIntensity = const Value.absent(),
    this.freetimeHours = const Value.absent(),
    this.freetimeIntensity = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.dailyMoveGoalCalories = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.moveGoalReminder = const Value.absent(),
    this.weightReminderDays = const Value.absent(),
    this.workoutReminder = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<UserProfileData> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? email,
    Expression<DateTime>? birthDate,
    Expression<String>? sex,
    Expression<int>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? weightUnit,
    Expression<String>? activityLevel,
    Expression<String>? profession,
    Expression<double>? workHours,
    Expression<String>? workIntensity,
    Expression<double>? sportHours,
    Expression<String>? sportIntensity,
    Expression<double>? freetimeHours,
    Expression<String>? freetimeIntensity,
    Expression<double>? sleepHours,
    Expression<int>? dailyMoveGoalCalories,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? moveGoalReminder,
    Expression<int>? weightReminderDays,
    Expression<bool>? workoutReminder,
    Expression<DateTime>? lastSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (birthDate != null) 'birth_date': birthDate,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (profession != null) 'profession': profession,
      if (workHours != null) 'work_hours': workHours,
      if (workIntensity != null) 'work_intensity': workIntensity,
      if (sportHours != null) 'sport_hours': sportHours,
      if (sportIntensity != null) 'sport_intensity': sportIntensity,
      if (freetimeHours != null) 'freetime_hours': freetimeHours,
      if (freetimeIntensity != null) 'freetime_intensity': freetimeIntensity,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (dailyMoveGoalCalories != null)
        'daily_move_goal_calories': dailyMoveGoalCalories,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (moveGoalReminder != null) 'move_goal_reminder': moveGoalReminder,
      if (weightReminderDays != null)
        'weight_reminder_days': weightReminderDays,
      if (workoutReminder != null) 'workout_reminder': workoutReminder,
      if (lastSync != null) 'last_sync': lastSync,
    });
  }

  UserProfileCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String>? email,
      Value<DateTime?>? birthDate,
      Value<String>? sex,
      Value<int?>? heightCm,
      Value<double?>? weightKg,
      Value<String>? weightUnit,
      Value<String>? activityLevel,
      Value<String>? profession,
      Value<double>? workHours,
      Value<String>? workIntensity,
      Value<double>? sportHours,
      Value<String>? sportIntensity,
      Value<double>? freetimeHours,
      Value<String>? freetimeIntensity,
      Value<double>? sleepHours,
      Value<int>? dailyMoveGoalCalories,
      Value<bool>? notificationsEnabled,
      Value<bool>? moveGoalReminder,
      Value<int>? weightReminderDays,
      Value<bool>? workoutReminder,
      Value<DateTime?>? lastSync}) {
    return UserProfileCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      weightUnit: weightUnit ?? this.weightUnit,
      activityLevel: activityLevel ?? this.activityLevel,
      profession: profession ?? this.profession,
      workHours: workHours ?? this.workHours,
      workIntensity: workIntensity ?? this.workIntensity,
      sportHours: sportHours ?? this.sportHours,
      sportIntensity: sportIntensity ?? this.sportIntensity,
      freetimeHours: freetimeHours ?? this.freetimeHours,
      freetimeIntensity: freetimeIntensity ?? this.freetimeIntensity,
      sleepHours: sleepHours ?? this.sleepHours,
      dailyMoveGoalCalories:
          dailyMoveGoalCalories ?? this.dailyMoveGoalCalories,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      moveGoalReminder: moveGoalReminder ?? this.moveGoalReminder,
      weightReminderDays: weightReminderDays ?? this.weightReminderDays,
      workoutReminder: workoutReminder ?? this.workoutReminder,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<int>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (profession.present) {
      map['profession'] = Variable<String>(profession.value);
    }
    if (workHours.present) {
      map['work_hours'] = Variable<double>(workHours.value);
    }
    if (workIntensity.present) {
      map['work_intensity'] = Variable<String>(workIntensity.value);
    }
    if (sportHours.present) {
      map['sport_hours'] = Variable<double>(sportHours.value);
    }
    if (sportIntensity.present) {
      map['sport_intensity'] = Variable<String>(sportIntensity.value);
    }
    if (freetimeHours.present) {
      map['freetime_hours'] = Variable<double>(freetimeHours.value);
    }
    if (freetimeIntensity.present) {
      map['freetime_intensity'] = Variable<String>(freetimeIntensity.value);
    }
    if (sleepHours.present) {
      map['sleep_hours'] = Variable<double>(sleepHours.value);
    }
    if (dailyMoveGoalCalories.present) {
      map['daily_move_goal_calories'] =
          Variable<int>(dailyMoveGoalCalories.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (moveGoalReminder.present) {
      map['move_goal_reminder'] = Variable<bool>(moveGoalReminder.value);
    }
    if (weightReminderDays.present) {
      map['weight_reminder_days'] = Variable<int>(weightReminderDays.value);
    }
    if (workoutReminder.present) {
      map['workout_reminder'] = Variable<bool>(workoutReminder.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('profession: $profession, ')
          ..write('workHours: $workHours, ')
          ..write('workIntensity: $workIntensity, ')
          ..write('sportHours: $sportHours, ')
          ..write('sportIntensity: $sportIntensity, ')
          ..write('freetimeHours: $freetimeHours, ')
          ..write('freetimeIntensity: $freetimeIntensity, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('dailyMoveGoalCalories: $dailyMoveGoalCalories, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('moveGoalReminder: $moveGoalReminder, ')
          ..write('weightReminderDays: $weightReminderDays, ')
          ..write('workoutReminder: $workoutReminder, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $DailyStepEntriesTable extends DailyStepEntries
    with TableInfo<$DailyStepEntriesTable, DailyStepEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStepEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stepCountMeta =
      const VerificationMeta('stepCount');
  @override
  late final GeneratedColumn<int> stepCount = GeneratedColumn<int>(
      'step_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
      'distance_meters', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _caloriesBurnedMeta =
      const VerificationMeta('caloriesBurned');
  @override
  late final GeneratedColumn<double> caloriesBurned = GeneratedColumn<double>(
      'calories_burned', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, stepCount, distanceMeters, caloriesBurned, pendingSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_step_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DailyStepEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('step_count')) {
      context.handle(_stepCountMeta,
          stepCount.isAcceptableOrUnknown(data['step_count']!, _stepCountMeta));
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    }
    if (data.containsKey('calories_burned')) {
      context.handle(
          _caloriesBurnedMeta,
          caloriesBurned.isAcceptableOrUnknown(
              data['calories_burned']!, _caloriesBurnedMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyStepEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStepEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      stepCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_count'])!,
      distanceMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_meters'])!,
      caloriesBurned: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}calories_burned'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $DailyStepEntriesTable createAlias(String alias) {
    return $DailyStepEntriesTable(attachedDatabase, alias);
  }
}

class DailyStepEntry extends DataClass implements Insertable<DailyStepEntry> {
  final int id;
  final DateTime date;
  final int stepCount;
  final double distanceMeters;
  final double caloriesBurned;
  final bool pendingSync;
  const DailyStepEntry(
      {required this.id,
      required this.date,
      required this.stepCount,
      required this.distanceMeters,
      required this.caloriesBurned,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['step_count'] = Variable<int>(stepCount);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['calories_burned'] = Variable<double>(caloriesBurned);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  DailyStepEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyStepEntriesCompanion(
      id: Value(id),
      date: Value(date),
      stepCount: Value(stepCount),
      distanceMeters: Value(distanceMeters),
      caloriesBurned: Value(caloriesBurned),
      pendingSync: Value(pendingSync),
    );
  }

  factory DailyStepEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStepEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      stepCount: serializer.fromJson<int>(json['stepCount']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      caloriesBurned: serializer.fromJson<double>(json['caloriesBurned']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'stepCount': serializer.toJson<int>(stepCount),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'caloriesBurned': serializer.toJson<double>(caloriesBurned),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  DailyStepEntry copyWith(
          {int? id,
          DateTime? date,
          int? stepCount,
          double? distanceMeters,
          double? caloriesBurned,
          bool? pendingSync}) =>
      DailyStepEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        stepCount: stepCount ?? this.stepCount,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  DailyStepEntry copyWithCompanion(DailyStepEntriesCompanion data) {
    return DailyStepEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      stepCount: data.stepCount.present ? data.stepCount.value : this.stepCount,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      caloriesBurned: data.caloriesBurned.present
          ? data.caloriesBurned.value
          : this.caloriesBurned,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStepEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('stepCount: $stepCount, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, stepCount, distanceMeters, caloriesBurned, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStepEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.stepCount == this.stepCount &&
          other.distanceMeters == this.distanceMeters &&
          other.caloriesBurned == this.caloriesBurned &&
          other.pendingSync == this.pendingSync);
}

class DailyStepEntriesCompanion extends UpdateCompanion<DailyStepEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> stepCount;
  final Value<double> distanceMeters;
  final Value<double> caloriesBurned;
  final Value<bool> pendingSync;
  const DailyStepEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.stepCount = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  DailyStepEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.stepCount = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.pendingSync = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyStepEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? stepCount,
    Expression<double>? distanceMeters,
    Expression<double>? caloriesBurned,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (stepCount != null) 'step_count': stepCount,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  DailyStepEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int>? stepCount,
      Value<double>? distanceMeters,
      Value<double>? caloriesBurned,
      Value<bool>? pendingSync}) {
    return DailyStepEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (stepCount.present) {
      map['step_count'] = Variable<int>(stepCount.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (caloriesBurned.present) {
      map['calories_burned'] = Variable<double>(caloriesBurned.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStepEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('stepCount: $stepCount, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $RunSessionsTable extends RunSessions
    with TableInfo<$RunSessionsTable, RunSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
      'distance_meters', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _caloriesBurnedMeta =
      const VerificationMeta('caloriesBurned');
  @override
  late final GeneratedColumn<double> caloriesBurned = GeneratedColumn<double>(
      'calories_burned', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _avgPaceMinPerKmMeta =
      const VerificationMeta('avgPaceMinPerKm');
  @override
  late final GeneratedColumn<double> avgPaceMinPerKm = GeneratedColumn<double>(
      'avg_pace_min_per_km', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _routePointsJsonMeta =
      const VerificationMeta('routePointsJson');
  @override
  late final GeneratedColumn<String> routePointsJson = GeneratedColumn<String>(
      'route_points_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startTime,
        endTime,
        distanceMeters,
        durationSeconds,
        caloriesBurned,
        avgPaceMinPerKm,
        routePointsJson,
        notes,
        pendingSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<RunSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('calories_burned')) {
      context.handle(
          _caloriesBurnedMeta,
          caloriesBurned.isAcceptableOrUnknown(
              data['calories_burned']!, _caloriesBurnedMeta));
    }
    if (data.containsKey('avg_pace_min_per_km')) {
      context.handle(
          _avgPaceMinPerKmMeta,
          avgPaceMinPerKm.isAcceptableOrUnknown(
              data['avg_pace_min_per_km']!, _avgPaceMinPerKmMeta));
    }
    if (data.containsKey('route_points_json')) {
      context.handle(
          _routePointsJsonMeta,
          routePointsJson.isAcceptableOrUnknown(
              data['route_points_json']!, _routePointsJsonMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      distanceMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_meters'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      caloriesBurned: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}calories_burned'])!,
      avgPaceMinPerKm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}avg_pace_min_per_km'])!,
      routePointsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}route_points_json'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $RunSessionsTable createAlias(String alias) {
    return $RunSessionsTable(attachedDatabase, alias);
  }
}

class RunSession extends DataClass implements Insertable<RunSession> {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceMeters;
  final int durationSeconds;
  final double caloriesBurned;
  final double avgPaceMinPerKm;
  final String routePointsJson;
  final String? notes;
  final bool pendingSync;
  const RunSession(
      {required this.id,
      required this.startTime,
      required this.endTime,
      required this.distanceMeters,
      required this.durationSeconds,
      required this.caloriesBurned,
      required this.avgPaceMinPerKm,
      required this.routePointsJson,
      this.notes,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['calories_burned'] = Variable<double>(caloriesBurned);
    map['avg_pace_min_per_km'] = Variable<double>(avgPaceMinPerKm);
    map['route_points_json'] = Variable<String>(routePointsJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  RunSessionsCompanion toCompanion(bool nullToAbsent) {
    return RunSessionsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: Value(endTime),
      distanceMeters: Value(distanceMeters),
      durationSeconds: Value(durationSeconds),
      caloriesBurned: Value(caloriesBurned),
      avgPaceMinPerKm: Value(avgPaceMinPerKm),
      routePointsJson: Value(routePointsJson),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      pendingSync: Value(pendingSync),
    );
  }

  factory RunSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunSession(
      id: serializer.fromJson<int>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      caloriesBurned: serializer.fromJson<double>(json['caloriesBurned']),
      avgPaceMinPerKm: serializer.fromJson<double>(json['avgPaceMinPerKm']),
      routePointsJson: serializer.fromJson<String>(json['routePointsJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'caloriesBurned': serializer.toJson<double>(caloriesBurned),
      'avgPaceMinPerKm': serializer.toJson<double>(avgPaceMinPerKm),
      'routePointsJson': serializer.toJson<String>(routePointsJson),
      'notes': serializer.toJson<String?>(notes),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  RunSession copyWith(
          {int? id,
          DateTime? startTime,
          DateTime? endTime,
          double? distanceMeters,
          int? durationSeconds,
          double? caloriesBurned,
          double? avgPaceMinPerKm,
          String? routePointsJson,
          Value<String?> notes = const Value.absent(),
          bool? pendingSync}) =>
      RunSession(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
        avgPaceMinPerKm: avgPaceMinPerKm ?? this.avgPaceMinPerKm,
        routePointsJson: routePointsJson ?? this.routePointsJson,
        notes: notes.present ? notes.value : this.notes,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  RunSession copyWithCompanion(RunSessionsCompanion data) {
    return RunSession(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      caloriesBurned: data.caloriesBurned.present
          ? data.caloriesBurned.value
          : this.caloriesBurned,
      avgPaceMinPerKm: data.avgPaceMinPerKm.present
          ? data.avgPaceMinPerKm.value
          : this.avgPaceMinPerKm,
      routePointsJson: data.routePointsJson.present
          ? data.routePointsJson.value
          : this.routePointsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunSession(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('avgPaceMinPerKm: $avgPaceMinPerKm, ')
          ..write('routePointsJson: $routePointsJson, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      startTime,
      endTime,
      distanceMeters,
      durationSeconds,
      caloriesBurned,
      avgPaceMinPerKm,
      routePointsJson,
      notes,
      pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunSession &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.distanceMeters == this.distanceMeters &&
          other.durationSeconds == this.durationSeconds &&
          other.caloriesBurned == this.caloriesBurned &&
          other.avgPaceMinPerKm == this.avgPaceMinPerKm &&
          other.routePointsJson == this.routePointsJson &&
          other.notes == this.notes &&
          other.pendingSync == this.pendingSync);
}

class RunSessionsCompanion extends UpdateCompanion<RunSession> {
  final Value<int> id;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<double> distanceMeters;
  final Value<int> durationSeconds;
  final Value<double> caloriesBurned;
  final Value<double> avgPaceMinPerKm;
  final Value<String> routePointsJson;
  final Value<String?> notes;
  final Value<bool> pendingSync;
  const RunSessionsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.avgPaceMinPerKm = const Value.absent(),
    this.routePointsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  RunSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.avgPaceMinPerKm = const Value.absent(),
    this.routePointsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.pendingSync = const Value.absent(),
  })  : startTime = Value(startTime),
        endTime = Value(endTime);
  static Insertable<RunSession> custom({
    Expression<int>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<double>? distanceMeters,
    Expression<int>? durationSeconds,
    Expression<double>? caloriesBurned,
    Expression<double>? avgPaceMinPerKm,
    Expression<String>? routePointsJson,
    Expression<String>? notes,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (avgPaceMinPerKm != null) 'avg_pace_min_per_km': avgPaceMinPerKm,
      if (routePointsJson != null) 'route_points_json': routePointsJson,
      if (notes != null) 'notes': notes,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  RunSessionsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<double>? distanceMeters,
      Value<int>? durationSeconds,
      Value<double>? caloriesBurned,
      Value<double>? avgPaceMinPerKm,
      Value<String>? routePointsJson,
      Value<String?>? notes,
      Value<bool>? pendingSync}) {
    return RunSessionsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      avgPaceMinPerKm: avgPaceMinPerKm ?? this.avgPaceMinPerKm,
      routePointsJson: routePointsJson ?? this.routePointsJson,
      notes: notes ?? this.notes,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (caloriesBurned.present) {
      map['calories_burned'] = Variable<double>(caloriesBurned.value);
    }
    if (avgPaceMinPerKm.present) {
      map['avg_pace_min_per_km'] = Variable<double>(avgPaceMinPerKm.value);
    }
    if (routePointsJson.present) {
      map['route_points_json'] = Variable<String>(routePointsJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('avgPaceMinPerKm: $avgPaceMinPerKm, ')
          ..write('routePointsJson: $routePointsJson, ')
          ..write('notes: $notes, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $WorkoutDaysTable workoutDays = $WorkoutDaysTable(this);
  late final $WorkoutSlotsTable workoutSlots = $WorkoutSlotsTable(this);
  late final $WorkoutLogsTable workoutLogs = $WorkoutLogsTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $NutritionPlansTable nutritionPlans = $NutritionPlansTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealItemsTable mealItems = $MealItemsTable(this);
  late final $NutritionDiaryTable nutritionDiary = $NutritionDiaryTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $MeasurementCategoriesTable measurementCategories =
      $MeasurementCategoriesTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $DailyStepEntriesTable dailyStepEntries =
      $DailyStepEntriesTable(this);
  late final $RunSessionsTable runSessions = $RunSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        exercises,
        routines,
        workoutDays,
        workoutSlots,
        workoutLogs,
        ingredients,
        nutritionPlans,
        meals,
        mealItems,
        nutritionDiary,
        weightEntries,
        measurementCategories,
        measurements,
        userProfile,
        dailyStepEntries,
        runSessions
      ];
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<String> description,
  Value<String> category,
  Value<String> muscles,
  Value<String> equipment,
  Value<String> imageUrl,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<String> description,
  Value<String> category,
  Value<String> muscles,
  Value<String> equipment,
  Value<String> imageUrl,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutSlotsTable, List<WorkoutSlot>>
      _workoutSlotsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutSlots,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.workoutSlots.exerciseId));

  $$WorkoutSlotsTableProcessedTableManager get workoutSlotsRefs {
    final manager = $$WorkoutSlotsTableTableManager($_db, $_db.workoutSlots)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSlotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutLogsTable, List<WorkoutLog>>
      _workoutLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutLogs,
          aliasName:
              $_aliasNameGenerator(db.exercises.id, db.workoutLogs.exerciseId));

  $$WorkoutLogsTableProcessedTableManager get workoutLogsRefs {
    final manager = $$WorkoutLogsTableTableManager($_db, $_db.workoutLogs)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get muscles => $composableBuilder(
      column: $table.muscles, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutSlotsRefs(
      Expression<bool> Function($$WorkoutSlotsTableFilterComposer f) f) {
    final $$WorkoutSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSlots,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSlotsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutLogsRefs(
      Expression<bool> Function($$WorkoutLogsTableFilterComposer f) f) {
    final $$WorkoutLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableFilterComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get muscles => $composableBuilder(
      column: $table.muscles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get muscles =>
      $composableBuilder(column: $table.muscles, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  Expression<T> workoutSlotsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSlotsTableAnnotationComposer a) f) {
    final $$WorkoutSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSlots,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutLogsRefs<T extends Object>(
      Expression<T> Function($$WorkoutLogsTableAnnotationComposer a) f) {
    final $$WorkoutLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool workoutSlotsRefs, bool workoutLogsRefs})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> muscles = const Value.absent(),
            Value<String> equipment = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            uuid: uuid,
            name: name,
            description: description,
            category: category,
            muscles: muscles,
            equipment: equipment,
            imageUrl: imageUrl,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<String> description = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> muscles = const Value.absent(),
            Value<String> equipment = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            description: description,
            category: category,
            muscles: muscles,
            equipment: equipment,
            imageUrl: imageUrl,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workoutSlotsRefs = false, workoutLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutSlotsRefs) db.workoutSlots,
                if (workoutLogsRefs) db.workoutLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSlotsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            WorkoutSlot>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutSlotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutSlotsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (workoutLogsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            WorkoutLog>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool workoutSlotsRefs, bool workoutLogsRefs})>;
typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> description,
  Value<DateTime> createdAt,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<DateTime> createdAt,
  Value<bool> pendingSync,
  Value<bool> isDeleted,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutDaysTable, List<WorkoutDay>>
      _workoutDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutDays,
          aliasName:
              $_aliasNameGenerator(db.routines.id, db.workoutDays.routineId));

  $$WorkoutDaysTableProcessedTableManager get workoutDaysRefs {
    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutDaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutDaysRefs(
      Expression<bool> Function($$WorkoutDaysTableFilterComposer f) f) {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> workoutDaysRefs<T extends Object>(
      Expression<T> Function($$WorkoutDaysTableAnnotationComposer a) f) {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool workoutDaysRefs})> {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              RoutinesCompanion(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              RoutinesCompanion.insert(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            pendingSync: pendingSync,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutinesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({workoutDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutDaysRefs) db.workoutDays],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutDaysRefs)
                    await $_getPrefetchedData<Routine, $RoutinesTable,
                            WorkoutDay>(
                        currentTable: table,
                        referencedTable:
                            $$RoutinesTableReferences._workoutDaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .workoutDaysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool workoutDaysRefs})>;
typedef $$WorkoutDaysTableCreateCompanionBuilder = WorkoutDaysCompanion
    Function({
  Value<int> id,
  required int routineId,
  Value<String> name,
  Value<String> dayOfWeek,
  Value<bool> pendingSync,
});
typedef $$WorkoutDaysTableUpdateCompanionBuilder = WorkoutDaysCompanion
    Function({
  Value<int> id,
  Value<int> routineId,
  Value<String> name,
  Value<String> dayOfWeek,
  Value<bool> pendingSync,
});

final class $$WorkoutDaysTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutDaysTable, WorkoutDay> {
  $$WorkoutDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias(
          $_aliasNameGenerator(db.workoutDays.routineId, db.routines.id));

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WorkoutSlotsTable, List<WorkoutSlot>>
      _workoutSlotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutSlots,
          aliasName:
              $_aliasNameGenerator(db.workoutDays.id, db.workoutSlots.dayId));

  $$WorkoutSlotsTableProcessedTableManager get workoutSlotsRefs {
    final manager = $$WorkoutSlotsTableTableManager($_db, $_db.workoutSlots)
        .filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSlotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutDaysTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> workoutSlotsRefs(
      Expression<bool> Function($$WorkoutSlotsTableFilterComposer f) f) {
    final $$WorkoutSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSlots,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSlotsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> workoutSlotsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSlotsTableAnnotationComposer a) f) {
    final $$WorkoutSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSlots,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutDaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, $$WorkoutDaysTableReferences),
    WorkoutDay,
    PrefetchHooks Function({bool routineId, bool workoutSlotsRefs})> {
  $$WorkoutDaysTableTableManager(_$AppDatabase db, $WorkoutDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> routineId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dayOfWeek = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              WorkoutDaysCompanion(
            id: id,
            routineId: routineId,
            name: name,
            dayOfWeek: dayOfWeek,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int routineId,
            Value<String> name = const Value.absent(),
            Value<String> dayOfWeek = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              WorkoutDaysCompanion.insert(
            id: id,
            routineId: routineId,
            name: name,
            dayOfWeek: dayOfWeek,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutDaysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {routineId = false, workoutSlotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutSlotsRefs) db.workoutSlots],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineId,
                    referencedTable:
                        $$WorkoutDaysTableReferences._routineIdTable(db),
                    referencedColumn:
                        $$WorkoutDaysTableReferences._routineIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSlotsRefs)
                    await $_getPrefetchedData<WorkoutDay, $WorkoutDaysTable,
                            WorkoutSlot>(
                        currentTable: table,
                        referencedTable: $$WorkoutDaysTableReferences
                            ._workoutSlotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutDaysTableReferences(db, table, p0)
                                .workoutSlotsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.dayId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, $$WorkoutDaysTableReferences),
    WorkoutDay,
    PrefetchHooks Function({bool routineId, bool workoutSlotsRefs})>;
typedef $$WorkoutSlotsTableCreateCompanionBuilder = WorkoutSlotsCompanion
    Function({
  Value<int> id,
  required int dayId,
  required int exerciseId,
  Value<int> order,
  Value<bool> pendingSync,
});
typedef $$WorkoutSlotsTableUpdateCompanionBuilder = WorkoutSlotsCompanion
    Function({
  Value<int> id,
  Value<int> dayId,
  Value<int> exerciseId,
  Value<int> order,
  Value<bool> pendingSync,
});

final class $$WorkoutSlotsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSlotsTable, WorkoutSlot> {
  $$WorkoutSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias(
          $_aliasNameGenerator(db.workoutSlots.dayId, db.workoutDays.id));

  $$WorkoutDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.workoutSlots.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSlotsTable> {
  $$WorkoutSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSlotsTable> {
  $$WorkoutSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableOrderingComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSlotsTable> {
  $$WorkoutSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSlotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSlotsTable,
    WorkoutSlot,
    $$WorkoutSlotsTableFilterComposer,
    $$WorkoutSlotsTableOrderingComposer,
    $$WorkoutSlotsTableAnnotationComposer,
    $$WorkoutSlotsTableCreateCompanionBuilder,
    $$WorkoutSlotsTableUpdateCompanionBuilder,
    (WorkoutSlot, $$WorkoutSlotsTableReferences),
    WorkoutSlot,
    PrefetchHooks Function({bool dayId, bool exerciseId})> {
  $$WorkoutSlotsTableTableManager(_$AppDatabase db, $WorkoutSlotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> dayId = const Value.absent(),
            Value<int> exerciseId = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              WorkoutSlotsCompanion(
            id: id,
            dayId: dayId,
            exerciseId: exerciseId,
            order: order,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int dayId,
            required int exerciseId,
            Value<int> order = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              WorkoutSlotsCompanion.insert(
            id: id,
            dayId: dayId,
            exerciseId: exerciseId,
            order: order,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSlotsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayId,
                    referencedTable:
                        $$WorkoutSlotsTableReferences._dayIdTable(db),
                    referencedColumn:
                        $$WorkoutSlotsTableReferences._dayIdTable(db).id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$WorkoutSlotsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$WorkoutSlotsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutSlotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSlotsTable,
    WorkoutSlot,
    $$WorkoutSlotsTableFilterComposer,
    $$WorkoutSlotsTableOrderingComposer,
    $$WorkoutSlotsTableAnnotationComposer,
    $$WorkoutSlotsTableCreateCompanionBuilder,
    $$WorkoutSlotsTableUpdateCompanionBuilder,
    (WorkoutSlot, $$WorkoutSlotsTableReferences),
    WorkoutSlot,
    PrefetchHooks Function({bool dayId, bool exerciseId})>;
typedef $$WorkoutLogsTableCreateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> id,
  required int exerciseId,
  Value<int?> routineId,
  Value<double> weight,
  Value<int> reps,
  Value<int> sets,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});
typedef $$WorkoutLogsTableUpdateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> id,
  Value<int> exerciseId,
  Value<int?> routineId,
  Value<double> weight,
  Value<int> reps,
  Value<int> sets,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});

final class $$WorkoutLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutLogsTable, WorkoutLog> {
  $$WorkoutLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.workoutLogs.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function({bool exerciseId})> {
  $$WorkoutLogsTableTableManager(_$AppDatabase db, $WorkoutLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> exerciseId = const Value.absent(),
            Value<int?> routineId = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> sets = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              WorkoutLogsCompanion(
            id: id,
            exerciseId: exerciseId,
            routineId: routineId,
            weight: weight,
            reps: reps,
            sets: sets,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int exerciseId,
            Value<int?> routineId = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> sets = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              WorkoutLogsCompanion.insert(
            id: id,
            exerciseId: exerciseId,
            routineId: routineId,
            weight: weight,
            reps: reps,
            sets: sets,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$WorkoutLogsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$WorkoutLogsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function({bool exerciseId})>;
typedef $$IngredientsTableCreateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<double> energy,
  Value<double> protein,
  Value<double> carbs,
  Value<double> fat,
  Value<double?> fiber,
  Value<double?> sugar,
  Value<String> imageUrl,
});
typedef $$IngredientsTableUpdateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<double> energy,
  Value<double> protein,
  Value<double> carbs,
  Value<double> fat,
  Value<double?> fiber,
  Value<double?> sugar,
  Value<String> imageUrl,
});

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealItemsTable, List<MealItem>>
      _mealItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.mealItems,
              aliasName: $_aliasNameGenerator(
                  db.ingredients.id, db.mealItems.ingredientId));

  $$MealItemsTableProcessedTableManager get mealItemsRefs {
    final manager = $$MealItemsTableTableManager($_db, $_db.mealItems)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NutritionDiaryTable, List<NutritionDiaryData>>
      _nutritionDiaryRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.nutritionDiary,
              aliasName: $_aliasNameGenerator(
                  db.ingredients.id, db.nutritionDiary.ingredientId));

  $$NutritionDiaryTableProcessedTableManager get nutritionDiaryRefs {
    final manager = $$NutritionDiaryTableTableManager($_db, $_db.nutritionDiary)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nutritionDiaryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein => $composableBuilder(
      column: $table.protein, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat => $composableBuilder(
      column: $table.fat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fiber => $composableBuilder(
      column: $table.fiber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sugar => $composableBuilder(
      column: $table.sugar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  Expression<bool> mealItemsRefs(
      Expression<bool> Function($$MealItemsTableFilterComposer f) f) {
    final $$MealItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableFilterComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> nutritionDiaryRefs(
      Expression<bool> Function($$NutritionDiaryTableFilterComposer f) f) {
    final $$NutritionDiaryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutritionDiary,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionDiaryTableFilterComposer(
              $db: $db,
              $table: $db.nutritionDiary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein => $composableBuilder(
      column: $table.protein, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat => $composableBuilder(
      column: $table.fat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fiber => $composableBuilder(
      column: $table.fiber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sugar => $composableBuilder(
      column: $table.sugar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get fiber =>
      $composableBuilder(column: $table.fiber, builder: (column) => column);

  GeneratedColumn<double> get sugar =>
      $composableBuilder(column: $table.sugar, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  Expression<T> mealItemsRefs<T extends Object>(
      Expression<T> Function($$MealItemsTableAnnotationComposer a) f) {
    final $$MealItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> nutritionDiaryRefs<T extends Object>(
      Expression<T> Function($$NutritionDiaryTableAnnotationComposer a) f) {
    final $$NutritionDiaryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutritionDiary,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionDiaryTableAnnotationComposer(
              $db: $db,
              $table: $db.nutritionDiary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function({bool mealItemsRefs, bool nutritionDiaryRefs})> {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> energy = const Value.absent(),
            Value<double> protein = const Value.absent(),
            Value<double> carbs = const Value.absent(),
            Value<double> fat = const Value.absent(),
            Value<double?> fiber = const Value.absent(),
            Value<double?> sugar = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
          }) =>
              IngredientsCompanion(
            id: id,
            name: name,
            energy: energy,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            imageUrl: imageUrl,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> energy = const Value.absent(),
            Value<double> protein = const Value.absent(),
            Value<double> carbs = const Value.absent(),
            Value<double> fat = const Value.absent(),
            Value<double?> fiber = const Value.absent(),
            Value<double?> sugar = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
          }) =>
              IngredientsCompanion.insert(
            id: id,
            name: name,
            energy: energy,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            imageUrl: imageUrl,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {mealItemsRefs = false, nutritionDiaryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (mealItemsRefs) db.mealItems,
                if (nutritionDiaryRefs) db.nutritionDiary
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealItemsRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable,
                            MealItem>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._mealItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .mealItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (nutritionDiaryRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable, NutritionDiaryData>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._nutritionDiaryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .nutritionDiaryRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function({bool mealItemsRefs, bool nutritionDiaryRefs})>;
typedef $$NutritionPlansTableCreateCompanionBuilder = NutritionPlansCompanion
    Function({
  Value<int> id,
  Value<String> description,
  Value<double?> goalEnergy,
  Value<double?> goalProtein,
  Value<double?> goalCarbs,
  Value<double?> goalFat,
  Value<bool> pendingSync,
});
typedef $$NutritionPlansTableUpdateCompanionBuilder = NutritionPlansCompanion
    Function({
  Value<int> id,
  Value<String> description,
  Value<double?> goalEnergy,
  Value<double?> goalProtein,
  Value<double?> goalCarbs,
  Value<double?> goalFat,
  Value<bool> pendingSync,
});

final class $$NutritionPlansTableReferences
    extends BaseReferences<_$AppDatabase, $NutritionPlansTable, NutritionPlan> {
  $$NutritionPlansTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealsTable, List<Meal>> _mealsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.meals,
          aliasName:
              $_aliasNameGenerator(db.nutritionPlans.id, db.meals.planId));

  $$MealsTableProcessedTableManager get mealsRefs {
    final manager = $$MealsTableTableManager($_db, $_db.meals)
        .filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NutritionPlansTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionPlansTable> {
  $$NutritionPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get goalEnergy => $composableBuilder(
      column: $table.goalEnergy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get goalProtein => $composableBuilder(
      column: $table.goalProtein, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get goalCarbs => $composableBuilder(
      column: $table.goalCarbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get goalFat => $composableBuilder(
      column: $table.goalFat, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  Expression<bool> mealsRefs(
      Expression<bool> Function($$MealsTableFilterComposer f) f) {
    final $$MealsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableFilterComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutritionPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionPlansTable> {
  $$NutritionPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get goalEnergy => $composableBuilder(
      column: $table.goalEnergy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get goalProtein => $composableBuilder(
      column: $table.goalProtein, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get goalCarbs => $composableBuilder(
      column: $table.goalCarbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get goalFat => $composableBuilder(
      column: $table.goalFat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));
}

class $$NutritionPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionPlansTable> {
  $$NutritionPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get goalEnergy => $composableBuilder(
      column: $table.goalEnergy, builder: (column) => column);

  GeneratedColumn<double> get goalProtein => $composableBuilder(
      column: $table.goalProtein, builder: (column) => column);

  GeneratedColumn<double> get goalCarbs =>
      $composableBuilder(column: $table.goalCarbs, builder: (column) => column);

  GeneratedColumn<double> get goalFat =>
      $composableBuilder(column: $table.goalFat, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  Expression<T> mealsRefs<T extends Object>(
      Expression<T> Function($$MealsTableAnnotationComposer a) f) {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableAnnotationComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutritionPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionPlansTable,
    NutritionPlan,
    $$NutritionPlansTableFilterComposer,
    $$NutritionPlansTableOrderingComposer,
    $$NutritionPlansTableAnnotationComposer,
    $$NutritionPlansTableCreateCompanionBuilder,
    $$NutritionPlansTableUpdateCompanionBuilder,
    (NutritionPlan, $$NutritionPlansTableReferences),
    NutritionPlan,
    PrefetchHooks Function({bool mealsRefs})> {
  $$NutritionPlansTableTableManager(
      _$AppDatabase db, $NutritionPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double?> goalEnergy = const Value.absent(),
            Value<double?> goalProtein = const Value.absent(),
            Value<double?> goalCarbs = const Value.absent(),
            Value<double?> goalFat = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              NutritionPlansCompanion(
            id: id,
            description: description,
            goalEnergy: goalEnergy,
            goalProtein: goalProtein,
            goalCarbs: goalCarbs,
            goalFat: goalFat,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double?> goalEnergy = const Value.absent(),
            Value<double?> goalProtein = const Value.absent(),
            Value<double?> goalCarbs = const Value.absent(),
            Value<double?> goalFat = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              NutritionPlansCompanion.insert(
            id: id,
            description: description,
            goalEnergy: goalEnergy,
            goalProtein: goalProtein,
            goalCarbs: goalCarbs,
            goalFat: goalFat,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NutritionPlansTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({mealsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealsRefs) db.meals],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealsRefs)
                    await $_getPrefetchedData<NutritionPlan,
                            $NutritionPlansTable, Meal>(
                        currentTable: table,
                        referencedTable:
                            $$NutritionPlansTableReferences._mealsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NutritionPlansTableReferences(db, table, p0)
                                .mealsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.planId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NutritionPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionPlansTable,
    NutritionPlan,
    $$NutritionPlansTableFilterComposer,
    $$NutritionPlansTableOrderingComposer,
    $$NutritionPlansTableAnnotationComposer,
    $$NutritionPlansTableCreateCompanionBuilder,
    $$NutritionPlansTableUpdateCompanionBuilder,
    (NutritionPlan, $$NutritionPlansTableReferences),
    NutritionPlan,
    PrefetchHooks Function({bool mealsRefs})>;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  required int planId,
  Value<String> name,
  Value<String?> time,
  Value<bool> pendingSync,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<String> name,
  Value<String?> time,
  Value<bool> pendingSync,
});

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NutritionPlansTable _planIdTable(_$AppDatabase db) => db
      .nutritionPlans
      .createAlias($_aliasNameGenerator(db.meals.planId, db.nutritionPlans.id));

  $$NutritionPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$NutritionPlansTableTableManager($_db, $_db.nutritionPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$MealItemsTable, List<MealItem>>
      _mealItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.mealItems,
          aliasName: $_aliasNameGenerator(db.meals.id, db.mealItems.mealId));

  $$MealItemsTableProcessedTableManager get mealItemsRefs {
    final manager = $$MealItemsTableTableManager($_db, $_db.mealItems)
        .filter((f) => f.mealId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  $$NutritionPlansTableFilterComposer get planId {
    final $$NutritionPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.nutritionPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionPlansTableFilterComposer(
              $db: $db,
              $table: $db.nutritionPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> mealItemsRefs(
      Expression<bool> Function($$MealItemsTableFilterComposer f) f) {
    final $$MealItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableFilterComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  $$NutritionPlansTableOrderingComposer get planId {
    final $$NutritionPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.nutritionPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionPlansTableOrderingComposer(
              $db: $db,
              $table: $db.nutritionPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  $$NutritionPlansTableAnnotationComposer get planId {
    final $$NutritionPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.nutritionPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.nutritionPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> mealItemsRefs<T extends Object>(
      Expression<T> Function($$MealItemsTableAnnotationComposer a) f) {
    final $$MealItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool planId, bool mealItemsRefs})> {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> planId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> time = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              MealsCompanion(
            id: id,
            planId: planId,
            name: name,
            time: time,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int planId,
            Value<String> name = const Value.absent(),
            Value<String?> time = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              MealsCompanion.insert(
            id: id,
            planId: planId,
            name: name,
            time: time,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MealsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({planId = false, mealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealItemsRefs) db.mealItems],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (planId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.planId,
                    referencedTable: $$MealsTableReferences._planIdTable(db),
                    referencedColumn:
                        $$MealsTableReferences._planIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealItemsRefs)
                    await $_getPrefetchedData<Meal, $MealsTable, MealItem>(
                        currentTable: table,
                        referencedTable:
                            $$MealsTableReferences._mealItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MealsTableReferences(db, table, p0).mealItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.mealId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MealsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool planId, bool mealItemsRefs})>;
typedef $$MealItemsTableCreateCompanionBuilder = MealItemsCompanion Function({
  Value<int> id,
  required int mealId,
  required int ingredientId,
  Value<double> amount,
  Value<bool> pendingSync,
  Value<int?> serverId,
});
typedef $$MealItemsTableUpdateCompanionBuilder = MealItemsCompanion Function({
  Value<int> id,
  Value<int> mealId,
  Value<int> ingredientId,
  Value<double> amount,
  Value<bool> pendingSync,
  Value<int?> serverId,
});

final class $$MealItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MealItemsTable, MealItem> {
  $$MealItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealsTable _mealIdTable(_$AppDatabase db) => db.meals
      .createAlias($_aliasNameGenerator(db.mealItems.mealId, db.meals.id));

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<int>('meal_id')!;

    final manager = $$MealsTableTableManager($_db, $_db.meals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias(
          $_aliasNameGenerator(db.mealItems.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MealItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableFilterComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableOrderingComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableAnnotationComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealItemsTable,
    MealItem,
    $$MealItemsTableFilterComposer,
    $$MealItemsTableOrderingComposer,
    $$MealItemsTableAnnotationComposer,
    $$MealItemsTableCreateCompanionBuilder,
    $$MealItemsTableUpdateCompanionBuilder,
    (MealItem, $$MealItemsTableReferences),
    MealItem,
    PrefetchHooks Function({bool mealId, bool ingredientId})> {
  $$MealItemsTableTableManager(_$AppDatabase db, $MealItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> mealId = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              MealItemsCompanion(
            id: id,
            mealId: mealId,
            ingredientId: ingredientId,
            amount: amount,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int mealId,
            required int ingredientId,
            Value<double> amount = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              MealItemsCompanion.insert(
            id: id,
            mealId: mealId,
            ingredientId: ingredientId,
            amount: amount,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MealItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({mealId = false, ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (mealId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mealId,
                    referencedTable:
                        $$MealItemsTableReferences._mealIdTable(db),
                    referencedColumn:
                        $$MealItemsTableReferences._mealIdTable(db).id,
                  ) as T;
                }
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable:
                        $$MealItemsTableReferences._ingredientIdTable(db),
                    referencedColumn:
                        $$MealItemsTableReferences._ingredientIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MealItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealItemsTable,
    MealItem,
    $$MealItemsTableFilterComposer,
    $$MealItemsTableOrderingComposer,
    $$MealItemsTableAnnotationComposer,
    $$MealItemsTableCreateCompanionBuilder,
    $$MealItemsTableUpdateCompanionBuilder,
    (MealItem, $$MealItemsTableReferences),
    MealItem,
    PrefetchHooks Function({bool mealId, bool ingredientId})>;
typedef $$NutritionDiaryTableCreateCompanionBuilder = NutritionDiaryCompanion
    Function({
  Value<int> id,
  Value<int?> planId,
  required int ingredientId,
  Value<double> amount,
  Value<DateTime> date,
  Value<bool> pendingSync,
  Value<int?> serverId,
});
typedef $$NutritionDiaryTableUpdateCompanionBuilder = NutritionDiaryCompanion
    Function({
  Value<int> id,
  Value<int?> planId,
  Value<int> ingredientId,
  Value<double> amount,
  Value<DateTime> date,
  Value<bool> pendingSync,
  Value<int?> serverId,
});

final class $$NutritionDiaryTableReferences extends BaseReferences<
    _$AppDatabase, $NutritionDiaryTable, NutritionDiaryData> {
  $$NutritionDiaryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias($_aliasNameGenerator(
          db.nutritionDiary.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NutritionDiaryTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionDiaryTable> {
  $$NutritionDiaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutritionDiaryTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionDiaryTable> {
  $$NutritionDiaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutritionDiaryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionDiaryTable> {
  $$NutritionDiaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutritionDiaryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionDiaryTable,
    NutritionDiaryData,
    $$NutritionDiaryTableFilterComposer,
    $$NutritionDiaryTableOrderingComposer,
    $$NutritionDiaryTableAnnotationComposer,
    $$NutritionDiaryTableCreateCompanionBuilder,
    $$NutritionDiaryTableUpdateCompanionBuilder,
    (NutritionDiaryData, $$NutritionDiaryTableReferences),
    NutritionDiaryData,
    PrefetchHooks Function({bool ingredientId})> {
  $$NutritionDiaryTableTableManager(
      _$AppDatabase db, $NutritionDiaryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionDiaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionDiaryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionDiaryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              NutritionDiaryCompanion(
            id: id,
            planId: planId,
            ingredientId: ingredientId,
            amount: amount,
            date: date,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            required int ingredientId,
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              NutritionDiaryCompanion.insert(
            id: id,
            planId: planId,
            ingredientId: ingredientId,
            amount: amount,
            date: date,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NutritionDiaryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable:
                        $$NutritionDiaryTableReferences._ingredientIdTable(db),
                    referencedColumn: $$NutritionDiaryTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NutritionDiaryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionDiaryTable,
    NutritionDiaryData,
    $$NutritionDiaryTableFilterComposer,
    $$NutritionDiaryTableOrderingComposer,
    $$NutritionDiaryTableAnnotationComposer,
    $$NutritionDiaryTableCreateCompanionBuilder,
    $$NutritionDiaryTableUpdateCompanionBuilder,
    (NutritionDiaryData, $$NutritionDiaryTableReferences),
    NutritionDiaryData,
    PrefetchHooks Function({bool ingredientId})>;
typedef $$WeightEntriesTableCreateCompanionBuilder = WeightEntriesCompanion
    Function({
  Value<int> id,
  required double weight,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});
typedef $$WeightEntriesTableUpdateCompanionBuilder = WeightEntriesCompanion
    Function({
  Value<int> id,
  Value<double> weight,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);
}

class $$WeightEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeightEntriesTable,
    WeightEntry,
    $$WeightEntriesTableFilterComposer,
    $$WeightEntriesTableOrderingComposer,
    $$WeightEntriesTableAnnotationComposer,
    $$WeightEntriesTableCreateCompanionBuilder,
    $$WeightEntriesTableUpdateCompanionBuilder,
    (
      WeightEntry,
      BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>
    ),
    WeightEntry,
    PrefetchHooks Function()> {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              WeightEntriesCompanion(
            id: id,
            weight: weight,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double weight,
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              WeightEntriesCompanion.insert(
            id: id,
            weight: weight,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeightEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeightEntriesTable,
    WeightEntry,
    $$WeightEntriesTableFilterComposer,
    $$WeightEntriesTableOrderingComposer,
    $$WeightEntriesTableAnnotationComposer,
    $$WeightEntriesTableCreateCompanionBuilder,
    $$WeightEntriesTableUpdateCompanionBuilder,
    (
      WeightEntry,
      BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>
    ),
    WeightEntry,
    PrefetchHooks Function()>;
typedef $$MeasurementCategoriesTableCreateCompanionBuilder
    = MeasurementCategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> unit,
  Value<bool> pendingSync,
});
typedef $$MeasurementCategoriesTableUpdateCompanionBuilder
    = MeasurementCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> unit,
  Value<bool> pendingSync,
});

final class $$MeasurementCategoriesTableReferences extends BaseReferences<
    _$AppDatabase, $MeasurementCategoriesTable, MeasurementCategory> {
  $$MeasurementCategoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MeasurementsTable, List<Measurement>>
      _measurementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.measurements,
              aliasName: $_aliasNameGenerator(
                  db.measurementCategories.id, db.measurements.categoryId));

  $$MeasurementsTableProcessedTableManager get measurementsRefs {
    final manager = $$MeasurementsTableTableManager($_db, $_db.measurements)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MeasurementCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementCategoriesTable> {
  $$MeasurementCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  Expression<bool> measurementsRefs(
      Expression<bool> Function($$MeasurementsTableFilterComposer f) f) {
    final $$MeasurementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.measurements,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeasurementsTableFilterComposer(
              $db: $db,
              $table: $db.measurements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeasurementCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementCategoriesTable> {
  $$MeasurementCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));
}

class $$MeasurementCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementCategoriesTable> {
  $$MeasurementCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  Expression<T> measurementsRefs<T extends Object>(
      Expression<T> Function($$MeasurementsTableAnnotationComposer a) f) {
    final $$MeasurementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.measurements,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeasurementsTableAnnotationComposer(
              $db: $db,
              $table: $db.measurements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeasurementCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementCategoriesTable,
    MeasurementCategory,
    $$MeasurementCategoriesTableFilterComposer,
    $$MeasurementCategoriesTableOrderingComposer,
    $$MeasurementCategoriesTableAnnotationComposer,
    $$MeasurementCategoriesTableCreateCompanionBuilder,
    $$MeasurementCategoriesTableUpdateCompanionBuilder,
    (MeasurementCategory, $$MeasurementCategoriesTableReferences),
    MeasurementCategory,
    PrefetchHooks Function({bool measurementsRefs})> {
  $$MeasurementCategoriesTableTableManager(
      _$AppDatabase db, $MeasurementCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementCategoriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementCategoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              MeasurementCategoriesCompanion(
            id: id,
            name: name,
            unit: unit,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> unit = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              MeasurementCategoriesCompanion.insert(
            id: id,
            name: name,
            unit: unit,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeasurementCategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({measurementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (measurementsRefs) db.measurements],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (measurementsRefs)
                    await $_getPrefetchedData<MeasurementCategory,
                            $MeasurementCategoriesTable, Measurement>(
                        currentTable: table,
                        referencedTable: $$MeasurementCategoriesTableReferences
                            ._measurementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeasurementCategoriesTableReferences(
                                    db, table, p0)
                                .measurementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MeasurementCategoriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $MeasurementCategoriesTable,
        MeasurementCategory,
        $$MeasurementCategoriesTableFilterComposer,
        $$MeasurementCategoriesTableOrderingComposer,
        $$MeasurementCategoriesTableAnnotationComposer,
        $$MeasurementCategoriesTableCreateCompanionBuilder,
        $$MeasurementCategoriesTableUpdateCompanionBuilder,
        (MeasurementCategory, $$MeasurementCategoriesTableReferences),
        MeasurementCategory,
        PrefetchHooks Function({bool measurementsRefs})>;
typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  required int categoryId,
  required double value,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  Value<int> categoryId,
  Value<double> value,
  Value<DateTime> date,
  Value<String> notes,
  Value<bool> pendingSync,
  Value<int?> serverId,
});

final class $$MeasurementsTableReferences
    extends BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement> {
  $$MeasurementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeasurementCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.measurementCategories.createAlias($_aliasNameGenerator(
          db.measurements.categoryId, db.measurementCategories.id));

  $$MeasurementCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$MeasurementCategoriesTableTableManager(
            $_db, $_db.measurementCategories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  $$MeasurementCategoriesTableFilterComposer get categoryId {
    final $$MeasurementCategoriesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.measurementCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MeasurementCategoriesTableFilterComposer(
                  $db: $db,
                  $table: $db.measurementCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  $$MeasurementCategoriesTableOrderingComposer get categoryId {
    final $$MeasurementCategoriesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.measurementCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MeasurementCategoriesTableOrderingComposer(
                  $db: $db,
                  $table: $db.measurementCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  $$MeasurementCategoriesTableAnnotationComposer get categoryId {
    final $$MeasurementCategoriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.measurementCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MeasurementCategoriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.measurementCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (Measurement, $$MeasurementsTableReferences),
    Measurement,
    PrefetchHooks Function({bool categoryId})> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            id: id,
            categoryId: categoryId,
            value: value,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoryId,
            required double value,
            Value<DateTime> date = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            id: id,
            categoryId: categoryId,
            value: value,
            date: date,
            notes: notes,
            pendingSync: pendingSync,
            serverId: serverId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeasurementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$MeasurementsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$MeasurementsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (Measurement, $$MeasurementsTableReferences),
    Measurement,
    PrefetchHooks Function({bool categoryId})>;
typedef $$UserProfileTableCreateCompanionBuilder = UserProfileCompanion
    Function({
  Value<int> id,
  Value<String> username,
  Value<String> email,
  Value<DateTime?> birthDate,
  Value<String> sex,
  Value<int?> heightCm,
  Value<double?> weightKg,
  Value<String> weightUnit,
  Value<String> activityLevel,
  Value<String> profession,
  Value<double> workHours,
  Value<String> workIntensity,
  Value<double> sportHours,
  Value<String> sportIntensity,
  Value<double> freetimeHours,
  Value<String> freetimeIntensity,
  Value<double> sleepHours,
  Value<int> dailyMoveGoalCalories,
  Value<bool> notificationsEnabled,
  Value<bool> moveGoalReminder,
  Value<int> weightReminderDays,
  Value<bool> workoutReminder,
  Value<DateTime?> lastSync,
});
typedef $$UserProfileTableUpdateCompanionBuilder = UserProfileCompanion
    Function({
  Value<int> id,
  Value<String> username,
  Value<String> email,
  Value<DateTime?> birthDate,
  Value<String> sex,
  Value<int?> heightCm,
  Value<double?> weightKg,
  Value<String> weightUnit,
  Value<String> activityLevel,
  Value<String> profession,
  Value<double> workHours,
  Value<String> workIntensity,
  Value<double> sportHours,
  Value<String> sportIntensity,
  Value<double> freetimeHours,
  Value<String> freetimeIntensity,
  Value<double> sleepHours,
  Value<int> dailyMoveGoalCalories,
  Value<bool> notificationsEnabled,
  Value<bool> moveGoalReminder,
  Value<int> weightReminderDays,
  Value<bool> workoutReminder,
  Value<DateTime?> lastSync,
});

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weightUnit => $composableBuilder(
      column: $table.weightUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profession => $composableBuilder(
      column: $table.profession, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get workHours => $composableBuilder(
      column: $table.workHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workIntensity => $composableBuilder(
      column: $table.workIntensity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sportHours => $composableBuilder(
      column: $table.sportHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sportIntensity => $composableBuilder(
      column: $table.sportIntensity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get freetimeHours => $composableBuilder(
      column: $table.freetimeHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get freetimeIntensity => $composableBuilder(
      column: $table.freetimeIntensity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyMoveGoalCalories => $composableBuilder(
      column: $table.dailyMoveGoalCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get moveGoalReminder => $composableBuilder(
      column: $table.moveGoalReminder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weightReminderDays => $composableBuilder(
      column: $table.weightReminderDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get workoutReminder => $composableBuilder(
      column: $table.workoutReminder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weightUnit => $composableBuilder(
      column: $table.weightUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profession => $composableBuilder(
      column: $table.profession, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get workHours => $composableBuilder(
      column: $table.workHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workIntensity => $composableBuilder(
      column: $table.workIntensity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sportHours => $composableBuilder(
      column: $table.sportHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sportIntensity => $composableBuilder(
      column: $table.sportIntensity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get freetimeHours => $composableBuilder(
      column: $table.freetimeHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get freetimeIntensity => $composableBuilder(
      column: $table.freetimeIntensity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyMoveGoalCalories => $composableBuilder(
      column: $table.dailyMoveGoalCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get moveGoalReminder => $composableBuilder(
      column: $table.moveGoalReminder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weightReminderDays => $composableBuilder(
      column: $table.weightReminderDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get workoutReminder => $composableBuilder(
      column: $table.workoutReminder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get weightUnit => $composableBuilder(
      column: $table.weightUnit, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => column);

  GeneratedColumn<String> get profession => $composableBuilder(
      column: $table.profession, builder: (column) => column);

  GeneratedColumn<double> get workHours =>
      $composableBuilder(column: $table.workHours, builder: (column) => column);

  GeneratedColumn<String> get workIntensity => $composableBuilder(
      column: $table.workIntensity, builder: (column) => column);

  GeneratedColumn<double> get sportHours => $composableBuilder(
      column: $table.sportHours, builder: (column) => column);

  GeneratedColumn<String> get sportIntensity => $composableBuilder(
      column: $table.sportIntensity, builder: (column) => column);

  GeneratedColumn<double> get freetimeHours => $composableBuilder(
      column: $table.freetimeHours, builder: (column) => column);

  GeneratedColumn<String> get freetimeIntensity => $composableBuilder(
      column: $table.freetimeIntensity, builder: (column) => column);

  GeneratedColumn<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => column);

  GeneratedColumn<int> get dailyMoveGoalCalories => $composableBuilder(
      column: $table.dailyMoveGoalCalories, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<bool> get moveGoalReminder => $composableBuilder(
      column: $table.moveGoalReminder, builder: (column) => column);

  GeneratedColumn<int> get weightReminderDays => $composableBuilder(
      column: $table.weightReminderDays, builder: (column) => column);

  GeneratedColumn<bool> get workoutReminder => $composableBuilder(
      column: $table.workoutReminder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$UserProfileTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfileTable,
    UserProfileData,
    $$UserProfileTableFilterComposer,
    $$UserProfileTableOrderingComposer,
    $$UserProfileTableAnnotationComposer,
    $$UserProfileTableCreateCompanionBuilder,
    $$UserProfileTableUpdateCompanionBuilder,
    (
      UserProfileData,
      BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>
    ),
    UserProfileData,
    PrefetchHooks Function()> {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<DateTime?> birthDate = const Value.absent(),
            Value<String> sex = const Value.absent(),
            Value<int?> heightCm = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<String> weightUnit = const Value.absent(),
            Value<String> activityLevel = const Value.absent(),
            Value<String> profession = const Value.absent(),
            Value<double> workHours = const Value.absent(),
            Value<String> workIntensity = const Value.absent(),
            Value<double> sportHours = const Value.absent(),
            Value<String> sportIntensity = const Value.absent(),
            Value<double> freetimeHours = const Value.absent(),
            Value<String> freetimeIntensity = const Value.absent(),
            Value<double> sleepHours = const Value.absent(),
            Value<int> dailyMoveGoalCalories = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<bool> moveGoalReminder = const Value.absent(),
            Value<int> weightReminderDays = const Value.absent(),
            Value<bool> workoutReminder = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
          }) =>
              UserProfileCompanion(
            id: id,
            username: username,
            email: email,
            birthDate: birthDate,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            weightUnit: weightUnit,
            activityLevel: activityLevel,
            profession: profession,
            workHours: workHours,
            workIntensity: workIntensity,
            sportHours: sportHours,
            sportIntensity: sportIntensity,
            freetimeHours: freetimeHours,
            freetimeIntensity: freetimeIntensity,
            sleepHours: sleepHours,
            dailyMoveGoalCalories: dailyMoveGoalCalories,
            notificationsEnabled: notificationsEnabled,
            moveGoalReminder: moveGoalReminder,
            weightReminderDays: weightReminderDays,
            workoutReminder: workoutReminder,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<DateTime?> birthDate = const Value.absent(),
            Value<String> sex = const Value.absent(),
            Value<int?> heightCm = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<String> weightUnit = const Value.absent(),
            Value<String> activityLevel = const Value.absent(),
            Value<String> profession = const Value.absent(),
            Value<double> workHours = const Value.absent(),
            Value<String> workIntensity = const Value.absent(),
            Value<double> sportHours = const Value.absent(),
            Value<String> sportIntensity = const Value.absent(),
            Value<double> freetimeHours = const Value.absent(),
            Value<String> freetimeIntensity = const Value.absent(),
            Value<double> sleepHours = const Value.absent(),
            Value<int> dailyMoveGoalCalories = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<bool> moveGoalReminder = const Value.absent(),
            Value<int> weightReminderDays = const Value.absent(),
            Value<bool> workoutReminder = const Value.absent(),
            Value<DateTime?> lastSync = const Value.absent(),
          }) =>
              UserProfileCompanion.insert(
            id: id,
            username: username,
            email: email,
            birthDate: birthDate,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            weightUnit: weightUnit,
            activityLevel: activityLevel,
            profession: profession,
            workHours: workHours,
            workIntensity: workIntensity,
            sportHours: sportHours,
            sportIntensity: sportIntensity,
            freetimeHours: freetimeHours,
            freetimeIntensity: freetimeIntensity,
            sleepHours: sleepHours,
            dailyMoveGoalCalories: dailyMoveGoalCalories,
            notificationsEnabled: notificationsEnabled,
            moveGoalReminder: moveGoalReminder,
            weightReminderDays: weightReminderDays,
            workoutReminder: workoutReminder,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfileTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfileTable,
    UserProfileData,
    $$UserProfileTableFilterComposer,
    $$UserProfileTableOrderingComposer,
    $$UserProfileTableAnnotationComposer,
    $$UserProfileTableCreateCompanionBuilder,
    $$UserProfileTableUpdateCompanionBuilder,
    (
      UserProfileData,
      BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>
    ),
    UserProfileData,
    PrefetchHooks Function()>;
typedef $$DailyStepEntriesTableCreateCompanionBuilder
    = DailyStepEntriesCompanion Function({
  Value<int> id,
  required DateTime date,
  Value<int> stepCount,
  Value<double> distanceMeters,
  Value<double> caloriesBurned,
  Value<bool> pendingSync,
});
typedef $$DailyStepEntriesTableUpdateCompanionBuilder
    = DailyStepEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int> stepCount,
  Value<double> distanceMeters,
  Value<double> caloriesBurned,
  Value<bool> pendingSync,
});

class $$DailyStepEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStepEntriesTable> {
  $$DailyStepEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepCount => $composableBuilder(
      column: $table.stepCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));
}

class $$DailyStepEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStepEntriesTable> {
  $$DailyStepEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepCount => $composableBuilder(
      column: $table.stepCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));
}

class $$DailyStepEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStepEntriesTable> {
  $$DailyStepEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get stepCount =>
      $composableBuilder(column: $table.stepCount, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);
}

class $$DailyStepEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyStepEntriesTable,
    DailyStepEntry,
    $$DailyStepEntriesTableFilterComposer,
    $$DailyStepEntriesTableOrderingComposer,
    $$DailyStepEntriesTableAnnotationComposer,
    $$DailyStepEntriesTableCreateCompanionBuilder,
    $$DailyStepEntriesTableUpdateCompanionBuilder,
    (
      DailyStepEntry,
      BaseReferences<_$AppDatabase, $DailyStepEntriesTable, DailyStepEntry>
    ),
    DailyStepEntry,
    PrefetchHooks Function()> {
  $$DailyStepEntriesTableTableManager(
      _$AppDatabase db, $DailyStepEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStepEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStepEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStepEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> stepCount = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<double> caloriesBurned = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              DailyStepEntriesCompanion(
            id: id,
            date: date,
            stepCount: stepCount,
            distanceMeters: distanceMeters,
            caloriesBurned: caloriesBurned,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<int> stepCount = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<double> caloriesBurned = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              DailyStepEntriesCompanion.insert(
            id: id,
            date: date,
            stepCount: stepCount,
            distanceMeters: distanceMeters,
            caloriesBurned: caloriesBurned,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyStepEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyStepEntriesTable,
    DailyStepEntry,
    $$DailyStepEntriesTableFilterComposer,
    $$DailyStepEntriesTableOrderingComposer,
    $$DailyStepEntriesTableAnnotationComposer,
    $$DailyStepEntriesTableCreateCompanionBuilder,
    $$DailyStepEntriesTableUpdateCompanionBuilder,
    (
      DailyStepEntry,
      BaseReferences<_$AppDatabase, $DailyStepEntriesTable, DailyStepEntry>
    ),
    DailyStepEntry,
    PrefetchHooks Function()>;
typedef $$RunSessionsTableCreateCompanionBuilder = RunSessionsCompanion
    Function({
  Value<int> id,
  required DateTime startTime,
  required DateTime endTime,
  Value<double> distanceMeters,
  Value<int> durationSeconds,
  Value<double> caloriesBurned,
  Value<double> avgPaceMinPerKm,
  Value<String> routePointsJson,
  Value<String?> notes,
  Value<bool> pendingSync,
});
typedef $$RunSessionsTableUpdateCompanionBuilder = RunSessionsCompanion
    Function({
  Value<int> id,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<double> distanceMeters,
  Value<int> durationSeconds,
  Value<double> caloriesBurned,
  Value<double> avgPaceMinPerKm,
  Value<String> routePointsJson,
  Value<String?> notes,
  Value<bool> pendingSync,
});

class $$RunSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $RunSessionsTable> {
  $$RunSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgPaceMinPerKm => $composableBuilder(
      column: $table.avgPaceMinPerKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routePointsJson => $composableBuilder(
      column: $table.routePointsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));
}

class $$RunSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunSessionsTable> {
  $$RunSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgPaceMinPerKm => $composableBuilder(
      column: $table.avgPaceMinPerKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routePointsJson => $composableBuilder(
      column: $table.routePointsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));
}

class $$RunSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunSessionsTable> {
  $$RunSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned, builder: (column) => column);

  GeneratedColumn<double> get avgPaceMinPerKm => $composableBuilder(
      column: $table.avgPaceMinPerKm, builder: (column) => column);

  GeneratedColumn<String> get routePointsJson => $composableBuilder(
      column: $table.routePointsJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);
}

class $$RunSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RunSessionsTable,
    RunSession,
    $$RunSessionsTableFilterComposer,
    $$RunSessionsTableOrderingComposer,
    $$RunSessionsTableAnnotationComposer,
    $$RunSessionsTableCreateCompanionBuilder,
    $$RunSessionsTableUpdateCompanionBuilder,
    (RunSession, BaseReferences<_$AppDatabase, $RunSessionsTable, RunSession>),
    RunSession,
    PrefetchHooks Function()> {
  $$RunSessionsTableTableManager(_$AppDatabase db, $RunSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> caloriesBurned = const Value.absent(),
            Value<double> avgPaceMinPerKm = const Value.absent(),
            Value<String> routePointsJson = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              RunSessionsCompanion(
            id: id,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            caloriesBurned: caloriesBurned,
            avgPaceMinPerKm: avgPaceMinPerKm,
            routePointsJson: routePointsJson,
            notes: notes,
            pendingSync: pendingSync,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            Value<double> distanceMeters = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> caloriesBurned = const Value.absent(),
            Value<double> avgPaceMinPerKm = const Value.absent(),
            Value<String> routePointsJson = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
          }) =>
              RunSessionsCompanion.insert(
            id: id,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            caloriesBurned: caloriesBurned,
            avgPaceMinPerKm: avgPaceMinPerKm,
            routePointsJson: routePointsJson,
            notes: notes,
            pendingSync: pendingSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RunSessionsTable,
    RunSession,
    $$RunSessionsTableFilterComposer,
    $$RunSessionsTableOrderingComposer,
    $$RunSessionsTableAnnotationComposer,
    $$RunSessionsTableCreateCompanionBuilder,
    $$RunSessionsTableUpdateCompanionBuilder,
    (RunSession, BaseReferences<_$AppDatabase, $RunSessionsTable, RunSession>),
    RunSession,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db, _db.workoutDays);
  $$WorkoutSlotsTableTableManager get workoutSlots =>
      $$WorkoutSlotsTableTableManager(_db, _db.workoutSlots);
  $$WorkoutLogsTableTableManager get workoutLogs =>
      $$WorkoutLogsTableTableManager(_db, _db.workoutLogs);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$NutritionPlansTableTableManager get nutritionPlans =>
      $$NutritionPlansTableTableManager(_db, _db.nutritionPlans);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealItemsTableTableManager get mealItems =>
      $$MealItemsTableTableManager(_db, _db.mealItems);
  $$NutritionDiaryTableTableManager get nutritionDiary =>
      $$NutritionDiaryTableTableManager(_db, _db.nutritionDiary);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$MeasurementCategoriesTableTableManager get measurementCategories =>
      $$MeasurementCategoriesTableTableManager(_db, _db.measurementCategories);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$DailyStepEntriesTableTableManager get dailyStepEntries =>
      $$DailyStepEntriesTableTableManager(_db, _db.dailyStepEntries);
  $$RunSessionsTableTableManager get runSessions =>
      $$RunSessionsTableTableManager(_db, _db.runSessions);
}
