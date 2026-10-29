part of '../pages/store_settings_page.dart';

class StoreSettingsForm extends StatelessWidget {
  const StoreSettingsForm({
    super.key,
    required this.formKey,
    required this.storeNameController,
    required this.addressController,
    required this.taxController,
    required this.serviceChargeController,
    required this.logoUrl,
    required this.autoCloseShiftEnabled,
    required this.autoCloseShiftTime,
    required this.isSaving,
    required this.isUploadingLogo,
    required this.selectedLogoBytes,
    required this.errorMessage,
    required this.onUploadLogo,
    required this.onRemoveLogo,
    required this.onAutoCloseShiftEnabledChanged,
    required this.onSelectAutoCloseTime,
    required this.onSaveSettings,
    required this.resolveLogoUrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController storeNameController;
  final TextEditingController addressController;
  final TextEditingController taxController;
  final TextEditingController serviceChargeController;
  final String logoUrl;
  final bool autoCloseShiftEnabled;
  final String autoCloseShiftTime;
  final bool isSaving;
  final bool isUploadingLogo;
  final Uint8List? selectedLogoBytes;
  final String? errorMessage;
  final VoidCallback onUploadLogo;
  final VoidCallback onRemoveLogo;
  final ValueChanged<bool> onAutoCloseShiftEnabledChanged;
  final VoidCallback onSelectAutoCloseTime;
  final VoidCallback onSaveSettings;
  final String Function(String) resolveLogoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Identitas toko', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('store-settings-name'),
                    controller: storeNameController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Nama toko',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama toko wajib diisi.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    enabled: !isSaving,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Alamat toko',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Logo struk', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selectedLogoBytes != null
                          ? Image.memory(selectedLogoBytes!, fit: BoxFit.cover)
                          : logoUrl.isEmpty
                          ? const Icon(Icons.storefront_outlined, size: 44)
                          : Image.network(
                              resolveLogoUrl(logoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isSaving || isUploadingLogo
                        ? null
                        : onUploadLogo,
                    icon: isUploadingLogo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(
                      isUploadingLogo
                          ? 'Mengunggah logo...'
                          : 'Pilih dan unggah logo',
                    ),
                  ),
                  if (logoUrl.isNotEmpty || selectedLogoBytes != null)
                    TextButton.icon(
                      onPressed: isSaving || isUploadingLogo
                          ? null
                          : onRemoveLogo,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus logo dari pengaturan'),
                    ),
                  const Text(
                    'Format JPG, JPEG, PNG, WEBP, atau GIF. Maksimal 2 MB.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Biaya transaksi', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: taxController,
                    enabled: !isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Pajak (%)',
                      suffixText: '%',
                    ),
                    validator: (value) => _validateAmount(value, 'Pajak'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: serviceChargeController,
                    enabled: !isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Biaya layanan',
                      prefixText: 'Rp ',
                    ),
                    validator: (value) =>
                        _validateAmount(value, 'Biaya layanan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tutup shift otomatis'),
                  subtitle: const Text(
                    'Aktifkan penutupan shift otomatis sesuai jadwal backend.',
                  ),
                  value: autoCloseShiftEnabled,
                  onChanged: isSaving ? null : onAutoCloseShiftEnabledChanged,
                ),
                if (autoCloseShiftEnabled)
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Waktu penutupan shift'),
                    subtitle: Text(autoCloseShiftTime),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: isSaving ? null : onSelectAutoCloseTime,
                  ),
              ],
            ),
          ),
          if (errorMessage case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('store-settings-save'),
            onPressed: isSaving ? null : onSaveSettings,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isSaving ? 'Menyimpan...' : 'Simpan pengaturan'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String? _validateAmount(String? value, String label) {
    final parsed = num.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label harus berupa angka.';
    if (parsed < 0) return '$label tidak boleh kurang dari 0.';
    return null;
  }
}

class StoreSettingsLoadError extends StatelessWidget {
  const StoreSettingsLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}
