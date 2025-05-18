import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

final List<String> behaviours = [
  'Drowsiness',
  'Distraction',
  'Intoxication',
  'Distress',
  'Phone Usage',
];

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
    Provider.of<AlertViewModel>(context, listen: false).loadAlertData();

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
            onLeadingPressed: () => context.pop(),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getHeaderIcon(),
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Configure Alert Sounds',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getHeaderDescription(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBehaviorsList(viewModel, isDarkMode, accentColor),
              ],
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

  Widget _buildBehaviorsList(AlertViewModel viewModel, bool isDarkMode, Color accentColor) {
    final containerColor = isDarkMode ? AppColors.darkBlue.withAlpha(150) : accentColor;
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackTransparent.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: behaviours.length,
          separatorBuilder: (context, index) => Divider(
            color: AppColors.white.withAlpha(60),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final behaviour = behaviours[index];
            return _buildBehaviorItem(context, viewModel, behaviour, isDarkMode);
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
  ) {
    String? file;

    if (widget.alertTypeName == 'Audio') {
      file = viewModel.alert.audioFilePath[behaviour];
    } else if (widget.alertTypeName == 'Self-Configured Audio') {
      file = viewModel.alert.audioFilePath[behaviour];
    } else {
      file = viewModel.alert.musicPlayList[behaviour];
    }

    bool isThisItemPlaying = _isPlaying && _currentPlayingItem == behaviour;
    String displayName = file ?? 'No file selected';
    
    // Truncate long file names
    if (displayName.length > 20) {
      displayName = '${displayName.substring(0, 17)}...';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getBehaviorIcon(behaviour),
          color: AppColors.white,
          size: 22,
        ),
      ),
      title: Text(
        behaviour,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        displayName,
        style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file != null)
            IconButton(
              icon: Icon(
                isThisItemPlaying ? Icons.stop : Icons.play_arrow,
                color: AppColors.white,
              ),
              onPressed: () => _playOrPauseAudio(behaviour, file!),
            ),
          IconButton(
            icon: Icon(
              _getActionIconForAlertType(file),
              color: AppColors.white,
            ),
            onPressed: () {
              _showFileSelectionDialog(context, viewModel, behaviour);
            },
          ),
        ],
      ),
      onTap: () {
        _showFileSelectionDialog(context, viewModel, behaviour);
      },
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
      case 'Distress':
        return Icons.sentiment_very_dissatisfied;
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
        _playOrPauseAudio(behaviour, 'audio.mp3');
        break;
      case 'Self-Configured Audio':
        _showAudioFilePickerDialog(context, viewModel, behaviour);
        break;
      case 'Music':
        _showSpotifyMusicSelectionDialog(context, viewModel, behaviour);
        break;
    }
  }

  void _showAudioFilePickerDialog(
    BuildContext methodContext,
    AlertViewModel viewModel,
    String behaviour,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && mounted) {
        String fileName = result.files.single.name;
        // Update the viewModel
        // viewModel.updateAudioFile(behaviour, fileName);

        // Use the STATE'S context (this.context), not the parameter context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file "$fileName" selected for $behaviour'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting audio file'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSpotifyMusicSelectionDialog(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Select Music for $behaviour',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400, // Fixed height
              child: Column(
                children: [
                  // Search field
                  TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(color: isDarkMode ? AppColors.greyBlue : AppColors.grey),
                      prefixIcon: Icon(Icons.search, color: accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? AppColors.greyBlue : AppColors.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? AppColors.greyBlue : AppColors.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? AppColors.darkGrey.withAlpha(50) : AppColors.lightGrey.withAlpha(50),
                    ),
                    onChanged: (value) {
                      // In a real implementation, this would trigger Spotify API search
                    },
                  ),
                  const SizedBox(height: 16),

                  // Song list
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        itemCount: _getMockSpotifySongs().length,
                        itemBuilder: (context, index) {
                          final song = _getMockSpotifySongs()[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.darkGrey.withAlpha(80) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? AppColors.greyBlue.withAlpha(80) : AppColors.lightGrey,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  song['imageUrl']!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, obj, st) => Container(
                                    width: 50,
                                    height: 50,
                                    color: isDarkMode ? AppColors.darkGrey : AppColors.lightGrey,
                                    child: Icon(Icons.music_note, color: accentColor),
                                  ),
                                ),
                              ),
                              title: Text(
                                song['title']!,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                song['artist']!,
                                style: TextStyle(
                                  color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.play_circle_outline, color: accentColor),
                                onPressed: () {
                                  // Preview song
                                },
                              ),
                              onTap: () {
                                // Update viewModel with selected song
                                // viewModel.updateMusicFile(behaviour, song['title']);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${song['title']} selected for $behaviour',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playOrPauseAudio(String behaviour, String fileName) async {
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
          // For Audio type, play a default alert sound
          await _audioPlayer.setAsset('assets/audio/$fileName');
        } else if (widget.alertTypeName == 'Self-Configured Audio') {
          // For Self-Configured Audio, we'd play the actual file
          // This is a placeholder - in production you'd use the real file path
          await _audioPlayer.setAsset('assets/audio/custom/$fileName');
        } else {
          // For Music, use a sample URL for demo purposes
          await _audioPlayer.setUrl(
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          );
        }

        await _audioPlayer.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    }
  }

  List<Map<String, String>> _getMockSpotifySongs() {
    return [
      {
        'title': 'Blinding Lights',
        'artist': 'The Weeknd',
        'imageUrl':
            'https://i.scdn.co/image/ab67616d00001e02ef10c1c5ed9ab0ca3075d32a',
      },
      {
        'title': 'Shape of You',
        'artist': 'Ed Sheeran',
        'imageUrl':
            'https://i.scdn.co/image/ab67616d00001e02ba5db46f4b838ef6027e6f96',
      },
      {
        'title': 'Dance Monkey',
        'artist': 'Tones and I',
        'imageUrl':
            'https://i.scdn.co/image/ab67616d00001e0219d75a25736361d4d189b9a5',
      },
      {
        'title': 'Someone You Loved',
        'artist': 'Lewis Capaldi',
        'imageUrl':
            'https://i.scdn.co/image/ab67616d00001e02fc2101e6889d6ce9025f85f2',
      },
      {
        'title': 'Bad Guy',
        'artist': 'Billie Eilish',
        'imageUrl':
            'https://i.scdn.co/image/ab67616d00001e0227cc5269e0e81adb1afce268',
      },
    ];
  }
}
