import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/store_settings_repository.dart';

class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({
    super.key,
    required this.repository,
    required this.apiBaseUrl,
  });

  final StoreSettingsRepository repository;
  final String apiBaseUrl;

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  late Future<StoreSettings> _settingsFuture;
  String _logoUrl = '';
  String _autoCloseShiftTime = '00:00';
  bool _autoCloseShiftEnabled = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _hasLoadedSettings = false;
  Uint8List? _selectedLogoBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _serviceChargeController.dispose();
    super.dispose();
  }

  Future<StoreSettings> _loadSettings() async {
    final settings = await widget.repository.getSettings();
    if (mounted) _applySettings(settings);
    return settings;
  }

  void _applySettings(StoreSettings settings) {
    _storeNameController.text = settings.storeName;
    _addressController.text = settings.address;
    _taxController.text = settings.taxPercentage.toString();
    _serviceChargeController.text = settings.serviceCharge.toString();
    _logoUrl = settings.logoUrl;
    _autoCloseShiftEnabled = settings.autoCloseShiftEnabled;
    _autoCloseShiftTime = settings.autoCloseShiftTime;
    _hasLoadedSettings = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan toko')),
      body: FutureBuilder<StoreSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !_hasLoadedSettings) {
            return _LoadError(
              message: 'Pengaturan toko gagal dimuat: ${snapshot.error}',
              onRetry: () => setState(() {
                _settingsFuture = _loadSettings();
              }),
            );
          }
          return _settingsForm(context);
        },
      ),
    );
  }

  Widget _settingsForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
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
                    controller: _storeNameController,
                    enabled: !_isSaving,
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
                    controller: _addressController,
                    enabled: !_isSaving,
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
                      child: _selectedLogoBytes != null
                          ? Image.memory(_selectedLogoBytes!, fit: BoxFit.cover)
                          : _logoUrl.isEmpty
                          ? const Icon(Icons.storefront_outlined, size: 44)
                          : Image.network(
                              _resolvedLogoUrl(_logoUrl),
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
                    onPressed: _isSaving || _isUploadingLogo
                        ? null
                        : _pickAndUploadLogo,
                    icon: _isUploadingLogo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(
                      _isUploadingLogo ? 'Mengunggah logo...' : 'Pilih dan unggah logo',
                    ),
                  ),
                  if (_logoUrl.isNotEmpty || _selectedLogoBytes != null)
                    TextButton.icon(
                      onPressed: _isSaving || _isUploadingLogo
                          ? null
                          : () => setState(() {
                              _logoUrl = '';
                              _selectedLogoBytes = null;
                            }),
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
                    controller: _taxController,
                    enabled: !_isSaving,
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
                    controller: _serviceChargeController,
                    enabled: !_isSaving,
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
                  value: _autoCloseShiftEnabled,
                  onChanged: _isSaving
                      ? null
                      : (enabled) => setState(
                          () => _autoCloseShiftEnabled = enabled,
                        ),
                ),
                if (_autoCloseShiftEnabled)
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Waktu penutupan shift'),
                    subtitle: Text(_autoCloseShiftTime),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _isSaving ? null : _selectAutoCloseTime,
                  ),
              ],
            ),
          ),
          if (_errorMessage case final error?) ...[
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
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan pengaturan'),
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

  Future<void> _pickAndUploadLogo() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        _isUploadingLogo = true;
        _errorMessage = null;
      });
      final url = await widget.repository.uploadLogo(image);
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _logoUrl = url;
        _selectedLogoBytes = bytes;
        _isUploadingLogo = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingLogo = false;
        _errorMessage = 'Logo gagal diunggah: $error';
      });
    }
  }

  Future<void> _selectAutoCloseTime() async {
    final parts = _autoCloseShiftTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted || time == null) return;
    setState(() {
      _autoCloseShiftTime =
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final settings = StoreSettings(
      storeName: _storeNameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: _logoUrl,
      taxPercentage: num.parse(_taxController.text.trim()),
      serviceCharge: num.parse(_serviceChargeController.text.trim()),
      autoCloseShiftEnabled: _autoCloseShiftEnabled,
      autoCloseShiftTime: _autoCloseShiftTime,
    );
    try {
      final saved = await widget.repository.updateSettings(settings);
      if (!mounted) return;
      setState(() {
        _applySettings(saved);
        _selectedLogoBytes = null;
        _settingsFuture = Future.value(saved);
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan toko berhasil disimpan.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Pengaturan gagal disimpan: $error';
      });
    }
  }

  String _resolvedLogoUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.hasScheme) return url;
    return Uri.parse(widget.apiBaseUrl).resolve(url).toString();
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

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
