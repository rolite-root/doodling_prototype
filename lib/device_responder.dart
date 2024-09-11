import 'package:flutter/widgets.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

class DeviceResponder extends StatefulWidget {
  final String deviceName;
  final String serviceType;

  const DeviceResponder({super.key, required this.deviceName, required this.serviceType});

  @override
  _DeviceResponderState createState() => _DeviceResponderState();
}

class _DeviceResponderState extends State<DeviceResponder> with WidgetsBindingObserver {
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
    return Container();  // Placeholder widget
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

      final serviceDomain = '${widget.deviceName}.${widget.serviceType}.local';
      final srvRecord = SrvResourceRecord(
        serviceDomain,
        port,
        weight: 0,
        priority: 0,
        target: wifiIP,
        port: port,
      );
      final service = Service(name: serviceDomain, type: widget.serviceType, port: port);

      final mdnsSd = MDnsSd.fromMDnsClient(_mdnsClient!);
      await mdnsSd.register(service, {srvRecord});

      print('Service "${widget.deviceName}" started on port $port and advertised via mDNS');
    } catch (e) {
      print('Failed to start responder: $e');
    }
  }

  Future<void> stopResponder() async {
    try {
      _mdnsClient?.stop();
      await _serverSocket?.close();
      print('Responder stopped.');
    } catch (e) {
      print('Failed to stop responder: $e');
    }
  }

  Future<void> startDiscovery() async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      await for (final PtrResourceRecord ptr
          in _mdnsClient!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(widget.serviceType),
      )) {
        final serviceDomain = ptr.domainName;
        final serviceParts = serviceDomain.split('.');

        if (serviceParts.length >= 3) {
          final discoveredDeviceName = serviceParts[0];
          final discoveredServiceType = serviceParts[1];

          await for (final SrvResourceRecord srvRecord in _mdnsClient!
              .lookup<SrvResourceRecord>(
                  ResourceRecordQuery.service(serviceDomain))) {
            final host = srvRecord.target;
            final port = srvRecord.port;
            print('Service discovered: $discoveredDeviceName ($discoveredServiceType) at $host:$port');
          }
        }
      }
    } catch (e) {
      print('Failed to start discovery: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      _mdnsClient?.stop();
      print('Discovery stopped.');
    } catch (e) {
      print('Failed to stop discovery: $e');
    }
  }

  Future<int> _getFreePort(int preferredPort) async {
    try {
      ServerSocket? socket;
      try {
        socket = await ServerSocket.bind(InternetAddress.anyIPv4, preferredPort);
        return socket.port;
      } catch (_) {
        socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        return socket.port;
      } finally {
        await socket?.close();
      }
    } catch (e) {
      print('Failed to find a free port: $e');
      return preferredPort;
    }
  }

  void _handleIncomingConnections() {
    _serverSocket?.listen((socket) {
      socket.listen((data) {
        final message = String.fromCharCodes(data);
        print('Received message from client: $message');
        socket.write('Hello from ${widget.deviceName}! You sent: $message');
      });
    });
  }
}
