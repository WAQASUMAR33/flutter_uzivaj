import 'package:flutter/foundation.dart' show kIsWeb;

const String appBaseUrl = 'https://uzivajlife.online';
const String appImageUploadsBaseUrl = 'https://uzivajlife.online/uploads';

/// Joins an image base URL with a filename or path.
/// All uploaded images are served from https://uzivajlife.online/uploads/
String joinImageUrl(String base, String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/uploads/')) {
    return '$appBaseUrl$trimmed';
  }
  if (trimmed.startsWith('uploads/')) {
    return '$appBaseUrl/$trimmed';
  }
  final clean = trimmed.replaceFirst(RegExp(r'^/+'), '');
  return '$appImageUploadsBaseUrl/$clean';
}

/// On Flutter Web, `Image.network` decodes images via the CanvasKit renderer,
/// which requires the image host to send an `Access-Control-Allow-Origin`
/// header. Hosts that don't (e.g. uzivaj.rizwancars.com) fail silently and
/// fall back to error builders. Routing through images.weserv.nl re-serves
/// the image with CORS headers attached. Native platforms aren't affected by
/// CORS, so the URL is returned unchanged there.
String webSafeImageUrl(String url) {
  if (!kIsWeb || url.contains('images.weserv.nl')) return url;
  final stripped = url.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(stripped)}';
}
