enum OfflineNetworkStatus { online, offline, checking }

abstract interface class OfflineNetworkStatusController {
  OfflineNetworkStatus get status;

  Stream<OfflineNetworkStatus> get statusChanges;

  void markOffline();

  void markChecking();

  void markOnline();
}
