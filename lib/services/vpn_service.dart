class VpnService {
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect(String configPath) async {
    // TODO: intégrer un vrai VPN (OpenVPN/WireGuard)
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
  }
}
