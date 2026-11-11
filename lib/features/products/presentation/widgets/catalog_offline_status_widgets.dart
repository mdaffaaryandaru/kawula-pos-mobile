import 'package:flutter/material.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogOfflineQueueButton extends StatelessWidget {
  const CatalogOfflineQueueButton({
    super.key,
    required this.queueCount,
    required this.onOpenQueue,
  });

  final Future<int> queueCount;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: queueCount,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            tooltip: 'Antrean gagal dimuat: ${snapshot.error}',
            onPressed: onOpenQueue,
            icon: Icon(
              Icons.sync_problem_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }
        final count = snapshot.data ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Antrean transaksi offline',
            onPressed: onOpenQueue,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.sync_alt_outlined),
            ),
          ),
        );
      },
    );
  }
}

class CatalogOfflineStatusBanner extends StatelessWidget {
  const CatalogOfflineStatusBanner({
    super.key,
    required this.status,
    required this.queueCount,
    required this.autoCloseSettingsError,
    required this.onOpenQueue,
    required this.buildAutoCloseWarning,
  });

  final OfflineNetworkStatus status;
  final Future<int> queueCount;
  final String? autoCloseSettingsError;
  final VoidCallback onOpenQueue;
  final Widget? Function(BuildContext context, int queueCount)
  buildAutoCloseWarning;

  @override
  Widget build(BuildContext context) {
    final isOffline = status == OfflineNetworkStatus.offline;
    final isChecking = status == OfflineNetworkStatus.checking;
    return FutureBuilder<int>(
      future: queueCount,
      builder: (context, snapshot) {
        final offlineText = switch (status) {
          OfflineNetworkStatus.offline => 'Mode Offline: katalog menggunakan data terakhir dan transaksi akan disimpan di perangkat.',
          OfflineNetworkStatus.checking => 'Memeriksa koneksi ke server...',
          OfflineNetworkStatus.online => 'Koneksi tersedia. Antrean dapat disinkronkan setelah PIN dipastikan.',
        };
        final color = isOffline
            ? const Color(0xFFFBF2D6)
            : isChecking
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : const Color(0xFFE8F7F0);
        final iconColor = isOffline
            ? Colors.orange
            : isChecking
            ? Theme.of(context).colorScheme.primary
            : AppColors.success;
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: iconColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  isOffline
                      ? Icons.cloud_off_rounded
                      : isChecking
                      ? Icons.sync
                      : Icons.cloud_done,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$offlineText Antrean gagal dibaca: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }

        final count = snapshot.data ?? 0;
        final needsSync = count > 0;
        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Container(
                key: ValueKey('$isOffline-$count'),
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOffline
                          ? Icons.cloud_off_rounded
                          : isChecking
                          ? Icons.sync
                          : Icons.signal_cellular_4_bar_rounded,
                      color: iconColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offlineText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (needsSync)
                      TextButton(
                        onPressed: onOpenQueue,
                        child: const Text('Sinkronkan'),
                      ),
                  ],
                ),
              ),
            ),
            ?buildAutoCloseWarning(context, count),
            if (count > 0 && autoCloseSettingsError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  'Pengaturan auto-close belum dapat dipastikan: '
                  '$autoCloseSettingsError',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
