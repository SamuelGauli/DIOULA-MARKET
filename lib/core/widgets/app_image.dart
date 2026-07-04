import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Image polyvalente qui gère les URLs réseau ET les chemins locaux.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  bool get _isLocal => !url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (_isLocal && !kIsWeb) {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, e, s) =>
            errorWidget?.call(ctx, url, e) ??
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (ctx, _) =>
          placeholder?.call(ctx, url) ??
          const Center(child: CircularProgressIndicator()),
      errorWidget: (ctx, _, e) =>
          errorWidget?.call(ctx, url, e) ??
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

/// Image polyvalente pour les `DecorationImage` (logos circulaires, etc.).
class AppNetworkProvider {
  static ImageProvider<Object> provider(String url) {
    if (!url.startsWith('http') && !kIsWeb) {
      return FileImage(File(url));
    }
    return CachedNetworkImageProvider(url);
  }
}
