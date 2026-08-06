import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../file_server_config.dart';

class ResortImageHelper {
  // In-memory cache mapping resort name or ID to list of resolved image URLs
  static final Map<String, List<String>> _imageUrlsCache = {};

  /// Resolves relative or full network image URL to a valid server URL
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${FileServerConfig.fileServerUrl}$trimmed';
    }
    return '${FileServerConfig.fileServerUrl}/$trimmed';
  }

  /// Dynamically fetches ALL available image URLs for a resort from DB property and File Server folder
  static Future<List<String>> getResortImageUrls(Map<String, dynamic> resort) async {
    final name = (resort['name'] ?? resort['resortName'] ?? '').toString().trim();
    final id = (resort['id'] ?? resort['resortId'] ?? '').toString().trim();
    final dbUrl = (resort['imageUrl'] ?? '').toString().trim();

    final List<String> urls = [];
    final Set<String> seen = {};

    void addUrl(String raw) {
      final full = resolveUrl(raw);
      if (full.isNotEmpty && !seen.contains(full)) {
        seen.add(full);
        urls.add(full);
      }
    }

    if (dbUrl.isNotEmpty) {
      addUrl(dbUrl);
    }

    // Check memory cache
    if (urls.isNotEmpty && name.isNotEmpty && _imageUrlsCache.containsKey(name) && _imageUrlsCache[name]!.length > 1) {
      return _imageUrlsCache[name]!;
    }

    // Query File Server folder (/api/files/resortimage/<identifier>)
    final identifiers = {name, id}.where((s) => s.isNotEmpty).toList();
    for (final identifier in identifiers) {
      try {
        final uri = Uri.parse('${FileServerConfig.fileServerUrl}/api/files/resortimage/${Uri.encodeComponent(identifier)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is List) {
            for (final f in (body['data'] as List)) {
              final relUrl = f['url']?.toString() ?? '/resortimage/$identifier/${f['fileName']}';
              addUrl(relUrl);
            }
          }
        }
      } catch (_) {}
    }

    if (name.isNotEmpty) _imageUrlsCache[name] = urls;
    if (id.isNotEmpty) _imageUrlsCache[id] = urls;

    return urls;
  }
}

/// Reusable Widget that displays an Auto-Scrolling Image Carousel for resort photos
class ResortImageWidget extends StatefulWidget {
  final Map<String, dynamic> resort;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Duration autoScrollDuration;

  const ResortImageWidget({
    super.key,
    required this.resort,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.autoScrollDuration = const Duration(seconds: 3),
  });

  @override
  State<ResortImageWidget> createState() => _ResortImageWidgetState();
}

class _ResortImageWidgetState extends State<ResortImageWidget> {
  List<String> _resolvedUrls = [];
  bool _isLoading = true;

  PageController? _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResortImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrl = oldWidget.resort['imageUrl']?.toString();
    final newUrl = widget.resort['imageUrl']?.toString();
    final oldName = oldWidget.resort['name']?.toString();
    final newName = widget.resort['name']?.toString();

    if (oldUrl != newUrl || oldName != newName) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    _autoScrollTimer?.cancel();
    final urls = await ResortImageHelper.getResortImageUrls(widget.resort);
    if (!mounted) return;

    setState(() {
      _resolvedUrls = urls;
      _isLoading = false;
      _currentPage = 0;
    });

    if (urls.length > 1) {
      _pageController?.dispose();
      _pageController = PageController(initialPage: 0);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_resolvedUrls.length <= 1) return;

    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) return;
      final nextPage = (_currentPage + 1) % _resolvedUrls.length;
      _pageController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 160,
      color: const Color(0xFFF0F4F2),
      child: const Center(
        child: Icon(Icons.villa_outlined, size: 40, color: Color(0xFF3E7C59)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = widget.placeholder ?? _defaultPlaceholder();
    } else if (_resolvedUrls.isEmpty) {
      content = widget.placeholder ?? _defaultPlaceholder();
    } else if (_resolvedUrls.length == 1) {
      content = Image.network(
        _resolvedUrls.first,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (ctx, err, stack) => widget.placeholder ?? _defaultPlaceholder(),
      );
    } else {
      // Multiple images available -> Auto-scrolling Carousel!
      content = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _resolvedUrls.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _resolvedUrls[index],
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (ctx, err, stack) => widget.placeholder ?? _defaultPlaceholder(),
              );
            },
          ),

          // Animated Dot Indicator Pills
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_resolvedUrls.length, (idx) {
                  final isActive = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: content,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }
}
