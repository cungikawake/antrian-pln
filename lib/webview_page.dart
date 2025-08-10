// ignore_for_file: camel_case_types, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class WebviewPage extends StatefulWidget {
  const WebviewPage({Key? key}) : super(key: key);

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  WebViewController? _controller;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) 
      ..addJavaScriptChannel(
        'pos', // Nama channel yang dipanggil dari web
        onMessageReceived: (JavaScriptMessage message) {
          // Pesan dari web → langsung print
          String textToPrint = message.message;
          _printThermal(textToPrint);
        },
      )
      // ..setNavigationDelegate(
      //   NavigationDelegate(
      //     onProgress: (int progress) {
      //       // Update loading bar.
      //     },
      //     onPageStarted: (String url) {},
      //     onPageFinished: (String url) {},
      //     onWebResourceError: (WebResourceError error) {},
      //     onNavigationRequest: (NavigationRequest request) {
      //       if (request.url.startsWith('https://gentamasbali.id/')) {
      //         return NavigationDecision.prevent;
      //       }
      //       return NavigationDecision.navigate;
      //     },
      //   ),
      // )
      ..loadRequest(Uri.parse('https://gentamasbali.id/print.php'));
  }

  void _printThermal(String text) async {
    try {
      // Ambil list printer yang sudah paired
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      if (devices.isNotEmpty) {
        // // Ambil printer pertama yang ditemukan
        // await bluetooth.connect(devices.first);

        // bluetooth.printNewLine();
        // bluetooth.printCustom(text, 1, 1); // (teks, font size, align center)
        // bluetooth.printNewLine();
        // bluetooth.paperCut();
        // Filter printer berdasarkan nama
        final keywords = ["pos", "epson", "thermal"];
        BluetoothDevice? targetPrinter;

        for (var device in devices) {
          String name = device.name?.toLowerCase() ?? "";
          if (keywords.any((keyword) => name.contains(keyword))) {
            targetPrinter = device;
            break;
          }
        }

        if (targetPrinter == null) {
          debugPrint("Tidak ada printer sesuai filter keyword");
          return;
        }

        debugPrint("Menghubungkan ke printer: ${targetPrinter.name} (${targetPrinter.address})");
        await bluetooth.connect(targetPrinter);

        bluetooth.printNewLine();
        bluetooth.printCustom(text, 1, 1); // Font normal, align center
        bluetooth.printNewLine();
        bluetooth.paperCut();

        debugPrint("Cetak selesai tanpa preview.");
      } else {
        debugPrint("Tidak ada printer terhubung");
      }
    } catch (e) {
      debugPrint("Error printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Antrian PLN"),
          actions: const [],
        ),
        body: WebViewWidget(controller: _controller!));
  }
}
