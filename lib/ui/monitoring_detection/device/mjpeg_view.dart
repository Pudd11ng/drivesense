import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MJPEGView extends StatefulWidget {
  final String streamUrl;
  final bool showLiveIcon;

  const MJPEGView({
    Key? key,
    required this.streamUrl,
    this.showLiveIcon = false,
  }) : super(key: key);

  @override
  State<MJPEGView> createState() => _MJPEGViewState();
}

class _MJPEGViewState extends State<MJPEGView> {
  StreamController<Uint8List>? _streamController;
  http.Client? _httpClient;
  Uint8List? _latestFrame;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  void didUpdateWidget(MJPEGView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _restartStream();
    }
  }

  void _startStream() async {
    _stopStream();

    _streamController = StreamController<Uint8List>();
    _httpClient = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await _httpClient!.send(request);

      final stream = response.stream;
      final completer = Completer<void>();

      // Process the multipart MJPEG stream
      List<int> buffer = [];
      int boundaryIndex = -1;

      stream.listen(
        (List<int> chunk) {
          buffer.addAll(chunk);

          if (boundaryIndex < 0) {
            // Find boundary in the first chunk
            final boundaryBytes = '\r\n\r\n'.codeUnits;
            for (int i = 0; i < buffer.length - 4; i++) {
              if (buffer[i] == boundaryBytes[0] &&
                  buffer[i + 1] == boundaryBytes[1] &&
                  buffer[i + 2] == boundaryBytes[2] &&
                  buffer[i + 3] == boundaryBytes[3]) {
                boundaryIndex = i + 4;
                break;
              }
            }
          }

          if (boundaryIndex >= 0) {
            // Try to extract JPEG frames
            int frameStart = -1;
            for (int i = boundaryIndex; i < buffer.length - 1; i++) {
              if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
                frameStart = i;
                break;
              }
            }

            if (frameStart >= 0) {
              // Find JPEG end marker
              int frameEnd = -1;
              for (int i = frameStart + 2; i < buffer.length - 1; i++) {
                if (buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
                  frameEnd = i + 2;
                  break;
                }
              }

              if (frameEnd > 0) {
                // Extract JPEG frame
                final frameBytes = Uint8List.fromList(
                  buffer.sublist(frameStart, frameEnd),
                );

                // Store latest frame
                _latestFrame = frameBytes;

                // Add to stream for display
                if (!_streamController!.isClosed) {
                  _streamController!.add(frameBytes);
                }

                // Keep data after this frame
                buffer = buffer.sublist(frameEnd);
                boundaryIndex = -1; // Reset to find next boundary
              }
            }
          }

          // Limit buffer size
          if (buffer.length > 1024 * 1024) {
            buffer = buffer.sublist(buffer.length - 1024 * 1024);
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Error starting MJPEG stream: $e');
    }
  }

  void _stopStream() {
    _httpClient?.close();
    _httpClient = null;
    _streamController?.close();
    _streamController = null;
  }

  void _restartStream() {
    _stopStream();
    _startStream();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // MJPEG stream display
        StreamBuilder<Uint8List>(
          stream: _streamController?.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Stream error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final imageBytes = snapshot.data!;

            return Image.memory(
              imageBytes,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            );
          },
        ),

        // Live indicator
        if (widget.showLiveIcon)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}