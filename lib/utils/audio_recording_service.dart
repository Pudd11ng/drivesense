import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AudioRecordingService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final Uuid _uuid = Uuid();

  // Check and request microphone permission
  static Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // Start recording
  static Future<bool> startRecording() async {
    try {
      if (!await checkPermission()) {
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'temp_recording_${_uuid.v4()}.m4a';
      final filePath = '${directory.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and return file path
  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  // Check if currently recording
  static Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Cancel recording
  static Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  // Save recorded file with custom name
  static Future<String?> saveRecordedFile(
    String tempPath,
    String customName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_files');

      // Create directory if it doesn't exist
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = '${customName}_${_uuid.v4()}.m4a';
      final newPath = '${audioDir.path}/$fileName';

      // Copy temp file to permanent location
      final tempFile = File(tempPath);
      await tempFile.copy(newPath);

      // Delete temp file
      await tempFile.delete();

      return newPath;
    } catch (e) {
      debugPrint('Error saving recorded file: $e');
      return null;
    }
  }
}
