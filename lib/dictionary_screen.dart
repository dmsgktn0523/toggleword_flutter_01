// import 'package:flutter/cupertino.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class WebView extends StatefulWidget{
//   const WebView({ Key? key }) : super(key: key);
//
//   @override
//   _WebViewState createState() => _WebViewState();
// }
//
// class _WebViewState extends State<WebView> {
//   final controller = WebViewController()
//   ..setJavaScriptMode(JavaScriptMode.unrestricted)
//   ..loadRequest(Uri.parse("https://en.dict.naver.com/#/main"));
//
//   @override
//   Widget build (BuildContext context) {
//     return SafeArea(child: WebViewWidget(controller: controller,));
//   }
// }