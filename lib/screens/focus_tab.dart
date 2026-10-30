import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';

class FocusTab extends StatefulWidget {
  const FocusTab({super.key});

  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> with WidgetsBindingObserver {
  bool _isRunning = false;
  int _secondsLeft = 25 * 60; // 25 minutes default
  final int _totalSeconds = 25 * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRunning &&
        (state == AppLifecycleState.paused ||
         state == AppLifecycleState.inactive)) {
      _failTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _completeTimer();
        }
      });
    });
  }

  void _failTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
    
    // Using Future.microtask to show dialog safely after rebuild
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Diqqat buzildi!'),
          content: const Text(
            'Siz ilovadan chiqib ketdingiz. Fokus bekor qilindi va coin berilmadi. Aldash taqiqlanadi!',
            style: TextStyle(color: AppColors.rose),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tushundim'),
            ),
          ],
        ),
      );
    });
  }

  void _completeTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });

    const earnedCoins = 5; // 5 coins for 25 mins
    context.read<AppState>().earnCoins(earnedCoins, 'Fokus sessiyasi (25 min)');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Fokus muvaffaqiyatli!', style: TextStyle(color: AppColors.emerald)),
        content: const Text('Siz mukammal diqqatni saqlab qoldingiz. +$earnedCoins coin!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Davom etish'),
          ),
        ],
      ),
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final progress = 1 - (_secondsLeft / _totalSeconds);

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Proof-of-Focus',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Diqqatni jamlang. Ilovadan chiqsangiz,\ncoin berilmaydi!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: AppColors.surface2,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            if (!_isRunning)
              ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'Boshlash',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _cancelTimer,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Bekor qilish (0 coin)',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
