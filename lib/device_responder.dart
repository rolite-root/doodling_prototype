import 'package:bonsoir/bonsoir.dart';

class DeviceResponder {
  BonsoirService? _service;
  String _deviceName = "MyDevice"; // Replace this with the actual device's name or username

  Future<void> startResponder() async {
    final String deviceIP = await _getDeviceIPAddress();

    // Create a Bonsoir service to broadcast the device's presence
    _service = BonsoirService(
      name: _deviceName,
      type: "_http._tcp",
      port: 8080,
      // Add any additional attributes like username
      text: {'username': _deviceName}
    );

    // Start broadcasting the service
    await _service?.start();
  }

  Future<void> stopResponder() async {
    // Stop broadcasting the service
    await _service?.stop();
  }

  // Fetch the local device IP address
  Future<String> _getDeviceIPAddress() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (var interface in interfaces) {
      for (var address in interface.addresses) {
        if (address.address.startsWith('192.') || address.address.startsWith('10.')) {
          return address.address;  // Return the first local IP found
        }
      }
    }
    return '0.0.0.0';
  }
}
