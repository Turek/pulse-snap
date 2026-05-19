// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReadingsTable extends Readings with TableInfo<$ReadingsTable, Reading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systolicMeta = const VerificationMeta(
    'systolic',
  );
  @override
  late final GeneratedColumn<int> systolic = GeneratedColumn<int>(
    'systolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diastolicMeta = const VerificationMeta(
    'diastolic',
  );
  @override
  late final GeneratedColumn<int> diastolic = GeneratedColumn<int>(
    'diastolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulseMeta = const VerificationMeta('pulse');
  @override
  late final GeneratedColumn<int> pulse = GeneratedColumn<int>(
    'pulse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScannerType, String> sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ScannerType>($ReadingsTable.$convertersourceType);
  static const VerificationMeta _deviceLabelMeta = const VerificationMeta(
    'deviceLabel',
  );
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
    'device_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrConfidenceMeta = const VerificationMeta(
    'ocrConfidence',
  );
  @override
  late final GeneratedColumn<double> ocrConfidence = GeneratedColumn<double>(
    'ocr_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isManuallyEditedMeta = const VerificationMeta(
    'isManuallyEdited',
  );
  @override
  late final GeneratedColumn<bool> isManuallyEdited = GeneratedColumn<bool>(
    'is_manually_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manually_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    measuredAt,
    systolic,
    diastolic,
    pulse,
    sourceType,
    deviceLabel,
    ocrConfidence,
    isManuallyEdited,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('systolic')) {
      context.handle(
        _systolicMeta,
        systolic.isAcceptableOrUnknown(data['systolic']!, _systolicMeta),
      );
    }
    if (data.containsKey('diastolic')) {
      context.handle(
        _diastolicMeta,
        diastolic.isAcceptableOrUnknown(data['diastolic']!, _diastolicMeta),
      );
    }
    if (data.containsKey('pulse')) {
      context.handle(
        _pulseMeta,
        pulse.isAcceptableOrUnknown(data['pulse']!, _pulseMeta),
      );
    }
    if (data.containsKey('device_label')) {
      context.handle(
        _deviceLabelMeta,
        deviceLabel.isAcceptableOrUnknown(
          data['device_label']!,
          _deviceLabelMeta,
        ),
      );
    }
    if (data.containsKey('ocr_confidence')) {
      context.handle(
        _ocrConfidenceMeta,
        ocrConfidence.isAcceptableOrUnknown(
          data['ocr_confidence']!,
          _ocrConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('is_manually_edited')) {
      context.handle(
        _isManuallyEditedMeta,
        isManuallyEdited.isAcceptableOrUnknown(
          data['is_manually_edited']!,
          _isManuallyEditedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      systolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}systolic'],
      ),
      diastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diastolic'],
      ),
      pulse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse'],
      ),
      sourceType: $ReadingsTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      deviceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_label'],
      ),
      ocrConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ocr_confidence'],
      ),
      isManuallyEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manually_edited'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ScannerType, String, String> $convertersourceType =
      const EnumNameConverter<ScannerType>(ScannerType.values);
}

