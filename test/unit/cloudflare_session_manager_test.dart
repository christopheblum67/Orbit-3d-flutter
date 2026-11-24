import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
// The platform interface is used to simulate WebView navigation callbacks.
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _WebViewPlatform extends WebViewPlatform {
  late _Controller controller;
  late _Delegate delegate;
  final cookies = <WebViewCookie>[];

  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    return controller = _Controller(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params) {
    return delegate = _Delegate(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
      PlatformWebViewCookieManagerCreationParams params) {
    return _Cookies(params, cookies);
  }
}

class _Controller extends PlatformWebViewController {
  _Controller(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<String?> getUserAgent() async => 'Native WebView UA';
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async =>
      javaScript == 'document.title' ? 'Normal page' : 'visible=only';
}

class _Delegate extends PlatformNavigationDelegate {
  _Delegate(super.params) : super.implementation();
  late PageEventCallback started;
  late PageEventCallback finished;
  late HttpResponseErrorCallback httpError;

  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async =>
      started = callback;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async =>
      finished = callback;
  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async =>
      httpError = callback;
  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback callback) async {}
}

class _Cookies extends PlatformWebViewCookieManager {
  _Cookies(super.params, this.cookies) : super.implementation();
  final List<WebViewCookie> cookies;
  @override
  Future<List<WebViewCookie>> getCookies(Uri url) async => cookies;
}

void main() {
  test('native cookies are preferred and retain their exact values', () async {
    var javascriptCalled = false;
    final result = await readCloudflareCookies(
      readNative: () async => 'other=visible; cf_clearance=abc==',
      readJavaScript: () async {
        javascriptCalled = true;
        return 'other=visible';
      },
    );
    expect(result, 'other=visible; cf_clearance=abc==');
    expect(javascriptCalled, isFalse);
  });

  test('JavaScript cookies are used only if native storage is unavailable',
      () async {
    final result = await readCloudflareCookies(
      readNative: () async => throw StateError('unavailable'),
      readJavaScript: () async => 'cf_clearance=visible',
    );
    expect(result, 'cf_clearance=visible');
  });

  testWidgets('a blocked page is not treated as a successful session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    overrideSecretStoreForTesting(InMemorySecretStore());
    addTearDown(restoreSecretStoreForTesting);
    final platform = _WebViewPlatform();
    WebViewPlatform.instance = platform;
    final session = CloudflareSessionManager.forTesting();
    const origin = 'https://provider.test';
    platform.cookies.add(const WebViewCookie(
        name: 'cf_clearance', value: 'old', domain: 'provider.test'));
    var done = false;
    final pending =
        session.initialize(baseUrl: origin).then((_) => done = true);
    await tester.pump();
    await tester.pump();
    platform.delegate.started('$origin/');
    platform.delegate.httpError(HttpResponseError(
      request: WebResourceRequest(uri: Uri.parse('$origin/')),
      response: const WebResourceResponse(uri: null, statusCode: 403),
    ));
    platform.delegate.finished('$origin/');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(done, isFalse);
    expect(session.isReady, isFalse);
    platform.delegate.started('$origin/step');
    platform.delegate.httpError(HttpResponseError(
      request: WebResourceRequest(uri: Uri.parse('$origin/step')),
      response: const WebResourceResponse(uri: null, statusCode: 503),
    ));
    platform.delegate.finished('$origin/step');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(session.isReady, isFalse);
    platform.delegate.started('$origin/success');
    platform.delegate.finished('$origin/success');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await pending;
    expect(session.isReady, isTrue);
    expect(session.userAgent, 'Native WebView UA');
    expect(session.cookies, 'cf_clearance=old');
    session.dispose();
  });

  testWidgets('a failed subresource does not abort a normal page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    overrideSecretStoreForTesting(InMemorySecretStore());
    addTearDown(restoreSecretStoreForTesting);
    final platform = _WebViewPlatform();
    WebViewPlatform.instance = platform;
    final session = CloudflareSessionManager.forTesting();
    const origin = 'https://provider.test';
    final pending = session.initialize(baseUrl: origin);
    await tester.pump();
    await tester.pump();
    platform.delegate.started('$origin/');
    platform.delegate.httpError(HttpResponseError(
      request: WebResourceRequest(uri: Uri.parse('$origin/image.png')),
      response: const WebResourceResponse(uri: null, statusCode: 404),
    ));
    platform.delegate.finished('$origin/');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await pending;
    expect(session.isReady, isTrue);
    expect(session.hasClearance, isFalse);
    session.dispose();
  });

  testWidgets('a timed-out navigation cannot update a later attempt',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    overrideSecretStoreForTesting(InMemorySecretStore());
    addTearDown(restoreSecretStoreForTesting);
    final platform = _WebViewPlatform();
    WebViewPlatform.instance = platform;
    final session = CloudflareSessionManager.forTesting(
      attemptTimeouts: [const Duration(seconds: 2), const Duration(seconds: 3)],
    );
    const origin = 'https://provider.test';
    final pending = session.initialize(baseUrl: origin);
    await tester.pump();
    await tester.pump();
    final oldDelegate = platform.delegate;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(platform.delegate, isNot(same(oldDelegate)));
    oldDelegate.finished('$origin/');
    await tester.pump(const Duration(seconds: 1));
    expect(session.isReady, isFalse);
    platform.delegate.started('$origin/');
    platform.delegate.finished('$origin/');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await pending;
    expect(session.isReady, isTrue);
    expect(session.hasClearance, isFalse);
    session.dispose();
  });
}
