import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/utils/sound_service.dart';
import 'package:drivesense/utils/audio_recording_service.dart';
import 'package:drivesense/utils/cloud_storage_service.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

final List<String> behaviours = [
  'Drowsiness',
  'Distraction',
  'Intoxication',
  'Phone Usage',
];

final Map<String, dynamic> defaultAudioFiles = {
  'Drowsiness': {
    'name': 'drowsiness.mp3',
    'path': 'assets/audio alert/audio_alert_drowsiness.mp3',
  },
  'Distraction': {
    'name': 'distraction.mp3',
    'path': 'assets/audio alert/audio_alert_distraction.mp3',
  },
  'Intoxication': {
    'name': 'intoxication.mp3',
    'path': 'assets/audio alert/audio_alert_intoxication.mp3',
  },
  'Phone Usage': {
    'name': 'phone_usage.mp3',
    'path': 'assets/audio alert/audio_alert_phone_usage.mp3',
  },
};

class ExtraConfigView extends StatefulWidget {
  final String alertTypeName;

  const ExtraConfigView({super.key, required this.alertTypeName});

  @override
  State<ExtraConfigView> createState() => _ExtraConfigViewState();
}

class _ExtraConfigViewState extends State<ExtraConfigView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingItem;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final viewModel = Provider.of<AlertViewModel>(context, listen: false);
      if (!viewModel.hasAlert) {
        viewModel.loadAlert();
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Consumer<AlertViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppHeaderBar(
            title: widget.alertTypeName,
            leading: Icon(Icons.arrow_back),
            onLeadingPressed: () => context.go('/manage_alert'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDarkMode
                                ? AppColors.blue.withValues(alpha: 0.2)
                                : AppColors.blue.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.blue.withValues(alpha: 0.2)
                                      : AppColors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isDarkMode
                                          ? AppColors.blue.withValues(
                                            alpha: 0.2,
                                          )
                                          : AppColors.darkBlue.withValues(
                                            alpha: 0.1,
                                          ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getHeaderIcon(),
                              color:
                                  isDarkMode
                                      ? AppColors.blue
                                      : AppColors.darkBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configure Alert Sounds',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getHeaderDescription(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        isDarkMode
                                            ? AppColors.greyBlue
                                            : AppColors.grey,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Behaviors list - now will take exactly the space it needs
                  _buildBehaviorsList(viewModel, isDarkMode, accentColor),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/manage_alert',
          ),
        );
      },
    );
  }

  IconData _getHeaderIcon() {
    switch (widget.alertTypeName) {
      case 'Audio':
        return Icons.notifications_active;
      case 'Self-Configured Audio':
        return Icons.settings_voice;
      case 'Music':
        return Icons.music_note;
      default:
        return Icons.notifications_active;
    }
  }

  String _getHeaderDescription() {
    switch (widget.alertTypeName) {
      case 'Audio':
        return 'Set predefined audio alerts for different behaviors';
      case 'Self-Configured Audio':
        return 'Upload custom audio files for each detection type';
      case 'Music':
        return 'Select songs to play when behaviors are detected';
      default:
        return 'Configure alert preferences';
    }
  }

  Widget _buildBehaviorsList(
    AlertViewModel viewModel,
    bool isDarkMode,
    Color accentColor,
  ) {
    final backgroundColor = isDarkMode ? AppColors.darkGrey : Colors.white;
    final borderColor =
        isDarkMode
            ? AppColors.greyBlue.withValues(alpha: 0.2)
            : AppColors.lightGrey;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ), // Add margin at bottom for spacing
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          padding: EdgeInsets.zero, // Remove default padding
          itemCount: behaviours.length,
          separatorBuilder:
              (context, index) =>
                  Divider(color: borderColor, height: 1, thickness: 0.5),
          itemBuilder: (context, index) {
            final behaviour = behaviours[index];
            return _buildBehaviorItem(
              context,
              viewModel,
              behaviour,
              isDarkMode,
              accentColor,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBehaviorItem(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
    bool isDarkMode,
    Color accentColor,
  ) {
    String? file = 'No file selected';
    String? filePath;

    // Add null safety check first
    if (!viewModel.hasAlert) {
      return ListTile(title: Text(behaviour), subtitle: Text('Loading...'));
    }

    // Get both name and path based on alert type
    if (widget.alertTypeName == 'Audio') {
      final fileData = defaultAudioFiles[behaviour];
      file = fileData?['name'];
      filePath = fileData?['path'];
    } else if (widget.alertTypeName == 'Self-Configured Audio') {
      final fileData = viewModel.alert!.audioFilePath[behaviour];
      file = fileData?['name'];
      filePath = fileData?['path'];
    } else if (widget.alertTypeName == 'Music') {
      final fileData = viewModel.alert!.musicPlayList[behaviour];
      file = fileData?['name'];
      filePath = fileData?['path'];
    }

    bool isThisItemPlaying = _isPlaying && _currentPlayingItem == behaviour;
    String displayName = file ?? 'No file selected';

    // Truncate long file names
    if (displayName.length > 25) {
      displayName = '${displayName.substring(0, 22)}...';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color:
            isThisItemPlaying
                ? accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 40,
        leading: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isThisItemPlaying
                    ? accentColor.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getBehaviorIcon(behaviour),
            color: accentColor,
            size: 20,
          ),
        ),
        title: Text(
          behaviour,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isDarkMode ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show the play button if we have a valid file path to play
            if (file != null &&
                file.isNotEmpty &&
                filePath != null &&
                filePath.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          isThisItemPlaying
                              ? accentColor
                              : accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isThisItemPlaying ? Icons.stop : Icons.play_arrow,
                      color: isThisItemPlaying ? Colors.white : accentColor,
                      size: 14,
                    ),
                  ),
                  onPressed: () => _playOrPauseAudio(behaviour, filePath!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (widget.alertTypeName != 'Audio') ...{
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),

                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap:
                      () => _showFileSelectionDialog(
                        context,
                        viewModel,
                        behaviour,
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getActionIconForAlertType(file),
                        color: accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (file?.isEmpty ?? true) ? 'Select' : 'Change',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            },
          ],
        ),
        onTap: () {
          _showFileSelectionDialog(context, viewModel, behaviour);
        },
      ),
    );
  }

  IconData _getBehaviorIcon(String behaviour) {
    switch (behaviour) {
      case 'Drowsiness':
        return Icons.nightlight;
      case 'Distraction':
        return Icons.remove_red_eye;
      case 'Intoxication':
        return Icons.warning;
      case 'Phone Usage':
        return Icons.phone_android;
      default:
        return Icons.assignment_late;
    }
  }

  IconData _getActionIconForAlertType(String? file) {
    if (widget.alertTypeName == 'Audio') {
      return Icons.headphones;
    } else if (widget.alertTypeName == 'Self-Configured Audio') {
      return file != null ? Icons.edit : Icons.upload_file;
    } else {
      return file != null ? Icons.edit : Icons.library_music;
    }
  }

  void _showFileSelectionDialog(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    switch (widget.alertTypeName) {
      case 'Audio':
        // For Audio type, just play the predefined sound
        _playOrPauseAudio(behaviour, defaultAudioFiles[behaviour]['path']);
        break;
      case 'Self-Configured Audio':
        // For Self-Configured Audio, show file picker
        _showAudioFilePickerDialog(context, viewModel, behaviour);
        break;
      case 'Music':
        // For Music, show FreeSound selection
        _showFreeSoundSelectionDialog(context, viewModel, behaviour);
        break;
    }
  }

  void _showAudioFilePickerDialog(
    BuildContext methodContext,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    // Variables for recording state
    bool isRecording = false;
    bool isUploading = false;
    int recordingDuration = 0;
    Timer? recordingTimer;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              // Stop recording function
              void stopRecording() async {
                recordingTimer?.cancel();
                recordingTimer = null;

                setState(() {
                  isRecording = false;
                });

                final path = await AudioRecordingService.stopRecording();
                if (path != null) {
                  setState(() {
                    isUploading = true;
                  });

                  try {
                    // Get signed URL from backend
                    final uploadData =
                        await CloudStorageService.getSignedUploadUrl(
                          behaviour,
                          'm4a',
                          'audio/mp4',
                        );

                    final signedUrl = uploadData['signedUrl'];
                    final publicUrl = uploadData['publicUrl'];

                    // Upload file to GCP using the signed URL
                    final file = File(path);
                    await CloudStorageService.uploadFileWithSignedUrl(
                      file,
                      signedUrl,
                      'audio/mp4',
                    );

                    // Update the alert with the cloud URL
                    final fileName = '${behaviour}_recording.m4a';
                    await viewModel.updateAudioFile(
                      behaviour,
                      fileName,
                      audioPath: publicUrl,
                    );

                    // Delete the temporary file - we don't need to keep it locally
                    try {
                      await file.delete();
                    } catch (e) {
                      // Silently handle deletion errors - not critical
                      debugPrint('Warning: Could not delete temp file: $e');
                    }

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Audio recorded and uploaded successfully',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() {
                      isUploading = false;
                    });
                  }
                }
              }

              // Start recording function
              void startRecording() async {
                final success = await AudioRecordingService.startRecording();
                if (success) {
                  setState(() {
                    isRecording = true;
                    recordingDuration = 0;
                  });

                  // Start timer to track recording duration
                  recordingTimer = Timer.periodic(const Duration(seconds: 1), (
                    timer,
                  ) {
                    setState(() {
                      recordingDuration++;
                      if (recordingDuration >= 60) {
                        // 60 seconds = 1 minute limit
                        stopRecording();
                      }
                    });
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start recording'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              // Cancel recording function
              void cancelRecording() async {
                recordingTimer?.cancel();
                recordingTimer = null;
                await AudioRecordingService.cancelRecording();
                setState(() {
                  isRecording = false;
                  recordingDuration = 0;
                });
              }

              // Upload existing audio file
              void pickAndUploadFile() async {
                try {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(type: FileType.audio, allowMultiple: false);

                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      isUploading = true;
                    });

                    // Get file details
                    final filePath = result.files.single.path!;
                    final fileName = result.files.single.name;
                    final fileExt = fileName.split('.').last.toLowerCase();
                    final contentType = 'audio/$fileExt';

                    try {
                      // Get signed URL from backend
                      final uploadData =
                          await CloudStorageService.getSignedUploadUrl(
                            behaviour,
                            fileExt,
                            contentType,
                          );

                      final signedUrl = uploadData['signedUrl'];
                      final publicUrl = uploadData['publicUrl'];

                      // Upload the file
                      final file = File(filePath);
                      await CloudStorageService.uploadFileWithSignedUrl(
                        file,
                        signedUrl,
                        contentType,
                      );

                      // Update the alert with the cloud URL
                      await viewModel.updateAudioFile(
                        behaviour,
                        fileName, // Show the original filename to the user
                        audioPath: publicUrl,
                      );

                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'File "$fileName" uploaded successfully',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Upload failed: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          isUploading = false;
                        });
                      }
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error selecting file: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }

              String formatDuration(int seconds) {
                final minutes = seconds ~/ 60;
                final remainingSeconds = seconds % 60;
                return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
              }

              return AlertDialog(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Add Audio for $behaviour',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 300,
                    maxWidth: 400,
                    minHeight: 100,
                    maxHeight: 320,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRecording) ...[
                        // Recording UI
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.mic, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Recording...',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatDuration(recordingDuration),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Maximum: 01:00',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? AppColors.greyBlue
                                          : AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: cancelRecording,
                              icon: const Icon(Icons.close),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: stopRecording,
                              icon: const Icon(Icons.stop),
                              label: const Text(
                                'Stop',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else if (isUploading) ...[
                        // Uploading UI
                        const SizedBox(height: 20),
                        CircularProgressIndicator(color: accentColor),
                        const SizedBox(height: 20),
                        Text(
                          'Uploading audio to cloud...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.greyBlue
                                    : AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        // Selection options UI
                        const SizedBox(height: 8),
                        Text(
                          'Choose how to add audio for this alert:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.greyBlue
                                    : AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Record button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: startRecording,
                            icon: const Icon(Icons.mic),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Record Audio (max 1 minute)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Divider with "OR"
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? AppColors.greyBlue
                                          : AppColors.grey,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Upload button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: pickAndUploadFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Select Existing Audio File',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(color: accentColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info Text
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? AppColors.greyBlue.withValues(alpha: 0.1)
                                    : AppColors.lightGrey.withValues(
                                      alpha: 0.2,
                                    ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Supported formats: MP3, WAV, M4A\nMax file size: 10MB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? AppColors.greyBlue
                                      : AppColors.grey,
                            ),
                          ),
                        ),

                        if (!isRecording && !isUploading) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.greyBlue
                                        : AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showFreeSoundSelectionDialog(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    // Create a dedicated audio player for the dialog
    final dialogAudioPlayer = AudioPlayer();
    bool isDialogPlaying = false;
    String? dialogPlayingItem;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    // Create service
    final freeSoundService = FreeSoundService();

    // State variables for search
    String searchQuery = '';
    List<FreeSoundItem> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false;

    // Add flag to track if initial search was done
    bool initialSearchPerformed = false;

    // Updated duration filter (10 seconds to 5 minutes)
    const String durationFilter = 'duration:[10 TO 300]';

    // Sort by highest rating
    const String sortOrder = 'rating_desc';

    // Add this inside _showFreeSoundSelectionDialog before showDialog
    dialogAudioPlayer.playerStateStream.listen((playerState) {
      // This avoids setState calls from the main widget's listener
      isDialogPlaying = playerState.playing;
    });

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Get screen size for responsive design
              final size = MediaQuery.of(context).size;

              // Search functionality
              Future<void> searchSounds() async {
                setState(() {
                  isSearching = true;
                  hasSearched = true;
                });

                try {
                  final results = await freeSoundService.searchSounds(
                    searchQuery.trim().isEmpty ? "music" : searchQuery.trim(),
                    page: 1,
                    pageSize: 20,
                    filter: durationFilter,
                    sort: sortOrder,
                    fields:
                        'id,name,username,previews,duration,license,tags,images,avg_rating',
                  );

                  setState(() {
                    searchResults = results;
                    isSearching = false;
                  });
                } catch (e) {
                  setState(() {
                    searchResults = [];
                    isSearching = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error searching sounds: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              // Only perform initial search once
              if (!initialSearchPerformed) {
                initialSearchPerformed = true;
                // Use post-frame callback to ensure the dialog is fully built
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) searchSounds();
                });
              }

              // Create a dialog-specific preview function
              Future<void> previewDialogSound(
                String previewUrl,
                String soundName,
              ) async {
                if (isDialogPlaying && dialogPlayingItem == previewUrl) {
                  // If this item is currently playing, stop it
                  await dialogAudioPlayer.stop();
                  setState(() {
                    dialogPlayingItem = null;
                    isDialogPlaying = false;
                  });
                } else {
                  try {
                    // Stop any currently playing audio
                    await dialogAudioPlayer.stop();

                    setState(() {
                      dialogPlayingItem = previewUrl;
                      isDialogPlaying =
                          false; // set false initially, will be true when playback starts
                    });

                    // Play the preview URL
                    await dialogAudioPlayer.setUrl(previewUrl);
                    await dialogAudioPlayer.play();

                    // Update playing status after successful playback
                    setState(() {
                      isDialogPlaying = true;
                    });

                    // Show playing notification
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Now playing: $soundName'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    // Handle error...
                  }
                }
              }

              return PopScope(
                canPop: true,
                onPopInvoked: (didPop) async {
                  await dialogAudioPlayer.stop();
                },
                child: Dialog(
                  backgroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: min(size.width * 0.9, 500),
                      maxHeight: min(size.height * 0.8, 600),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDarkMode
                                    ? accentColor.withValues(alpha: 0.2)
                                    : accentColor.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Select Sound for $behaviour',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        // Content area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Column(
                              children: [
                                // Search field
                                _buildSearchField(
                                  isDarkMode,
                                  accentColor,
                                  textColor,
                                  searchQuery,
                                  (value) => searchQuery = value,
                                  searchSounds,
                                ),

                                const SizedBox(height: 8),
                                Divider(
                                  color:
                                      isDarkMode
                                          ? AppColors.greyBlue.withAlpha(100)
                                          : AppColors.grey.withAlpha(100),
                                ),
                                const SizedBox(height: 8),

                                // Results
                                Expanded(
                                  child: _buildSearchResults(
                                    isSearching,
                                    hasSearched,
                                    searchResults,
                                    isDarkMode,
                                    accentColor,
                                    textColor,
                                    context,
                                    viewModel,
                                    behaviour,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Actions
                        Divider(height: 1, thickness: 0.5),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  dialogAudioPlayer.stop();
                                  freeSoundService.dispose();
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? AppColors.greyBlue
                                              : AppColors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // Search field component
  Widget _buildSearchField(
    bool isDarkMode,
    Color accentColor,
    Color textColor,
    String searchQuery,
    Function(String) onChanged,
    VoidCallback onSearch,
  ) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Search sounds...',
              hintStyle: TextStyle(
                color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: accentColor),
              contentPadding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true, // Make the input field more compact
            ),
            onChanged: onChanged,
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 8),
        // Search button
        ElevatedButton(
          onPressed: onSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Search',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Search results component - update the no results message
  Widget _buildSearchResults(
    bool isSearching,
    bool hasSearched,
    List<FreeSoundItem> searchResults,
    bool isDarkMode,
    Color accentColor,
    Color textColor,
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.darkGrey.withAlpha(30)
                : AppColors.lightGrey.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          isSearching
              ? const Center(child: CircularProgressIndicator())
              : !hasSearched
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 40,
                      color:
                          isDarkMode ? AppColors.greyBlue : AppColors.lightGrey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Search for sounds',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : searchResults.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.not_interested,
                      size: 36,
                      color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sounds found',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Try different keywords.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDarkMode ? AppColors.greyBlue : AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final sound = searchResults[index];
                  return _buildCompactSoundListItem(
                    context,
                    sound,
                    isDarkMode,
                    accentColor,
                    textColor,
                    viewModel,
                    behaviour,
                    () {
                      // Handle selection
                      final soundName = sound.name;
                      final previewUrl = sound.previewsHqMp3.toString();

                      // Cache the preview URL
                      FreeSoundService.cachePreviewUrl(behaviour, previewUrl);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$soundName selected'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    () {
                      // Preview sound
                      _previewFreeSoundAudio(
                        sound.previewsHqMp3.toString(),
                        sound.name,
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildCompactSoundListItem(
    BuildContext context,
    FreeSoundItem sound,
    bool isDarkMode,
    Color accentColor,
    Color textColor,
    AlertViewModel viewModel,
    String behaviour,
    VoidCallback onSelect,
    VoidCallback onPreview, {
    bool isPlaying = false,
  }) {
    // Format duration for display
    final duration =
        sound.duration.inMinutes > 0
            ? '${sound.duration.inMinutes}:${(sound.duration.inSeconds % 60).toString().padLeft(2, '0')}'
            : '0:${sound.duration.inSeconds.toString().padLeft(2, '0')}';

    // Get rating
    final rating = sound.avgRating ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              isDarkMode
                  ? AppColors.greyBlue.withValues(alpha: 0.1)
                  : AppColors.lightGrey,
          width: 1,
        ),
      ),
      color:
          isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.2) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sound.name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 10, color: Colors.amber),
                            Text(
                              " ${rating.toStringAsFixed(1)}",
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isDarkMode
                                        ? AppColors.greyBlue
                                        : AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'By ${sound.username}',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.greyBlue
                                      : AppColors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          duration,
                          style: TextStyle(fontSize: 10, color: accentColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: Icon(
                  isPlaying ? Icons.stop_circle : Icons.play_circle,
                  color: accentColor,
                  size: 22,
                ),
                onPressed: onPreview,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 22),
                onPressed: () {
                  viewModel.updatePlaylist(
                    behaviour,
                    sound.name,
                    sound.previewsHqMp3.toString(),
                  );
                  onSelect();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playOrPauseAudio(String behaviour, String path) async {
    if (_isPlaying && _currentPlayingItem == behaviour) {
      // If this item is currently playing, pause it
      await _audioPlayer.pause();
      setState(() {
        _currentPlayingItem = null;
      });
    } else {
      // If not playing or another item is playing, play this one
      setState(() {
        _currentPlayingItem = behaviour;
      });

      try {
        // Stop any currently playing audio
        await _audioPlayer.stop();

        // Determine what to play based on alert type
        if (widget.alertTypeName == 'Audio') {
          await _audioPlayer.setAsset(defaultAudioFiles[behaviour]['path']);
        } else if (widget.alertTypeName == 'Self-Configured Audio') {
          if (path.isNotEmpty) {
            await _audioPlayer.setUrl(path);
          } else {
            throw Exception('No audio URL available for this behavior');
          }
        } else {
          if (path.isNotEmpty) {
            await _audioPlayer.setUrl(path);
          } else {
            throw Exception('No audio URL available for this behavior');
          }
        }

        await _audioPlayer.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _previewFreeSoundAudio(
    String previewUrl,
    String soundName,
  ) async {
    if (_isPlaying && _currentPlayingItem == previewUrl) {
      // If this item is currently playing, stop it
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingItem = null;
      });
    } else {
      // If not playing or another item is playing, play this one
      setState(() {
        _currentPlayingItem = previewUrl;
      });

      try {
        // Stop any currently playing audio
        await _audioPlayer.stop();

        // Play the preview URL
        await _audioPlayer.setUrl(previewUrl);
        await _audioPlayer.play();

        // Show playing notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now playing: $soundName'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
