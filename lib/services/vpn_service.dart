class VpnService {
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect(String configPath) async {
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
  }

  Future<void> saveConfigPath(String path) async {
    // Simulé : rien à faire
  }

  Future<String?> getConfigPath() async {
    return null;
  }

  Future<void> toggleVpn() async {
    if (_isConnected) {
      await disconnect();
    } else {
      await connect('');
    }
  }
}
