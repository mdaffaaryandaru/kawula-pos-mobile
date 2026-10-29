import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/store_settings_repository.dart';

part '../widgets/store_settings_form.dart';

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
            return StoreSettingsLoadError(
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

  Widget _settingsForm(BuildContext context) => StoreSettingsForm(
    formKey: _formKey,
    storeNameController: _storeNameController,
    addressController: _addressController,
    taxController: _taxController,
    serviceChargeController: _serviceChargeController,
    logoUrl: _logoUrl,
    autoCloseShiftEnabled: _autoCloseShiftEnabled,
    autoCloseShiftTime: _autoCloseShiftTime,
    isSaving: _isSaving,
    isUploadingLogo: _isUploadingLogo,
    selectedLogoBytes: _selectedLogoBytes,
    errorMessage: _errorMessage,
    onUploadLogo: _pickAndUploadLogo,
    onRemoveLogo: () => setState(() {
      _logoUrl = '';
      _selectedLogoBytes = null;
    }),
    onAutoCloseShiftEnabledChanged: (enabled) =>
        setState(() => _autoCloseShiftEnabled = enabled),
    onSelectAutoCloseTime: _selectAutoCloseTime,
    onSaveSettings: _saveSettings,
    resolveLogoUrl: _resolvedLogoUrl,
  );

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
