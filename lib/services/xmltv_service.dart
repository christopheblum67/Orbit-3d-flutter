import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';

typedef XmltvHttpGet = Future<Response<dynamic>> Function(
  String url, {
  Options? options,
});

class XmltvService {
  XmltvService({
    required ConditionalXmltvCache cache,
    required XmltvHttpGet get,
  })  : _cache = cache,
        _get = get;

  final ConditionalXmltvCache _cache;
  final XmltvHttpGet _get;

  Future<List<EPGProgram>> fetch(String url) => _cache.fetch(
        resource: url,
        request: (headers) async {
          final response = await traceCatalogStep(
            'epg',
            'network',
            () => _get(
              url,
              options: Options(
                headers: headers,
                responseType: ResponseType.bytes,
                validateStatus: (status) =>
                    status != null &&
                    (status == 304 || (status >= 200 && status < 300)),
              ),
            ),
          );
          final data = response.data;
          return XmltvResponse(
            statusCode: response.statusCode ?? 0,
            body: data is List<int> ? Uint8List.fromList(data) : null,
            contentType: response.headers.value('content-type'),
            etag: response.headers.value('etag'),
            lastModified: response.headers.value('last-modified'),
            cacheControl: response.headers.value('cache-control'),
            vary: response.headers.value('vary'),
          );
        },
        parse: (bytes, contentType) => traceCatalogStep(
          'epg',
          'parse',
          () => parseBytesInIsolate(bytes, contentType: contentType),
        ),
      );

  static String decodeBytes(Uint8List bytes, {String headerCharset = ''}) =>
      _decodeXmltvPayload(bytes, 'charset=$headerCharset');

  static Future<List<EPGProgram>> parseBytesInIsolate(
    Uint8List bytes, {
    String? contentType,
  }) {
    if (kIsWeb) return compute(_parseXmltvBytes, (bytes, contentType));
    return compute(
      _parseTransferredXmltvBytes,
      (TransferableTypedData.fromList([bytes]), contentType),
    );
  }
}

List<EPGProgram> _parseTransferredXmltvBytes(
  (TransferableTypedData, String?) input,
) =>
    _parseXmltvBytes((input.$1.materialize().asUint8List(), input.$2));

List<EPGProgram> _parseXmltvBytes((Uint8List, String?) input) {
  final (bytes, contentType) = input;
  final content = _decodeXmltvPayload(bytes, contentType);
  final emptyRoot =
      RegExp(r'<tv(?:\s[^<>]*?)?\s*/>', caseSensitive: false).hasMatch(content);
  final hasRoot =
      RegExp(r'<tv(?:\s|>)', caseSensitive: false).hasMatch(content) &&
          RegExp(r'</tv\s*>', caseSensitive: false).hasMatch(content);
  if (!emptyRoot && !hasRoot) {
    throw const FormatException('Invalid XMLTV document');
  }
  return EpgStreamParser.parse(content);
}

String _decodeXmltvPayload(List<int> bytes, String? contentType) {
  final head = latin1.decode(bytes.take(4096).toList(), allowInvalid: true);
  final declared = RegExp(
    "encoding\\s*=\\s*['\"]([A-Za-z0-9_.\\-]+)['\"]",
    caseSensitive: false,
  ).firstMatch(head)?.group(1)?.toLowerCase();
  final header = contentType?.toLowerCase() ?? '';
  final headerCharset =
      RegExp('charset=([A-Za-z0-9_.\\-]+)').firstMatch(header)?.group(1);
  final candidates = <String>[
    if (declared != null) declared,
    if (headerCharset != null) headerCharset,
    'utf-8',
    'iso-8859-1',
  ];
  for (final charset in candidates) {
    final decoded = _decodeCharset(bytes, charset);
    if (decoded != null) return decoded;
  }
  return latin1.decode(bytes, allowInvalid: true);
}

String? _decodeCharset(List<int> bytes, String charset) {
  final name = charset.toLowerCase().trim();
  try {
    if (name == 'utf-8' || name == 'utf8') return utf8.decode(bytes);
    if (name == 'iso-8859-1' ||
        name == 'latin1' ||
        name == 'iso8859-1' ||
        name == 'windows-1252' ||
        name == 'cp1252') {
      return latin1.decode(bytes, allowInvalid: true);
    }
  } on FormatException {
    return null;
  }
  return null;
}
