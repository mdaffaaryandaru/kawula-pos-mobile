typedef SessionExpiredCallback = Future<void> Function();

class AuthSessionExpiryHandler {
  String? _activeToken;
  SessionExpiredCallback? _onSessionExpired;
  bool _isHandlingExpiry = false;

  void attach(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  void detach() {
    _onSessionExpired = null;
  }

  void markSessionActive(String token) {
    _activeToken = token;
    _isHandlingExpiry = false;
  }

  void markSessionEnded([String? token]) {
    if (token == null || token == _activeToken) {
      _activeToken = null;
    }
  }

  Future<void> handleUnauthorized(String token) async {
    if (_activeToken != token || _isHandlingExpiry) return;
    _activeToken = null;
    _isHandlingExpiry = true;
    try {
      await _onSessionExpired?.call();
    } finally {
      _isHandlingExpiry = false;
    }
  }
}
