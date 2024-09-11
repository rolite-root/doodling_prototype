// device_responder.dart

import 'package:flutter/widgets.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

class DeviceResponder extends StatefulWidget {
  final String deviceName;
  final String serviceType;

  const DeviceResponder({
    super.key,
    required this.deviceName,
    required this.serviceType,
  });

  @override
  _DeviceResponderState createState() => _DeviceResponderState();
}

class _DeviceResponderState extends State<DeviceResponder>
    with WidgetsBindingObserver {
  MDnsClient? _mdnsClient;
  ServerSocket? _serverSocket;
  int port = 8080;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startResponder();
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder widget
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopResponder();
    super.dispose();
  }

  Future<void> startResponder() async {
    try {
      final info = NetworkInfo();
      String? wifiIP = await info.getWifiIP();

      if (wifiIP == null) {
        throw Exception('No valid IP address found.');
      }

      port = await _getFreePort(port);

      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _handleIncomingConnections();

      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      final service = Service(
        name: widget.deviceName,
        type: widget.serviceType,
        port: port,
      );

      final mdnsSd = MDnsSd.fromMDnsClient(_mdnsClient!);
      await mdnsSd.register(service);

      print("DeviceResponder started: ${widget.deviceName} on $wifiIP:$port");
    } catch (e) {
      print('Error starting responder: $e');
    }
  }

  Future<void> stopResponder() async {
    await _serverSocket?.close();
    _serverSocket = null;
    _mdnsClient?.stop();
    _mdnsClient = null;
    print("DeviceResponder stopped.");
  }

  Future<int> _getFreePort(int startingPort) async {
    int port = startingPort;
    bool portFound = false;

    while (!portFound) {
      try {
        final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await socket.close();
        portFound = true;
      } catch (e) {
        port++;
      }
    }
    return port;
  }

  void _handleIncomingConnections() {
    _serverSocket?.listen((Socket socket) {
      print('Connection from ${socket.remoteAddress}:${socket.remotePort}');
      // Handle communication with the client
    });
  }
}
