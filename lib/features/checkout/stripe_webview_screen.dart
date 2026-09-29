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
            ),
            onLoadStart: (controller, url) {
              _checkUrl(url.toString());
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              if (url != null) {
                _checkUrl(url.toString());
              }
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

  void _checkUrl(String url) {
    // Si contiene la URL de éxito definida en el backend
    if (url.contains('/pago/exitoso')) {
      Navigator.of(context).pop(true);
    } 
    // Si contiene la URL de cancelación definida en el backend
    else if (url.contains('/pago/cancelado')) {
      Navigator.of(context).pop(false);
    }
  }
}
