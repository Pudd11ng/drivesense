import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:ultralytics_yolo/yolo.dart';

class MJPEGView extends StatefulWidget {
  final String streamUrl;
  final bool showLiveIcon;


  const MJPEGView({
    super.key,
    required this.streamUrl,
    this.showLiveIcon = false,
  });

  @override
  State<MJPEGView> createState() => _MJPEGViewState();
}

class _MJPEGViewState extends State<MJPEGView> {
  StreamController<Uint8List>? _streamController;
  http.Client? _httpClient;
  InputImage? _inputImage;

  // Add these variables for face mesh
  List<FaceMesh> _faceMeshes = [];
  bool _isProcessing = false;
  Size _imageSize = Size.zero;

  // YOLO variables
  YOLO? _yolo;
  List<YOLOResult> _yoloResults = [];
  bool _yoloInitialized = false;
  // int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeYolo();
    _startStream();
  }

  Future<void> _initializeYolo() async {
    try {
      // Initialize with a smaller model for better performance
      _yolo = YOLO(modelPath: 'dangerous_driving_behaviours', task: YOLOTask.detect);
      final loaded = await _yolo!.loadModel();
      if (loaded) {
        setState(() {
          _yoloInitialized = true;
        });
        debugPrint('YOLO model loaded successfully');
      } else {
        debugPrint('Failed to load YOLO model');
      }
    } catch (e) {
      debugPrint('Error initializing YOLO: $e');
    }
  }

  @override
  void dispose() {
    _stopStream();
    _yolo = null; // YOLO has no explicit dispose method
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

      final meshDetector = FaceMeshDetector(
        option: FaceMeshDetectorOptions.faceMesh,
      );

      stream.listen(
        (List<int> chunk) async {
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

                // Process with face detection first, then YOLO
                if (!_isProcessing) {
                  _processImage(frameBytes, meshDetector).then((_) {
                    // Only run YOLO if face was detected (driver present)
                    if (_faceMeshes.isNotEmpty && _yoloInitialized 
                    // && _frameCounter % 5 == 0
                    ) {
                      _processWithYolo(frameBytes);
                    }
                  });
                }
                
                // _frameCounter++;

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

  Future<void> _processImage(
    Uint8List frameBytes,
    FaceMeshDetector detector,
  ) async {
    _isProcessing = true;

    try {
      // Decode JPEG to get image and dimensions
      final codec = await ui.instantiateImageCodec(frameBytes);
      final frameImage = await codec.getNextFrame();
      final image = frameImage.image;

      // Update image size
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Convert to bytes in supported format (NV21 for Android)
      final bytes = await _convertImageToNv21(image);

      // Create input image with the right format
      _inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: _imageSize,
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // For NV21, bytesPerRow = width
        ),
      );

      // Process image
      final meshes = await detector.processImage(_inputImage!);

      if (mounted) {
        setState(() {
          _faceMeshes = meshes;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing face mesh: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  // Helper method to convert ui.Image to NV21 format
  Future<Uint8List> _convertImageToNv21(ui.Image image) async {
    // Get RGBA bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgbaBytes = byteData!.buffer.asUint8List();

    // Calculate NV21 size (12 bits per pixel)
    final int nv21Size = (image.width * image.height * 3) ~/ 2;
    final nv21Bytes = Uint8List(nv21Size);

    // Convert RGBA to NV21
    // Y plane
    int yIndex = 0;
    // UV plane
    int uvIndex = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int rgbaIndex = (y * image.width + x) * 4;

        // RGBA to YUV conversion
        final int r = rgbaBytes[rgbaIndex];
        final int g = rgbaBytes[rgbaIndex + 1];
        final int b = rgbaBytes[rgbaIndex + 2];

        // Y
        int yValue = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
        yValue = yValue.clamp(0, 255);
        nv21Bytes[yIndex++] = yValue;

        // UV (NV21 format, every 2x2 block)
        if (y % 2 == 0 && x % 2 == 0) {
          // V
          int vValue = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
          vValue = vValue.clamp(0, 255);
          nv21Bytes[uvIndex++] = vValue;

          // U
          int uValue = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
          uValue = uValue.clamp(0, 255);
          nv21Bytes[uvIndex++] = uValue;
        }
      }
    }

    return nv21Bytes;
  }

  Future<void> _processWithYolo(Uint8List frameBytes) async {
    if (!_yoloInitialized || _yolo == null) return;

    try {
      // Run YOLO inference on the frame
      final results = await _yolo!.predict(frameBytes);
      
      print('Raw YOLO results: $results'); // Print the raw results
      
      if (mounted && results.containsKey('boxes')) {
        final boxes = results['boxes'] as List;
        print('Raw boxes count: ${boxes.length}'); // Check count before processing
        
        if (boxes.isNotEmpty) {
          print('First box: ${boxes.first}');
          
          final typedResults = boxes.map((box) => 
            convertToYoloResult(box as Map<String, dynamic>)
          ).toList();
          
          setState(() {
            _yoloResults = typedResults;
          });

          print('YOLO detections: ${_yoloResults.length}');
        } else {
          // Clear previous results when no objects are detected
          setState(() {
            _yoloResults = [];
          });
          print('No objects detected in this frame');
        }
      } else {
        print('No boxes key in results: ${results.keys}'); // See what keys are available
      }
    } catch (e) {
      debugPrint('Error running YOLO detection: $e');
    }
  }

  YOLOResult convertToYoloResult(Map<String, dynamic> box) {
    // Get coordinates
    final x1 = box['x1'] as double;
    final y1 = box['y1'] as double;
    final x2 = box['x2'] as double;
    final y2 = box['y2'] as double;
    
    // Create bounding boxes
    final boundingBox = Rect.fromLTRB(x1, y1, x2, y2);
    final normalizedBox = Rect.fromLTRB(
      x1 / _imageSize.width, 
      y1 / _imageSize.height,
      x2 / _imageSize.width, 
      y2 / _imageSize.height
    );
    
    // Get class and confidence
    final className = box['class'] as String;
    final confidence = box['confidence'] as double;
    
    // Map class names to indices based on your model's class list
    int classIndex;
    switch (className) {
      case 'Bloodshot eyes': classIndex = 0; break;
      case 'Droopy eyelids': classIndex = 1; break;
      case 'Flushed skin': classIndex = 2; break;
      case 'awake': classIndex = 3; break;
      case 'distraction': classIndex = 4; break;
      case 'drowsy': classIndex = 5; break;
      case 'phone': classIndex = 6; break;
      case 'yawn': classIndex = 7; break;
      default: classIndex = 99; // unknown
    }
    
    return YOLOResult.new(
      classIndex: classIndex,
      className: className,
      confidence: confidence,
      boundingBox: boundingBox,
      normalizedBox: normalizedBox,
    );
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

        // Face mesh overlay
        if (_faceMeshes.isNotEmpty && _imageSize != Size.zero)
          CustomPaint(
            painter: FaceMeshPainter(
              faceMeshes: _faceMeshes,
              imageSize: _imageSize,
            ),
            size: MediaQuery.of(context).size,
          ),

        // YOLO detection overlay
        if (_yoloResults.isNotEmpty && _imageSize != Size.zero)
          CustomPaint(
            painter: YoloPainter(
              detections: _yoloResults,
              imageSize: _imageSize,
            ),
            size: MediaQuery.of(context).size,
          ),

        // Face detection status indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _faceMeshes.isNotEmpty ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _faceMeshes.isNotEmpty
                      ? 'Face: ${_faceMeshes.length}'
                      : 'No Face',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // YOLO detection status indicator
        Positioned(
          top: 40, // Position below face detection indicator
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _yoloResults.isNotEmpty ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _yoloResults.isNotEmpty
                      ? 'Objects: ${_yoloResults.length}'
                      : 'No Objects',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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

class FaceMeshPainter extends CustomPainter {
  final List<FaceMesh> faceMeshes;
  final Size imageSize;

  FaceMeshPainter({required this.faceMeshes, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (faceMeshes.isEmpty || imageSize == Size.zero) return;

    // Calculate scale to fit image in view
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double scale = math.min(scaleX, scaleY);

    // Calculate offset to center the image
    final double offsetX = (size.width - imageSize.width * scale) / 2;
    final double offsetY = (size.height - imageSize.height * scale) / 2;

    // Paints
    final pointPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;

    final contourPaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    for (final mesh in faceMeshes) {
      // Draw contours (face features)
      for (final contour in mesh.contours.entries) {
        final points = contour.value;
        if (points == null || points.isEmpty) continue;

        final path = Path();
        var firstPoint = true;

        for (final point in points) {
          final scaledX = offsetX + point.x * scale;
          final scaledY = offsetY + point.y * scale;

          if (firstPoint) {
            path.moveTo(scaledX, scaledY);
            firstPoint = false;
          } else {
            path.lineTo(scaledX, scaledY);
          }
        }

        canvas.drawPath(path, contourPaint);
      }

      // Draw points (selectively to avoid clutter)
      for (int i = 0; i < mesh.points.length; i += 10) {
        // Draw every 10th point
        final point = mesh.points[i];
        final scaledX = offsetX + point.x * scale;
        final scaledY = offsetY + point.y * scale;
        canvas.drawCircle(Offset(scaledX, scaledY), 2, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FaceMeshPainter oldDelegate) {
    return oldDelegate.faceMeshes != faceMeshes ||
        oldDelegate.imageSize != imageSize;
  }
}

class YoloPainter extends CustomPainter {
  final List<YOLOResult> detections;
  final Size imageSize;

  YoloPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageSize == Size.zero) return;

    // Calculate scale to fit image in view
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double scale = math.min(scaleX, scaleY);

    // Calculate offset to center the image
    final double offsetX = (size.width - imageSize.width * scale) / 2;
    final double offsetY = (size.height - imageSize.height * scale) / 2;

    // Paint for bounding boxes
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Text style for labels
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (final detection in detections) {
      // Get detection details using proper accessors
      final boundingBox = detection.boundingBox;  // Changed from box to boundingBox
      final confidence = detection.confidence;    // This was already correct
      final classIndex = detection.classIndex;    // Changed from classId to classIndex
      final className = detection.className;      // This was already correct
      
      // Skip low confidence detections
      if (confidence < 0.5) continue;

      // Convert coordinates to screen space using Rect properties
      final left = offsetX + boundingBox.left * scale;
      final top = offsetY + boundingBox.top * scale;
      final right = offsetX + boundingBox.right * scale;
      final bottom = offsetY + boundingBox.bottom * scale;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      
      // Assign different colors based on class index for better visualization
      final color = Colors.primaries[classIndex % Colors.primaries.length];
      boxPaint.color = color;
      
      // Draw bounding box
      canvas.drawRect(rect, boxPaint);
      
      // Prepare label text
      final labelText = '$className ${(confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(text: labelText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Draw label background
      canvas.drawRect(
        Rect.fromLTWH(left, top - textPainter.height - 4, textPainter.width + 8, textPainter.height + 4),
        Paint()..color = color,
      );
      
      // Draw label text
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant YoloPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize;
  }
}
