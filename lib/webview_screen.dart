import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  WebViewScreenState createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => isLoading = true),
              onPageFinished: (_) => setState(() => isLoading = false),
            ),
          );

    _checkInternetAndLoad();
    _listenToInternetChanges();
  }

  /// ✅ Verifica la conexión antes de cargar la WebView
  Future<void> _checkInternetAndLoad() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.wifi) &&
        !connectivityResult.contains(ConnectivityResult.mobile)) {
      setState(() => hasInternet = false);
    } else {
      setState(() {
        hasInternet = true;
        _controller.clearCache(); // 💡 Limpia la caché antes de cargar la URL
        _controller.loadRequest(
          Uri.parse(widget.url),
        ); // 🚀 Fuerza la carga desde la red
      });
    }
  }

  /// ✅ Detecta cambios en la conexión y recarga si es necesario
  void _listenToInternetChanges() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      if ((connectivityResult.contains(ConnectivityResult.wifi) ||
              connectivityResult.contains(ConnectivityResult.mobile)) &&
          !hasInternet) {
        setState(() => hasInternet = true);
        _controller.loadRequest(Uri.parse(widget.url));
      }
    });
  }

  /// ✅ Permite recargar la página con un Swipe
  Future<void> _reloadPage() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile)) {
      setState(() => hasInternet = true);
      _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          hasInternet
              ? RefreshIndicator(
                onRefresh: _reloadPage,
                child: WebViewWidget(controller: _controller),
              )
              : _noInternetWidget(),
          if (isLoading && hasInternet)
            Center(child: CircularProgressIndicator()),
          Positioned(
            top: 40,
            left: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/back_button.png', height: 40),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Widget para mostrar si no hay conexión a Internet
  Widget _noInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 50, color: Colors.red),
          SizedBox(height: 10),
          Text(
            "You must be connected to a network",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkInternetAndLoad,
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }
}
