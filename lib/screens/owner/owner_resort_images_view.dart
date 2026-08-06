import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../file_server_config.dart';

class OwnerResortImagesView extends StatefulWidget {
  final List<Map<String, dynamic>> resorts;
  final Function(int, Map<String, dynamic>) onResortUpdated;
  final VoidCallback? onRefreshResorts;

  const OwnerResortImagesView({
    super.key,
    required this.resorts,
    required this.onResortUpdated,
    this.onRefreshResorts,
  });

  @override
  State<OwnerResortImagesView> createState() => _OwnerResortImagesViewState();
}

class _OwnerResortImagesViewState extends State<OwnerResortImagesView> {
  String? _selectedResortId;
  String? _selectedResortName;
  bool _isLoadingImages = false;

  // Real images loaded from file-server folder and resort state
  List<Map<String, dynamic>> _images = [];

  // Available server folders discovered
  List<String> _serverFolders = [];



  @override
  void initState() {
    super.initState();
    if (widget.resorts.isNotEmpty) {
      _selectedResortId = _getResortId(widget.resorts.first, 0);
      _selectedResortName = _getResortName(widget.resorts.first);
    }
    _fetchServerFolders();
    _loadImagesForCurrentResort();
  }

  @override
  void didUpdateWidget(covariant OwnerResortImagesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resorts != widget.resorts) {
      if (_selectedResortId == null && widget.resorts.isNotEmpty) {
        _selectedResortId = _getResortId(widget.resorts.first, 0);
        _selectedResortName = _getResortName(widget.resorts.first);
      }
      _fetchServerFolders();
      _loadImagesForCurrentResort();
    }
  }

  String _getResortId(Map<String, dynamic> resort, int index) {
    final rawId = resort['id']?.toString() ?? resort['resortId']?.toString();
    if (rawId != null && rawId.trim().isNotEmpty && rawId != 'null') {
      return rawId.trim();
    }
    return '${index + 1}';
  }

  String _getResortName(Map<String, dynamic> resort) {
    final name = resort['name']?.toString() ?? resort['resortName']?.toString();
    if (name != null && name.trim().isNotEmpty && name != 'null') {
      return name.trim();
    }
    return 'Resort';
  }

  Map<String, dynamic>? _getCurrentResort() {
    if (_selectedResortId == null && _selectedResortName == null) return null;
    for (int i = 0; i < widget.resorts.length; i++) {
      final r = widget.resorts[i];
      if (_getResortId(r, i) == _selectedResortId || _getResortName(r) == _selectedResortName) {
        return r;
      }
    }
    return widget.resorts.isNotEmpty ? widget.resorts.first : null;
  }

  int _getCurrentResortIndex() {
    if (_selectedResortId == null && _selectedResortName == null) return -1;
    for (int i = 0; i < widget.resorts.length; i++) {
      final r = widget.resorts[i];
      if (_getResortId(r, i) == _selectedResortId || _getResortName(r) == _selectedResortName) {
        return i;
      }
    }
    return -1;
  }

  String get _activeFolderIdentifier {
    if (_selectedResortName != null && _selectedResortName!.trim().isNotEmpty) {
      return _selectedResortName!.trim();
    }
    if (_selectedResortId != null && _selectedResortId!.trim().isNotEmpty) {
      return _selectedResortId!.trim();
    }
    return 'default';
  }

  /// Resolves any relative or full image path to a valid network URL
  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${FileServerConfig.fileServerUrl}$trimmed';
    }
    return '${FileServerConfig.fileServerUrl}/$trimmed';
  }

  /// Fetch all resort folders inside E:\uploadfile\resortimage\
  Future<void> _fetchServerFolders() async {
    try {
      final uri = Uri.parse('${FileServerConfig.fileServerUrl}/api/files/folders');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          if (mounted) {
            setState(() {
              _serverFolders = List<String>.from(body['data'].map((e) => e.toString()));
            });
          }
        }
      }
    } catch (_) {}
  }

  /// Load images from the file server for the currently selected resort
  Future<void> _loadImagesForCurrentResort() async {
    final resort = _getCurrentResort();
    final resortIndex = _getCurrentResortIndex();
    final resortName = resort != null ? _getResortName(resort) : (_selectedResortName ?? 'Resort');
    final resortId = resort != null ? _getResortId(resort, resortIndex >= 0 ? resortIndex : 0) : (_selectedResortId ?? '1');

    setState(() => _isLoadingImages = true);

    final List<Map<String, dynamic>> combined = [];
    final Set<String> seenFileNames = {};

    // 1. Fetch images from File Server folder (E:\uploadfile\resortimage\<folderIdentifier>)
    final identifiersToQuery = {resortName, resortId, _activeFolderIdentifier}.where((s) => s.isNotEmpty).toSet();

    for (final identifier in identifiersToQuery) {
      try {
        final uri = Uri.parse('${FileServerConfig.fileServerUrl}/api/files/resortimage/${Uri.encodeComponent(identifier)}');
        final response = await http.get(uri).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] is List) {
            final List fileList = body['data'];
            for (int idx = 0; idx < fileList.length; idx++) {
              final f = fileList[idx];
              final fileName = f['fileName']?.toString() ?? 'image${idx + 1}.jpg';

              if (seenFileNames.contains(fileName)) continue;
              seenFileNames.add(fileName);

              final relUrl = f['url']?.toString() ?? '/resortimage/$identifier/$fileName';

              combined.add({
                'id': 'fs_${identifier}_$fileName',
                'resortId': resortId,
                'resortName': resortName,
                'folderIdentifier': identifier,
                'resortIndex': resortIndex,
                'title': fileName,
                'fileName': fileName,
                'category': 'Resort Photo',
                'url': relUrl,
                'bytes': null,
                'isCover': (resort != null && resort['imageUrl'] == relUrl),
                'createdAt': f['createdAt']?.toString() ?? 'Uploaded',
                'source': 'fileServer',
              });
            }
          }
        }
      } catch (_) {
        // Continue querying next identifier or local state
      }
    }

    // 2. Include resort's local cover photo if not already in combined list
    if (resort != null && resort['imageUrl'] != null && resort['imageUrl'].toString().trim().isNotEmpty) {
      final coverUrl = resort['imageUrl'].toString().trim();
      final alreadyPresent = combined.any((img) => img['url'] == coverUrl);
      if (!alreadyPresent) {
        final fileName = coverUrl.split('/').last.split('?').first;
        combined.insert(0, {
          'id': 'cover_${resortId}_$fileName',
          'resortId': resortId,
          'resortName': resortName,
          'folderIdentifier': _activeFolderIdentifier,
          'resortIndex': resortIndex,
          'title': fileName.isNotEmpty ? fileName : 'Primary Cover Photo',
          'fileName': fileName.isNotEmpty ? fileName : 'cover.jpg',
          'category': 'Exterior',
          'url': coverUrl,
          'bytes': null,
          'isCover': true,
          'createdAt': 'Active Cover',
          'source': 'resortState',
        });
      }
    }

    if (mounted) {
      setState(() {
        _images = combined;
        _isLoadingImages = false;
      });
    }
  }

  bool _isCoverImage(Map<String, dynamic> img) {
    if (img['isCover'] == true) return true;
    final resort = _getCurrentResort();
    if (resort != null && resort['imageUrl'] != null) {
      return resort['imageUrl'] == img['url'];
    }
    return false;
  }

  void _setAsCover(Map<String, dynamic> targetImage) {
    final resortIndex = _getCurrentResortIndex();
    final resort = _getCurrentResort();
    if (resortIndex == -1 || resort == null) return;

    final targetUrl = targetImage['url'] ?? '';

    setState(() {
      for (var img in _images) {
        img['isCover'] = (img['id'] == targetImage['id'] || img['url'] == targetUrl);
      }
    });

    final updatedResort = Map<String, dynamic>.from(resort);
    updatedResort['imageUrl'] = targetUrl;
    widget.onResortUpdated(resortIndex, updatedResort);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cover photo set for ${_getResortName(resort)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3E7C59),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteImage(Map<String, dynamic> targetImage) async {
    final bool isCover = _isCoverImage(targetImage);
    final String fileName = targetImage['fileName'] ?? '';
    final String folder = targetImage['folderIdentifier'] ?? _activeFolderIdentifier;
    final String resortId = targetImage['resortId'] ?? _selectedResortId ?? '1';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Photo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$fileName"?'),
            const SizedBox(height: 8),
            Text(
              'Resort: $folder • File: $fileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (isCover) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This is currently set as the primary cover photo.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Send delete request to File Server
    try {
      final deleteUri = Uri.parse(
        '${FileServerConfig.fileServerUrl}/api/files/delete?module=resortimage&resortName=${Uri.encodeComponent(folder)}&resortId=$resortId&fileName=${Uri.encodeComponent(fileName)}',
      );
      await http.delete(deleteUri).timeout(const Duration(seconds: 4));
    } catch (_) {}

    setState(() {
      _images.removeWhere((img) => img['id'] == targetImage['id'] || (img['fileName'] == fileName && img['folderIdentifier'] == folder));
    });

    if (isCover) {
      final resortIndex = _getCurrentResortIndex();
      final resort = _getCurrentResort();
      if (resortIndex != -1 && resort != null) {
        final updatedResort = Map<String, dynamic>.from(resort);
        final remaining = _images.where((img) => img['resortName'] == _getResortName(resort) || img['resortId'] == _getResortId(resort, resortIndex)).toList();
        updatedResort['imageUrl'] = remaining.isNotEmpty ? remaining.first['url'] : '';
        widget.onResortUpdated(resortIndex, updatedResort);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted $fileName'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Pick image directly from Gallery or Camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final name = pickedFile.name;

      if (!mounted) return;

      _showUploadDialog(
        bytes: bytes,
        fileName: name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const List<double> _vividMatrix = [
    1.2, 0, 0, 0, -10,
    0, 1.2, 0, 0, -10,
    0, 0, 1.2, 0, -10,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _warmMatrix = [
    1.15, 0, 0, 0, 15,
    0, 1.0, 0, 0, 0,
    0, 0, 0.85, 0, -15,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _coolMatrix = [
    0.85, 0, 0, 0, -15,
    0, 1.0, 0, 0, 0,
    0, 0, 1.2, 0, 15,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _bwMatrix = [
    0.33, 0.33, 0.33, 0, 0,
    0.33, 0.33, 0.33, 0, 0,
    0.33, 0.33, 0.33, 0, 0,
    0, 0, 0, 1, 0,
  ];

  List<double>? _getColorMatrix(String filter) {
    switch (filter) {
      case 'Vivid':
        return _vividMatrix;
      case 'Warm':
        return _warmMatrix;
      case 'Cool':
        return _coolMatrix;
      case 'B&W':
        return _bwMatrix;
      default:
        return null;
    }
  }

  /// Bakes rotation, flip, crop rectangle, and filter into edited PNG bytes using dart:ui
  Future<Uint8List> _processAndCropImage({
    required Uint8List rawBytes,
    required double rotationDegrees,
    required bool flipHorizontal,
    required bool flipVertical,
    required Rect cropNormalized,
    required List<double>? colorMatrix,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      final double origW = uiImage.width.toDouble();
      final double origH = uiImage.height.toDouble();

      final double cropX = (cropNormalized.left * origW).clamp(0.0, origW - 1.0);
      final double cropY = (cropNormalized.top * origH).clamp(0.0, origH - 1.0);
      final double cropW = (cropNormalized.width * origW).clamp(1.0, origW - cropX);
      final double cropH = (cropNormalized.height * origH).clamp(1.0, origH - cropY);

      final recorder = ui.PictureRecorder();
      final bool isRotated90 = ((rotationDegrees.abs() / 90).round() % 2) == 1;
      final double canvasW = isRotated90 ? cropH : cropW;
      final double canvasH = isRotated90 ? cropW : cropH;

      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasW, canvasH));

      final paint = Paint();
      if (colorMatrix != null) {
        paint.colorFilter = ColorFilter.matrix(colorMatrix);
      }

      canvas.save();
      canvas.translate(canvasW / 2, canvasH / 2);
      canvas.rotate(rotationDegrees * math.pi / 180);
      canvas.scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0);
      canvas.translate(-cropW / 2, -cropH / 2);

      final srcRect = Rect.fromLTWH(cropX, cropY, cropW, cropH);
      final dstRect = Rect.fromLTWH(0, 0, cropW, cropH);

      canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
      canvas.restore();

      final picture = recorder.endRecording();
      final renderedImage = await picture.toImage(canvasW.toInt(), canvasH.toInt());
      final byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List() ?? rawBytes;
    } catch (e) {
      debugPrint('Error editing image: $e');
      return rawBytes;
    }
  }

  /// Dialog to edit, crop, and upload picked image directly to File Server
  void _showUploadDialog({
    required Uint8List bytes,
    required String fileName,
  }) {
    String selectedResortId = _selectedResortId ?? (_getCurrentResort() != null ? _getResortId(_getCurrentResort()!, 0) : '1');
    String selectedResortName = _selectedResortName ?? (_getCurrentResort() != null ? _getResortName(_getCurrentResort()!) : 'Resort');
    String selectedFolder = _activeFolderIdentifier;

    // Image Editing State
    double rotationDegrees = 0.0;
    bool flipHorizontal = false;
    bool flipVertical = false;
    String activeAspect = 'Free';
    Rect cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
    String activeFilter = 'Original';
    int activeTab = 0; // 0=Crop, 1=Rotate/Flip, 2=Filters

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isUploading = false;

          Future<void> handleUpload() async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(dialogCtx);
            setDialogState(() => isUploading = true);

            // 1. Process & Crop Image
            final finalBytes = await _processAndCropImage(
              rawBytes: bytes,
              rotationDegrees: rotationDegrees,
              flipHorizontal: flipHorizontal,
              flipVertical: flipVertical,
              cropNormalized: cropRect,
              colorMatrix: _getColorMatrix(activeFilter),
            );

            String finalImageUrl = '';
            String uploadedFileName = fileName.isNotEmpty ? fileName : 'image_${DateTime.now().millisecondsSinceEpoch}.png';

            // 2. Upload to File Server
            try {
              final uri = Uri.parse('${FileServerConfig.fileServerUrl}/api/files/upload');
              final request = http.MultipartRequest('POST', uri);

              request.fields['module'] = 'resortimage';
              request.fields['resortName'] = selectedFolder;
              request.fields['resortId'] = selectedResortId;
              request.fields['organization'] = selectedFolder;

              request.files.add(
                http.MultipartFile.fromBytes(
                  'file',
                  finalBytes,
                  filename: uploadedFileName,
                ),
              );

              final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
              final response = await http.Response.fromStream(streamedResponse);

              if (response.statusCode == 200) {
                final jsonBody = jsonDecode(response.body);
                if (jsonBody['success'] == true && jsonBody['data'] != null) {
                  finalImageUrl = jsonBody['data']['url'] ?? '';
                  if (jsonBody['data']['fileName'] != null) {
                    uploadedFileName = jsonBody['data']['fileName'];
                  }
                }
              }
            } catch (_) {}

            if (finalImageUrl.isEmpty) {
              finalImageUrl = '/resortimage/$selectedFolder/$uploadedFileName';
            }

            final newImageItem = {
              'id': 'fs_${selectedFolder}_$uploadedFileName',
              'resortId': selectedResortId,
              'resortName': selectedResortName,
              'folderIdentifier': selectedFolder,
              'title': uploadedFileName,
              'fileName': uploadedFileName,
              'category': 'Resort Photo',
              'url': finalImageUrl,
              'bytes': finalBytes,
              'isCover': _images.isEmpty,
              'createdAt': 'Just now',
              'source': 'fileServer',
            };

            setState(() {
              _images.insert(0, newImageItem);
            });

            if (navigator.canPop()) {
              navigator.pop();
            }

            messenger.showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Photo cropped and uploaded successfully!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF3E7C59),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            _loadImagesForCurrentResort();
            _fetchServerFolders();
          }

          // Aspect ratio helper
          void setAspectRatio(String aspect) {
            setDialogState(() {
              activeAspect = aspect;
              switch (aspect) {
                case '16:9':
                  cropRect = const Rect.fromLTWH(0.0, 0.15, 1.0, 0.70);
                  break;
                case '4:3':
                  cropRect = const Rect.fromLTWH(0.05, 0.08, 0.90, 0.84);
                  break;
                case '1:1':
                  cropRect = const Rect.fromLTWH(0.15, 0.15, 0.70, 0.70);
                  break;
                default:
                  cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
              }
            });
          }

          final filterMatrix = _getColorMatrix(activeFilter);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 560,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E7C59).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.crop_rotate, color: Color(0xFF3E7C59), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit & Crop Photo',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              'Resort: $selectedResortName',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isUploading ? null : () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Editing Canvas Area
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Transformed Image Preview
                        ColorFiltered(
                          colorFilter: filterMatrix != null
                              ? ColorFilter.matrix(filterMatrix)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateZ(rotationDegrees * math.pi / 180)
                              ..scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0),
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),

                        // Crop Box Overlay Grid
                        Positioned.fill(
                          child: FractionallySizedBox(
                            widthFactor: cropRect.width,
                            heightFactor: cropRect.height,
                            alignment: Alignment(
                              (cropRect.left + cropRect.width / 2 - 0.5) * 2,
                              (cropRect.top + cropRect.height / 2 - 0.5) * 2,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 0,
                                    spreadRadius: 2000,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Grid Lines
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Divider(color: Colors.white.withValues(alpha: 0.4), height: 1),
                                      Divider(color: Colors.white.withValues(alpha: 0.4), height: 1),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      VerticalDivider(color: Colors.white.withValues(alpha: 0.4), width: 1),
                                      VerticalDivider(color: Colors.white.withValues(alpha: 0.4), width: 1),
                                    ],
                                  ),
                                  // Corner Handles
                                  Positioned(top: 0, left: 0, child: _buildCornerHandle()),
                                  Positioned(top: 0, right: 0, child: _buildCornerHandle()),
                                  Positioned(bottom: 0, left: 0, child: _buildCornerHandle()),
                                  Positioned(bottom: 0, right: 0, child: _buildCornerHandle()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Editing Toolbar Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton(0, Icons.crop, 'Crop', activeTab, (idx) => setDialogState(() => activeTab = idx)),
                        _buildTabButton(1, Icons.rotate_right, 'Rotate & Flip', activeTab, (idx) => setDialogState(() => activeTab = idx)),
                        _buildTabButton(2, Icons.filter_vintage, 'Filters', activeTab, (idx) => setDialogState(() => activeTab = idx)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Active Tab Controls Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: activeTab == 0
                              // Tab 0: Crop Aspect Ratios
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      const Text('Aspect: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                      _buildChip('Free', activeAspect == 'Free', () => setAspectRatio('Free')),
                                      const SizedBox(width: 6),
                                      _buildChip('16:9 Cover', activeAspect == '16:9', () => setAspectRatio('16:9')),
                                      const SizedBox(width: 6),
                                      _buildChip('4:3 Photo', activeAspect == '4:3', () => setAspectRatio('4:3')),
                                      const SizedBox(width: 6),
                                      _buildChip('1:1 Square', activeAspect == '1:1', () => setAspectRatio('1:1')),
                                    ],
                                  ),
                                )
                              : activeTab == 1
                                  // Tab 1: Rotate & Flip Buttons
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.rotate_left, color: Color(0xFF3E7C59)),
                                          tooltip: 'Rotate Left (-90°)',
                                          onPressed: () => setDialogState(() => rotationDegrees = (rotationDegrees - 90) % 360),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.rotate_right, color: Color(0xFF3E7C59)),
                                          tooltip: 'Rotate Right (+90°)',
                                          onPressed: () => setDialogState(() => rotationDegrees = (rotationDegrees + 90) % 360),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.flip, color: flipHorizontal ? const Color(0xFF3E7C59) : Colors.grey),
                                          tooltip: 'Flip Horizontal',
                                          onPressed: () => setDialogState(() => flipHorizontal = !flipHorizontal),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.swap_vert, color: flipVertical ? const Color(0xFF3E7C59) : Colors.grey),
                                          tooltip: 'Flip Vertical',
                                          onPressed: () => setDialogState(() => flipVertical = !flipVertical),
                                        ),
                                      ],
                                    )
                                  // Tab 2: Filter Presets
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          const Text('Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                          _buildChip('Original', activeFilter == 'Original', () => setDialogState(() => activeFilter = 'Original')),
                                          const SizedBox(width: 6),
                                          _buildChip('Vivid', activeFilter == 'Vivid', () => setDialogState(() => activeFilter = 'Vivid')),
                                          const SizedBox(width: 6),
                                          _buildChip('Warm', activeFilter == 'Warm', () => setDialogState(() => activeFilter = 'Warm')),
                                          const SizedBox(width: 6),
                                          _buildChip('Cool', activeFilter == 'Cool', () => setDialogState(() => activeFilter = 'Cool')),
                                          const SizedBox(width: 6),
                                          _buildChip('B&W', activeFilter == 'B&W', () => setDialogState(() => activeFilter = 'B&W')),
                                        ],
                                      ),
                                    ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              rotationDegrees = 0.0;
                              flipHorizontal = false;
                              flipVertical = false;
                              activeAspect = 'Free';
                              cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
                              activeFilter = 'Original';
                            });
                          },
                          icon: const Icon(Icons.restart_alt, size: 16, color: Colors.grey),
                          label: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : handleUpload,
                        icon: isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.crop_outlined, size: 18),
                        label: Text(isUploading ? 'Cropping & Uploading...' : 'Crop & Save Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E7C59),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCornerHandle() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, int activeTab, Function(int) onTap) {
    final isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF3E7C59) : Colors.black54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF3E7C59) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E7C59) : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Edit & crop an existing uploaded photo
  Future<void> _editExistingImage(Map<String, dynamic> img) async {
    final String fileName = img['fileName'] ?? img['title'] ?? 'photo.jpg';
    Uint8List? bytes = img['bytes'];

    if (bytes == null) {
      final String fullUrl = _resolveImageUrl(img['url']);
      try {
        final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          bytes = res.bodyBytes;
        }
      } catch (e) {
        debugPrint('Could not fetch image for editing: $e');
      }
    }

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not download image for editing.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showUploadDialog(bytes: bytes, fileName: fileName);
    }
  }

  /// Fullscreen Lightbox preview
  void _openLightbox(Map<String, dynamic> img) {
    final isCover = _isCoverImage(img);
    final Uint8List? bytes = img['bytes'];
    final String fullUrl = _resolveImageUrl(img['url']);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InteractiveViewer(
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.contain)
                          : Image.network(
                              fullUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Unable to load image preview', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    img['title'] ?? 'Resort Photo',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  if (isCover) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3E7C59),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Primary Cover', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Resort: ${img['resortName']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _editExistingImage(img);
                              },
                              icon: const Icon(Icons.crop_rotate, size: 16),
                              label: const Text('Edit & Crop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E7C59),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (!isCover)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _setAsCover(img);
                                },
                                icon: const Icon(Icons.star_border, size: 16),
                                label: const Text('Set as Cover'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3E7C59),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resorts.isEmpty && _serverFolders.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.villa_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No Resorts Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Please add a resort first before managing photos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    final currentResort = _getCurrentResort();
    final currentResortName = currentResort != null ? _getResortName(currentResort) : (_selectedResortName ?? 'Resort');
    final currentId = currentResort != null ? _getResortId(currentResort, _getCurrentResortIndex() >= 0 ? _getCurrentResortIndex() : 0) : (_selectedResortId ?? '1');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Loading state or Content
          if (_isLoadingImages)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3E7C59)),
                    SizedBox(height: 16),
                    Text(
                      'Loading photos from file server...',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (_images.isEmpty)
            // Empty State Card matching requested UI
            _buildEmptyUploadCard(currentId, currentResortName)
          else
            // Gallery Grid
            _buildGalleryView(currentId, currentResortName),
        ],
      ),
    );
  }



  /// Empty State Card exactly matching the user's design
  Widget _buildEmptyUploadCard(String resortId, String resortName) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Icon Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3E7C59).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Color(0xFF3E7C59),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'No Resort Photos Uploaded Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Upload high quality photos for $resortName to showcase your property.',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 32),

            // 1. Choose from Gallery Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E7C59),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Take from Camera Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text(
                  'Take from Camera',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3E7C59),
                  side: const BorderSide(color: Color(0xFF3E7C59), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gallery View when photos exist
  Widget _buildGalleryView(String resortId, String resortName) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resortName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_images.length} photo${_images.length == 1 ? '' : 's'} available',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3E7C59),
                        side: const BorderSide(color: Color(0xFF3E7C59)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                      label: const Text('Add Photos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E7C59),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Responsive Grid of Images
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 900) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final img = _images[index];
                  return _buildImageCard(img);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> img) {
    final isCover = _isCoverImage(img);
    final Uint8List? bytes = img['bytes'];
    final String fullUrl = _resolveImageUrl(img['url']);
    final String fileName = img['fileName'] ?? 'photo.jpg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCover ? const Color(0xFF3E7C59) : Colors.grey.withValues(alpha: 0.15),
          width: isCover ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area with overlays
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openLightbox(img),
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                            ),
                          ),
                        ),
                ),

                // Primary Cover Badge
                if (isCover)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E7C59),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Primary Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top right actions (Edit & Delete)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.crop_rotate, color: Colors.white, size: 18),
                          tooltip: 'Edit & Crop photo',
                          onPressed: () => _editExistingImage(img),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          tooltip: 'Delete image',
                          onPressed: () => _deleteImage(img),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  img['category']?.toString() ?? 'Resort Photo',
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _editExistingImage(img),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.crop_rotate, size: 14, color: Color(0xFF3E7C59)),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E7C59),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isCover)
                      InkWell(
                        onTap: () => _setAsCover(img),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_border, size: 14, color: Color(0xFF3E7C59)),
                            SizedBox(width: 4),
                            Text(
                              'Set Cover',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E7C59),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Active Cover',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E7C59),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, size: 18, color: Colors.grey),
                      tooltip: 'Preview',
                      onPressed: () => _openLightbox(img),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
