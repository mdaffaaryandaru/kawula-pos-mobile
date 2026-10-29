import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetUserPinDialog extends StatefulWidget {
  const SetUserPinDialog({super.key, required this.userName});

  final String userName;

  @override
  State<SetUserPinDialog> createState() => _SetUserPinDialogState();
}

class _SetUserPinDialogState extends State<SetUserPinDialog> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Atur PIN · ${widget.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'PIN baru'),
            ),
            TextField(
              controller: _confirmationController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'Ulangi PIN'),
            ),
            if (_errorMessage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final pin = _pinController.text;
            if (pin.length != 4) {
              setState(() => _errorMessage = 'PIN harus tepat 4 digit.');
              return;
            }
            if (pin != _confirmationController.text) {
              setState(() => _errorMessage = 'Konfirmasi PIN tidak sama.');
              return;
            }
            Navigator.pop(context, pin);
          },
          child: const Text('Simpan PIN'),
        ),
      ],
    );
  }
}
