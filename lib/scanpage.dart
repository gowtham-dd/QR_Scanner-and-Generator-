import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _launchURL(String url) async {
    // Check if the URL has the proper format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    final Uri uri = Uri.parse(url);

    // Attempt to launch the URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch the URL'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String imagePath = image.path;
      _scanQRCode(imagePath);
    }
  }

  void _scanQRCode(String imagePath) async {
    final MobileScannerController scanner = MobileScannerController();
    final BarcodeCapture? capture = await scanner.analyzeImage(imagePath);
    if (capture != null) {
      final List<Barcode> barcodes = capture.barcodes;
      final String? rawValue =
          barcodes.isNotEmpty ? barcodes.first.rawValue : null;
      if (rawValue != null) {
        final Uint8List imageData = await File(imagePath).readAsBytes();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: GestureDetector(
                onTap: () {
                  _launchURL(rawValue);
                },
                child: Text(
                  rawValue,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              content: Image.memory(imageData),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in the selected image.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popAndPushNamed(context, "/generate");
            },
            icon: const Icon(
              Icons.qr_code,
            ),
          ),
        ],
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: true,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          for (final barcode in barcodes) {
            print('Barcode found! ${barcode.rawValue}');
          }
          if (image != null && barcodes.isNotEmpty) {
            final String? rawValue = barcodes.first.rawValue;
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: GestureDetector(
                    onTap: () {
                      if (rawValue != null) {
                        _launchURL(rawValue);
                      }
                    },
                    child: Text(
                      rawValue ?? "",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  content: Image(
                    image: MemoryImage(image),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
