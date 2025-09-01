import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class IdInputForm extends StatefulWidget {
  final String mode; // 'manual' or 'auto'
  final Function(Map<String, String>) onSave;

  const IdInputForm({super.key, required this.mode, required this.onSave});

  @override
  State<IdInputForm> createState() => _IdInputFormState();
}

class _IdInputFormState extends State<IdInputForm> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  bool _scanning = false;

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _mockNfcScan() async {
    try {
      setState(() => _scanning = true);

      // Wait for an NFC tag
      NFCTag tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 20));

      // Display the UID
      _idController.text = tag.id;

      // Finish scanning
      await FlutterNfcKit.finish();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC scan failed: $e')),
      );
    } finally {
      setState(() => _scanning = false);
    }
  }

  void _handleSave() {
    final id = _idController.text.trim();
    final label = _labelController.text.trim();

    if (id.isEmpty || label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill both ID and Name/Label")),
      );
      return;
    }

    widget.onSave({
      "id": id,
      "label": label,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (widget.mode == 'manual') ...[
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: "Name/Label",
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _scanning ? null : _mockNfcScan,
              icon: const Icon(Icons.nfc),
              label: Text(_scanning ? 'Scanning...' : 'Scan with NFC'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Detected UID',
                border: OutlineInputBorder(),
              ),
              readOnly: true,       // Makes it non-editable
              enabled: false,       // Makes it look disabled (greyed out) and prevents taps
              showCursor: false,
              enableInteractiveSelection: false, // prevents text selectio             
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: "Name/Label",
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSave,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
