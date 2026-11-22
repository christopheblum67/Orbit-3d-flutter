/// Only headers produced by the session manager may use this allowlist.
bool cloudflareHeadersNeedProtection(Map<String, String> headers) {
  const safe = {
    'user-agent',
    'referer',
    'accept',
    'accept-language',
    'sec-ch-ua',
    'sec-ch-ua-mobile',
    'sec-ch-ua-platform',
    'sec-fetch-dest',
    'sec-fetch-mode',
    'sec-fetch-site',
  };
  return headers.keys.any((name) => !safe.contains(name.toLowerCase()));
}

bool needsProtectedPlaybackProxy({
  required bool isLocalFile,
  required Map<String, String>? suppliedHeaders,
  required Map<String, String> sessionHeaders,
}) =>
    !isLocalFile &&
    ((suppliedHeaders?.isNotEmpty ?? false) ||
        cloudflareHeadersNeedProtection(sessionHeaders));
