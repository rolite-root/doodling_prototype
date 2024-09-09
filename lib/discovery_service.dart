import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DiscoveryService {
  MDnsClient? _mdnsClient;

  Future<List<Map<String, String>>> discoverDevices() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();

    if (wifiIP == null) {
      return [];
    }

    // Create a baseIP for discovering devices in the same subnet
    final ipParts = wifiIP.split('.');
    final baseIP = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.';

    // Initialize device discovery list
    List<Map<String, String>> discoveredDevices = [];

    // Start mDNS client
    _mdnsClient = MDnsClient();
    await _mdnsClient!.start();

    // Query for devices on the network using mDNS
    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_http._tcp.local'),
    )) {
      // Get the instance name or IP address
      final deviceIp = ptr.domainName;
      // Here, you need logic to fetch actual IP or resolve it (replace the ptr.domainName with actual IP logic)

      // Assuming you have a mechanism to get usernames from devices, fetch them here
      String deviceUsername = await _getDeviceUsername(deviceIp);

      // Add discovered devices to the list
      discoveredDevices.add({
        'ip': deviceIp,
        'username': deviceUsername.isEmpty ? 'Unknown User' : deviceUsername,
      });
    }

    _mdnsClient!.stop();
    return discoveredDevices;
  }

  // Placeholder for logic to get a device's username
  Future<String> _getDeviceUsername(String deviceIp) async {
    // Use your own logic here to retrieve the username (e.g., TCP/UDP handshake)
    // For now, returning a placeholder
    return "DeviceUser";
  }
}
