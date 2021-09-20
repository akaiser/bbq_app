import 'package:bbq_app/shared/prefs.dart';
import 'package:bbq_app/shared/util/environment.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatelessWidget {
  const WebViewPage({Key? key}) : super(key: key);

  static const route = 'webview_page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: const SafeArea(child: _WebViewContainer()),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        label: const Text(
          'Back',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _WebViewContainer extends StatefulWidget {
  const _WebViewContainer({
    Key? key,
  }) : super(key: key);

  @override
  _WebViewContainerState createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<_WebViewContainer> {
  bool _isLoading = true;
  late WebViewController _webViewController;

  Future<bool> _onWillPop(BuildContext context) async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebView(
            initialUrl: Environment.baseUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: (_) => Future.delayed(
              const Duration(milliseconds: 500),
              () => setState(() => _isLoading = false),
            ),
            onWebViewCreated: (controller) => _webViewController = controller,
          ),
          if (_isLoading)
            const ColoredBox(
              color: mainColor,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
