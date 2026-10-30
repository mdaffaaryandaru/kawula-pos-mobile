import 'package:flutter/material.dart';

import '../../domain/entities/member.dart';

class MemberDialog extends StatefulWidget {
  const MemberDialog({super.key, this.member});

  final Member? member;

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.member?.phoneNumber ?? '',
    );
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _isActive = widget.member?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.member == null ? 'Tambah member' : 'Ubah member'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama member'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Nama minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor telepon'),
                keyboardType: TextInputType.phone,
                validator: (value) => (value?.trim().length ?? 0) < 6
                    ? 'Nomor telepon minimal 6 karakter.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opsional)',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isNotEmpty &&
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Format email tidak valid.';
                  }
                  return null;
                },
              ),
              if (widget.member != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Member aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Simpan')),
    ],
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      MemberDraft(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class MemberDraft {
  const MemberDraft({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.isActive,
  });

  final String name;
  final String phoneNumber;
  final String email;
  final bool isActive;
}
