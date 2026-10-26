import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Browser visible to the user for provider verification.
/// It intentionally does not export or forward WebView cookies to the player.
class ProviderVerificationDialog extends StatefulWidget {
  const ProviderVerificationDialog({
    required this.uri,
    required this.title,
    required this.instructions,
    required this.closeLabel,
    super.key,
  });

  final Uri uri;
  final String title;
  final String instructions;
  final String closeLabel;

  @override
  State<ProviderVerificationDialog> createState() =>
      _ProviderVerificationDialogState();
}

class _ProviderVerificationDialogState
    extends State<ProviderVerificationDialog> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate())
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: widget.closeLabel,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip:
                MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            icon: const Icon(Icons.refresh),
            onPressed: _controller.reload,
          ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            content: Text(widget.instructions),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.closeLabel),
              ),
            ],
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
