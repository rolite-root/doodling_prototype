import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class DiscoveryService {
  Future<List<String>> discoverDevices() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();
    if (wifiIP == null) {
      return [];
    }

    List<String> discoveredDevices = [];
    // Simulate the discovery process by scanning a range of IP addresses.
    final ipParts = wifiIP.split('.');
    final baseIP = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.';

    for (int i = 1; i < 255; i++) {
      final targetIP = baseIP + i.toString();
      try {
        final result = await InternetAddress.lookup(targetIP);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          discoveredDevices.add(targetIP);
        }
      } catch (e) {
        // Ignore if device is not found
      }
    }

    return discoveredDevices;
  }
}
