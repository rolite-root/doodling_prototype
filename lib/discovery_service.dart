import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class DiscoveryService {
  Future<List<Map<String, String>>> discoverDevices() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();
    if (wifiIP == null) {
      return [];
    }

    List<Map<String, String>> discoveredDevices = [];
    final ipParts = wifiIP.split('.');
    final baseIP = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.';

    for (int i = 1; i < 255; i++) {
      final targetIP = baseIP + i.toString();
      try {
        Socket socket =
            await Socket.connect(targetIP, 5000, timeout: const Duration(seconds: 1));
        // Assuming you have some protocol to identify devices and get usernames
        discoveredDevices.add({'ip': targetIP, 'username': 'Unknown User'});
        socket.destroy();
      } catch (e) {
        // Ignore if device is not found or connection times out
      }
    }

    return discoveredDevices;
  }
}