class Reading extends DataClass implements Insertable<Reading> {
  final int id;
  final String userId;
  final DateTime measuredAt;
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final ScannerType sourceType;
  final String? deviceLabel;
  final double? ocrConfidence;
  final bool isManuallyEdited;
  final DateTime createdAt;
  const Reading({
    required this.id,
    required this.userId,
    required this.measuredAt,
    this.systolic,
    this.diastolic,
    this.pulse,
    required this.sourceType,
    this.deviceLabel,
    this.ocrConfidence,
    required this.isManuallyEdited,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    if (!nullToAbsent || systolic != null) {
      map['systolic'] = Variable<int>(systolic);
    }
    if (!nullToAbsent || diastolic != null) {
      map['diastolic'] = Variable<int>(diastolic);
    }
    if (!nullToAbsent || pulse != null) {
      map['pulse'] = Variable<int>(pulse);
    }
    {
      map['source_type'] = Variable<String>(
        $ReadingsTable.$convertersourceType.toSql(sourceType),
      );
    }
    if (!nullToAbsent || deviceLabel != null) {
      map['device_label'] = Variable<String>(deviceLabel);
    }
    if (!nullToAbsent || ocrConfidence != null) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence);
    }
    map['is_manually_edited'] = Variable<bool>(isManuallyEdited);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      userId: Value(userId),
      measuredAt: Value(measuredAt),
      systolic: systolic == null && nullToAbsent
          ? const Value.absent()
          : Value(systolic),
      diastolic: diastolic == null && nullToAbsent
          ? const Value.absent()
          : Value(diastolic),
      pulse: pulse == null && nullToAbsent
          ? const Value.absent()
          : Value(pulse),
      sourceType: Value(sourceType),
      deviceLabel: deviceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceLabel),
      ocrConfidence: ocrConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConfidence),
      isManuallyEdited: Value(isManuallyEdited),
      createdAt: Value(createdAt),
    );
  }

  factory Reading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reading(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      systolic: serializer.fromJson<int?>(json['systolic']),
      diastolic: serializer.fromJson<int?>(json['diastolic']),
      pulse: serializer.fromJson<int?>(json['pulse']),
      sourceType: $ReadingsTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      deviceLabel: serializer.fromJson<String?>(json['deviceLabel']),
      ocrConfidence: serializer.fromJson<double?>(json['ocrConfidence']),
      isManuallyEdited: serializer.fromJson<bool>(json['isManuallyEdited']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'systolic': serializer.toJson<int?>(systolic),
      'diastolic': serializer.toJson<int?>(diastolic),
      'pulse': serializer.toJson<int?>(pulse),
      'sourceType': serializer.toJson<String>(
        $ReadingsTable.$convertersourceType.toJson(sourceType),
      ),
      'deviceLabel': serializer.toJson<String?>(deviceLabel),
      'ocrConfidence': serializer.toJson<double?>(ocrConfidence),
      'isManuallyEdited': serializer.toJson<bool>(isManuallyEdited),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reading copyWith({
    int? id,
    String? userId,
    DateTime? measuredAt,
    Value<int?> systolic = const Value.absent(),
    Value<int?> diastolic = const Value.absent(),
    Value<int?> pulse = const Value.absent(),
    ScannerType? sourceType,
    Value<String?> deviceLabel = const Value.absent(),
    Value<double?> ocrConfidence = const Value.absent(),
    bool? isManuallyEdited,
    DateTime? createdAt,
  }) => Reading(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    measuredAt: measuredAt ?? this.measuredAt,
    systolic: systolic.present ? systolic.value : this.systolic,
    diastolic: diastolic.present ? diastolic.value : this.diastolic,
    pulse: pulse.present ? pulse.value : this.pulse,
    sourceType: sourceType ?? this.sourceType,
    deviceLabel: deviceLabel.present ? deviceLabel.value : this.deviceLabel,
    ocrConfidence: ocrConfidence.present
        ? ocrConfidence.value
        : this.ocrConfidence,
    isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
    createdAt: createdAt ?? this.createdAt,
  );
  Reading copyWithCompanion(ReadingsCompanion data) {
    return Reading(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      systolic: data.systolic.present ? data.systolic.value : this.systolic,
      diastolic: data.diastolic.present ? data.diastolic.value : this.diastolic,
      pulse: data.pulse.present ? data.pulse.value : this.pulse,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      deviceLabel: data.deviceLabel.present
          ? data.deviceLabel.value
          : this.deviceLabel,
      ocrConfidence: data.ocrConfidence.present
          ? data.ocrConfidence.value
          : this.ocrConfidence,
      isManuallyEdited: data.isManuallyEdited.present
          ? data.isManuallyEdited.value
          : this.isManuallyEdited,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reading(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('sourceType: $sourceType, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('isManuallyEdited: $isManuallyEdited, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    measuredAt,
    systolic,
    diastolic,
    pulse,
    sourceType,
    deviceLabel,
    ocrConfidence,
    isManuallyEdited,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reading &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.measuredAt == this.measuredAt &&
          other.systolic == this.systolic &&
          other.diastolic == this.diastolic &&
          other.pulse == this.pulse &&
          other.sourceType == this.sourceType &&
          other.deviceLabel == this.deviceLabel &&
          other.ocrConfidence == this.ocrConfidence &&
          other.isManuallyEdited == this.isManuallyEdited &&
          other.createdAt == this.createdAt);
}

class ReadingsCompanion extends UpdateCompanion<Reading> {
  final Value<int> id;
  final Value<String> userId;
  final Value<DateTime> measuredAt;
  final Value<int?> systolic;
  final Value<int?> diastolic;
  final Value<int?> pulse;
  final Value<ScannerType> sourceType;
  final Value<String?> deviceLabel;
  final Value<double?> ocrConfidence;
  final Value<bool> isManuallyEdited;
  final Value<DateTime> createdAt;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.pulse = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.isManuallyEdited = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required DateTime measuredAt,
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.pulse = const Value.absent(),
    required ScannerType sourceType,
    this.deviceLabel = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.isManuallyEdited = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : measuredAt = Value(measuredAt),
       sourceType = Value(sourceType);
  static Insertable<Reading> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<DateTime>? measuredAt,
    Expression<int>? systolic,
    Expression<int>? diastolic,
    Expression<int>? pulse,
    Expression<String>? sourceType,
    Expression<String>? deviceLabel,
    Expression<double>? ocrConfidence,
    Expression<bool>? isManuallyEdited,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (pulse != null) 'pulse': pulse,
      if (sourceType != null) 'source_type': sourceType,
      if (deviceLabel != null) 'device_label': deviceLabel,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (isManuallyEdited != null) 'is_manually_edited': isManuallyEdited,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<DateTime>? measuredAt,
    Value<int?>? systolic,
    Value<int?>? diastolic,
    Value<int?>? pulse,
    Value<ScannerType>? sourceType,
    Value<String?>? deviceLabel,
    Value<double?>? ocrConfidence,
    Value<bool>? isManuallyEdited,
    Value<DateTime>? createdAt,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      measuredAt: measuredAt ?? this.measuredAt,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      sourceType: sourceType ?? this.sourceType,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (systolic.present) {
      map['systolic'] = Variable<int>(systolic.value);
    }
    if (diastolic.present) {
      map['diastolic'] = Variable<int>(diastolic.value);
    }
    if (pulse.present) {
      map['pulse'] = Variable<int>(pulse.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $ReadingsTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (deviceLabel.present) {
      map['device_label'] = Variable<String>(deviceLabel.value);
    }
    if (ocrConfidence.present) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence.value);
    }
    if (isManuallyEdited.present) {
      map['is_manually_edited'] = Variable<bool>(isManuallyEdited.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('sourceType: $sourceType, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('isManuallyEdited: $isManuallyEdited, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingTagsTable extends ReadingTags
    with TableInfo<$ReadingTagsTable, ReadingTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _readingIdMeta = const VerificationMeta(
    'readingId',
  );
  @override
  late final GeneratedColumn<int> readingId = GeneratedColumn<int>(
    'reading_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemTagMeta = const VerificationMeta(
    'isSystemTag',
  );
  @override
  late final GeneratedColumn<bool> isSystemTag = GeneratedColumn<bool>(
    'is_system_tag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_tag" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    readingId,
    value,
    isSystemTag,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reading_id')) {
      context.handle(
        _readingIdMeta,
        readingId.isAcceptableOrUnknown(data['reading_id']!, _readingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readingIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('is_system_tag')) {
      context.handle(
        _isSystemTagMeta,
        isSystemTag.isAcceptableOrUnknown(
          data['is_system_tag']!,
          _isSystemTagMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      readingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      isSystemTag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_tag'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingTagsTable createAlias(String alias) {
    return $ReadingTagsTable(attachedDatabase, alias);
  }
}

class ReadingTag extends DataClass implements Insertable<ReadingTag> {
  final int id;
  final int readingId;
  final String value;
  final bool isSystemTag;
  final DateTime createdAt;
  const ReadingTag({
    required this.id,
    required this.readingId,
    required this.value,
    required this.isSystemTag,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reading_id'] = Variable<int>(readingId);
    map['value'] = Variable<String>(value);
    map['is_system_tag'] = Variable<bool>(isSystemTag);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReadingTagsCompanion toCompanion(bool nullToAbsent) {
    return ReadingTagsCompanion(
      id: Value(id),
      readingId: Value(readingId),
      value: Value(value),
      isSystemTag: Value(isSystemTag),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingTag(
      id: serializer.fromJson<int>(json['id']),
      readingId: serializer.fromJson<int>(json['readingId']),
      value: serializer.fromJson<String>(json['value']),
      isSystemTag: serializer.fromJson<bool>(json['isSystemTag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'readingId': serializer.toJson<int>(readingId),
      'value': serializer.toJson<String>(value),
      'isSystemTag': serializer.toJson<bool>(isSystemTag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReadingTag copyWith({
    int? id,
    int? readingId,
    String? value,
    bool? isSystemTag,
    DateTime? createdAt,
  }) => ReadingTag(
    id: id ?? this.id,
    readingId: readingId ?? this.readingId,
    value: value ?? this.value,
    isSystemTag: isSystemTag ?? this.isSystemTag,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingTag copyWithCompanion(ReadingTagsCompanion data) {
    return ReadingTag(
      id: data.id.present ? data.id.value : this.id,
      readingId: data.readingId.present ? data.readingId.value : this.readingId,
      value: data.value.present ? data.value.value : this.value,
      isSystemTag: data.isSystemTag.present
          ? data.isSystemTag.value
          : this.isSystemTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingTag(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('value: $value, ')
          ..write('isSystemTag: $isSystemTag, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, readingId, value, isSystemTag, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingTag &&
          other.id == this.id &&
          other.readingId == this.readingId &&
          other.value == this.value &&
          other.isSystemTag == this.isSystemTag &&
          other.createdAt == this.createdAt);
}

class ReadingTagsCompanion extends UpdateCompanion<ReadingTag> {
  final Value<int> id;
  final Value<int> readingId;
  final Value<String> value;
  final Value<bool> isSystemTag;
  final Value<DateTime> createdAt;
  const ReadingTagsCompanion({
    this.id = const Value.absent(),
    this.readingId = const Value.absent(),
    this.value = const Value.absent(),
    this.isSystemTag = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReadingTagsCompanion.insert({
    this.id = const Value.absent(),
    required int readingId,
    required String value,
    this.isSystemTag = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : readingId = Value(readingId),
       value = Value(value);
  static Insertable<ReadingTag> custom({
    Expression<int>? id,
    Expression<int>? readingId,
    Expression<String>? value,
    Expression<bool>? isSystemTag,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readingId != null) 'reading_id': readingId,
      if (value != null) 'value': value,
      if (isSystemTag != null) 'is_system_tag': isSystemTag,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReadingTagsCompanion copyWith({
    Value<int>? id,
    Value<int>? readingId,
    Value<String>? value,
    Value<bool>? isSystemTag,
    Value<DateTime>? createdAt,
  }) {
    return ReadingTagsCompanion(
      id: id ?? this.id,
      readingId: readingId ?? this.readingId,
      value: value ?? this.value,
      isSystemTag: isSystemTag ?? this.isSystemTag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (readingId.present) {
      map['reading_id'] = Variable<int>(readingId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (isSystemTag.present) {
      map['is_system_tag'] = Variable<bool>(isSystemTag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingTagsCompanion(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('value: $value, ')
          ..write('isSystemTag: $isSystemTag, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $ReadingTagsTable readingTags = $ReadingTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [readings, readingTags];
}

typedef $$ReadingsTableCreateCompanionBuilder =
    ReadingsCompanion Function({
      Value<int> id,
      Value<String> userId,
      required DateTime measuredAt,
      Value<int?> systolic,
      Value<int?> diastolic,
      Value<int?> pulse,
      required ScannerType sourceType,
      Value<String?> deviceLabel,
      Value<double?> ocrConfidence,
      Value<bool> isManuallyEdited,
      Value<DateTime> createdAt,
    });
typedef $$ReadingsTableUpdateCompanionBuilder =
    ReadingsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<DateTime> measuredAt,
      Value<int?> systolic,
      Value<int?> diastolic,
      Value<int?> pulse,
      Value<ScannerType> sourceType,
      Value<String?> deviceLabel,
      Value<double?> ocrConfidence,
      Value<bool> isManuallyEdited,
      Value<DateTime> createdAt,
    });

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScannerType, ScannerType, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get systolic =>
      $composableBuilder(column: $table.systolic, builder: (column) => column);

  GeneratedColumn<int> get diastolic =>
      $composableBuilder(column: $table.diastolic, builder: (column) => column);

  GeneratedColumn<int> get pulse =>
      $composableBuilder(column: $table.pulse, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScannerType, String> get sourceType =>
      $composableBuilder(
        column: $table.sourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingsTable,
          Reading,
          $$ReadingsTableFilterComposer,
          $$ReadingsTableOrderingComposer,
          $$ReadingsTableAnnotationComposer,
          $$ReadingsTableCreateCompanionBuilder,
          $$ReadingsTableUpdateCompanionBuilder,
          (Reading, BaseReferences<_$AppDatabase, $ReadingsTable, Reading>),
          Reading,
          PrefetchHooks Function()
        > {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<int?> systolic = const Value.absent(),
                Value<int?> diastolic = const Value.absent(),
                Value<int?> pulse = const Value.absent(),
                Value<ScannerType> sourceType = const Value.absent(),
                Value<String?> deviceLabel = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<bool> isManuallyEdited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                userId: userId,
                measuredAt: measuredAt,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                sourceType: sourceType,
                deviceLabel: deviceLabel,
                ocrConfidence: ocrConfidence,
                isManuallyEdited: isManuallyEdited,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                required DateTime measuredAt,
                Value<int?> systolic = const Value.absent(),
                Value<int?> diastolic = const Value.absent(),
                Value<int?> pulse = const Value.absent(),
                required ScannerType sourceType,
                Value<String?> deviceLabel = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<bool> isManuallyEdited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingsCompanion.insert(
                id: id,
                userId: userId,
                measuredAt: measuredAt,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                sourceType: sourceType,
                deviceLabel: deviceLabel,
                ocrConfidence: ocrConfidence,
                isManuallyEdited: isManuallyEdited,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingsTable,
      Reading,
      $$ReadingsTableFilterComposer,
      $$ReadingsTableOrderingComposer,
      $$ReadingsTableAnnotationComposer,
      $$ReadingsTableCreateCompanionBuilder,
      $$ReadingsTableUpdateCompanionBuilder,
      (Reading, BaseReferences<_$AppDatabase, $ReadingsTable, Reading>),
      Reading,
      PrefetchHooks Function()
    >;
typedef $$ReadingTagsTableCreateCompanionBuilder =
    ReadingTagsCompanion Function({
      Value<int> id,
      required int readingId,
      required String value,
      Value<bool> isSystemTag,
      Value<DateTime> createdAt,
    });
typedef $$ReadingTagsTableUpdateCompanionBuilder =
    ReadingTagsCompanion Function({
      Value<int> id,
      Value<int> readingId,
      Value<String> value,
      Value<bool> isSystemTag,
      Value<DateTime> createdAt,
    });

class $$ReadingTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingTagsTable> {
  $$ReadingTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemTag => $composableBuilder(
    column: $table.isSystemTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingTagsTable> {
  $$ReadingTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemTag => $composableBuilder(
    column: $table.isSystemTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingTagsTable> {
  $$ReadingTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get readingId =>
      $composableBuilder(column: $table.readingId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isSystemTag => $composableBuilder(
    column: $table.isSystemTag,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingTagsTable,
          ReadingTag,
          $$ReadingTagsTableFilterComposer,
          $$ReadingTagsTableOrderingComposer,
          $$ReadingTagsTableAnnotationComposer,
          $$ReadingTagsTableCreateCompanionBuilder,
          $$ReadingTagsTableUpdateCompanionBuilder,
          (
            ReadingTag,
            BaseReferences<_$AppDatabase, $ReadingTagsTable, ReadingTag>,
          ),
          ReadingTag,
          PrefetchHooks Function()
        > {
  $$ReadingTagsTableTableManager(_$AppDatabase db, $ReadingTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> readingId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<bool> isSystemTag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingTagsCompanion(
                id: id,
                readingId: readingId,
                value: value,
                isSystemTag: isSystemTag,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int readingId,
                required String value,
                Value<bool> isSystemTag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingTagsCompanion.insert(
                id: id,
                readingId: readingId,
                value: value,
                isSystemTag: isSystemTag,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingTagsTable,
      ReadingTag,
      $$ReadingTagsTableFilterComposer,
      $$ReadingTagsTableOrderingComposer,
      $$ReadingTagsTableAnnotationComposer,
      $$ReadingTagsTableCreateCompanionBuilder,
      $$ReadingTagsTableUpdateCompanionBuilder,
      (
        ReadingTag,
        BaseReferences<_$AppDatabase, $ReadingTagsTable, ReadingTag>,
      ),
      ReadingTag,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$ReadingTagsTableTableManager get readingTags =>
      $$ReadingTagsTableTableManager(_db, _db.readingTags);
}
