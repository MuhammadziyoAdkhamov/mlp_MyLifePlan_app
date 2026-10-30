import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';

class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        
        // Temporarily stop scanner
        controller.stop();

        // Give 10 coins
        context.read<AppState>().earnCoins(10, 'QR Check-in (+10)');

        // Show dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 64),
                SizedBox(height: 16),
                Text('Muvaffaqiyatli!', style: TextStyle(color: AppColors.emerald)),
              ],
            ),
            content: const Text(
              'O\'quv markazi check-in tasdiqlandi.\n+10 Coin hamyoningizga tushdi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Davom etish', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );

        // Resume scanner after 2 seconds to prevent spam
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _isProcessing = false);
        controller.start();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Kamerani O\'quv markazidagi\nQR kodga qarating',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
