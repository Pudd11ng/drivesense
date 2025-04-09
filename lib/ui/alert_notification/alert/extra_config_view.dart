import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';

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

    @override
    void dispose() {
      _audioPlayer.dispose();
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.alertTypeName,
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                _buildBehaviorsList(viewModel),
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

  Widget _buildBehaviorsList(AlertViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: behaviours.length,
        itemBuilder: (context, index) {
          final behaviour = behaviours[index];
          return _buildBehaviorItem(context, viewModel, behaviour, index);
        },
      ),
    );
  }

  Widget _buildBehaviorItem(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
    int index,
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

    return Container(
      decoration: BoxDecoration(
        border:
            index != behaviours.length - 1
                ? const Border(
                  bottom: BorderSide(color: Colors.white24, width: 0.5),
                )
                : null,
      ),
      child: ListTile(
        title: Text(
          behaviour,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              file ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(_getIconForAlertType(file), color: Colors.white),
          ],
        ),
        onTap: () {
          _showFileSelectionDialog(context, viewModel, behaviour);
        },
      ),
    );
  }

  IconData _getIconForAlertType(String? file) {
    if (widget.alertTypeName == 'Audio') {
      return Icons.headphones;
    } else if (widget.alertTypeName == 'Self-Configured Audio') {
      return file != null ? Icons.headphones : Icons.upload_file;
    } else {
      return file != null ? Icons.headphones : Icons.upload_file;
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting audio file')),
        );
      }
    }
  }

  void _showSpotifyMusicSelectionDialog(
    BuildContext context,
    AlertViewModel viewModel,
    String behaviour,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Select Music for $behaviour'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search field
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search songs...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // In a real implementation, this would trigger Spotify API search
                          // setState(() { searchResults = ... });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Song list (popular songs or search results)
                      Expanded(
                        child: ListView(
                          children:
                              _getMockSpotifySongs().map((song) {
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      song['imageUrl']!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (ctx, obj, st) => Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.music_note),
                                          ),
                                    ),
                                  ),
                                  title: Text(song['title']!),
                                  subtitle: Text(song['artist']!),
                                  onTap: () {
                                    // Update viewModel with selected song
                                    // viewModel.updateMusicFile(behaviour, song['title']);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${song['title']} selected for $behaviour',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
          // await _audioPlayer.setAsset('assets/audio/custom/$fileName');
        } else {
          // For Music, play the Spotify preview URL (this is a placeholder)
          // In production, you'd get the actual streaming URL from Spotify API
          final song = _getMockSpotifySongs().firstWhere(
            (song) => song['title'] == fileName,
            orElse: () => {'preview_url': 'https://example.com/preview.mp3'},
          );

          // Use a sample URL for demo purposes
          await _audioPlayer.setUrl(
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          );
        }

        await _audioPlayer.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
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
