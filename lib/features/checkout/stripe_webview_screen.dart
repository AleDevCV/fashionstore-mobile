import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/theme.dart';

class StripeWebviewScreen extends StatefulWidget {
  final String checkoutUrl;

  const StripeWebviewScreen({
    Key? key,
    required this.checkoutUrl,
  }) : super(key: key);

  @override
  State<StripeWebviewScreen> createState() => _StripeWebviewScreenState();
}

class _StripeWebviewScreenState extends State<StripeWebviewScreen> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago Seguro - Stripe'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // El usuario canceló manualmente
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.checkoutUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true, // Importante para interceptar HTTP redirects
            ),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              print("StripeWebview intercepted URL: $url");
              
              if (url.contains('/pago/exitoso') || url.contains('/pago/exito')) {
                if (!_isClosing) {
                  _isClosing = true;
                  Navigator.of(context).pop(true);
                }
                return NavigationActionPolicy.CANCEL;
              } else if (url.contains('/pago/cancelado')) {
                if (!_isClosing) {
                  _isClosing = true;
                  Navigator.of(context).pop(false);
                }
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              if (url != null) _checkUrl(url.toString());
            },
            onLoadStop: (controller, url) {
              if (url != null) _checkUrl(url.toString());
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              if (url != null) _checkUrl(url.toString());
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              color: fsEmerald,
            ),
        ],
      ),
    );
  }

  bool _isClosing = false;

  void _checkUrl(String url) {
    if (_isClosing) return;

    // Si contiene la URL de éxito definida en el backend
    if (url.contains('/pago/exitoso') || url.contains('/pago/exito')) {
      _isClosing = true;
      Navigator.of(context).pop(true);
    } 
    // Si contiene la URL de cancelación definida en el backend
    else if (url.contains('/pago/cancelado')) {
      _isClosing = true;
      Navigator.of(context).pop(false);
    }
  }
}
