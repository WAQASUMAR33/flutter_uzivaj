import 'package:flutter/foundation.dart' show kIsWeb;

/// Joins an image base URL with a filename, normalizing the slash between
/// them so it works whether the base has a trailing slash and/or the
/// filename has a leading slash (the API has returned both forms).
String joinImageUrl(String base, String name) {
  if (name.startsWith('http')) return name;
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final n = name.startsWith('/') ? name : '/$name';
  return '$b$n';
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
