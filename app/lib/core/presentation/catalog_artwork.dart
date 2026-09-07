import 'package:flutter/material.dart';

/// Renders a server-owned catalog artwork without treating arbitrary user
/// input as an image source.
///
/// Local Flutter assets are preferred for fixed Home artwork. Approved remote
/// catalog exports may use an HTTPS URL. Storage paths and unknown schemes are
/// deliberately kept as placeholders until the catalog storage resolver is
/// configured, so a database value cannot make the client fetch an arbitrary
/// resource.
class CatalogArtwork extends StatelessWidget {
  const CatalogArtwork({
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.semanticLabel,
    super.key,
  });

  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final path = assetPath?.trim();
    final image = switch (path) {
      final value when value == null || value.isEmpty => null,
      final value when value.startsWith('assets/') => Image.asset(
        value,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => _fallback(),
      ),
      final value => _remoteImage(value),
    };
    return image ?? _fallback();
  }

  Widget _remoteImage(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return _fallback();
    }
    return Image.network(
      uri.toString(),
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Semantics(
      image: semanticLabel != null,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: placeholder ?? const Icon(Icons.image_outlined)),
      ),
    );
  }
}
