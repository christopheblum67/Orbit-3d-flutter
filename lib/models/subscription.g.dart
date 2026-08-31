// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 3;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as SubscriptionType,
      baseUrl: fields[3] as String?,
      username: fields[4] as String?,
      password: fields[5] as String?,
      m3uUrl: fields[6] as String?,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      lastTestedAt: fields[9] as DateTime?,
      lastTestResult: fields[10] as TestResultStatus,
      lastTestLatencyMs: fields[11] as int?,
      lastTestError: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.baseUrl)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.m3uUrl)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastTestedAt)
      ..writeByte(10)
      ..write(obj.lastTestResult)
      ..writeByte(11)
      ..write(obj.lastTestLatencyMs)
      ..writeByte(12)
      ..write(obj.lastTestError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionTypeAdapter extends TypeAdapter<SubscriptionType> {
  @override
  final int typeId = 1;

  @override
  SubscriptionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionType.xtream;
      case 1:
        return SubscriptionType.m3u;
      default:
        return SubscriptionType.xtream;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionType obj) {
    switch (obj) {
      case SubscriptionType.xtream:
        writer.writeByte(0);
        break;
      case SubscriptionType.m3u:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestResultStatusAdapter extends TypeAdapter<TestResultStatus> {
  @override
  final int typeId = 2;

  @override
  TestResultStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TestResultStatus.success;
      case 1:
        return TestResultStatus.error;
      case 2:
        return TestResultStatus.untested;
      default:
        return TestResultStatus.success;
    }
  }

  @override
  void write(BinaryWriter writer, TestResultStatus obj) {
    switch (obj) {
      case TestResultStatus.success:
        writer.writeByte(0);
        break;
      case TestResultStatus.error:
        writer.writeByte(1);
        break;
      case TestResultStatus.untested:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
