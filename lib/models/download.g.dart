// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadProgressAdapter extends TypeAdapter<DownloadProgress> {
  @override
  final int typeId = 51;

  @override
  DownloadProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadProgress(
      bytesDownloaded: fields[0] as int,
      totalBytes: fields[1] as int,
      speedBytesPerSec: fields[2] as double,
      estimatedTimeRemaining: fields[3] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bytesDownloaded)
      ..writeByte(1)
      ..write(obj.totalBytes)
      ..writeByte(2)
      ..write(obj.speedBytesPerSec)
      ..writeByte(3)
      ..write(obj.estimatedTimeRemaining);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadConfigAdapter extends TypeAdapter<DownloadConfig> {
  @override
  final int typeId = 52;

  @override
  DownloadConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadConfig(
      wifiOnly: fields[0] as bool,
      maxConcurrentDownloads: fields[1] as int,
      retryAttempts: fields[2] as int,
      retryDelay: fields[3] as Duration,
      deleteAfterWatch: fields[4] as bool,
      preferredQuality: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.wifiOnly)
      ..writeByte(1)
      ..write(obj.maxConcurrentDownloads)
      ..writeByte(2)
      ..write(obj.retryAttempts)
      ..writeByte(3)
      ..write(obj.retryDelay)
      ..writeByte(4)
      ..write(obj.deleteAfterWatch)
      ..writeByte(5)
      ..write(obj.preferredQuality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final int typeId = 53;

  @override
  DownloadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTask(
      id: fields[0] as String,
      mediaItemId: fields[1] as String,
      title: fields[2] as String,
      posterUrl: fields[3] as String?,
      streamUrl: fields[4] as String,
      drmToken: fields[5] as String?,
      localPath: fields[6] as String,
      status: fields[7] as DownloadStatus,
      progress: fields[8] as DownloadProgress?,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime?,
      completedAt: fields[11] as DateTime?,
      errorMessage: fields[12] as String?,
      retryCount: fields[13] as int,
      contentType: fields[14] as String,
      seriesId: fields[15] as String?,
      seasonNumber: fields[16] as int?,
      episodeNumber: fields[17] as int?,
      episodeTitle: fields[18] as String?,
      headers: (fields[19] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mediaItemId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.posterUrl)
      ..writeByte(4)
      ..write(obj.streamUrl)
      ..writeByte(5)
      ..write(obj.drmToken)
      ..writeByte(6)
      ..write(obj.localPath)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.progress)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.completedAt)
      ..writeByte(12)
      ..write(obj.errorMessage)
      ..writeByte(13)
      ..write(obj.retryCount)
      ..writeByte(14)
      ..write(obj.contentType)
      ..writeByte(15)
      ..write(obj.seriesId)
      ..writeByte(16)
      ..write(obj.seasonNumber)
      ..writeByte(17)
      ..write(obj.episodeNumber)
      ..writeByte(18)
      ..write(obj.episodeTitle)
      ..writeByte(19)
      ..write(obj.headers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final int typeId = 50;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.queued;
      case 1:
        return DownloadStatus.preparing;
      case 2:
        return DownloadStatus.downloading;
      case 3:
        return DownloadStatus.paused;
      case 4:
        return DownloadStatus.completed;
      case 5:
        return DownloadStatus.failed;
      case 6:
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.queued;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.queued:
        writer.writeByte(0);
        break;
      case DownloadStatus.preparing:
        writer.writeByte(1);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(2);
        break;
      case DownloadStatus.paused:
        writer.writeByte(3);
        break;
      case DownloadStatus.completed:
        writer.writeByte(4);
        break;
      case DownloadStatus.failed:
        writer.writeByte(5);
        break;
      case DownloadStatus.cancelled:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
