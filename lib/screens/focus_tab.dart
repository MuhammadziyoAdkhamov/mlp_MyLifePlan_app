import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/mlp_design_system.dart';
import '../core/design_system/mlp_liquid_glass.dart';
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
      mlpShowDialog(
        context: context,
        builder: (_) => MLPLiquidSurface(
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: MLPColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Diqqat buzildi!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Siz ilovadan chiqib ketdingiz. Fokus bekor qilindi va coin berilmadi. Aldash taqiqlanadi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MLPColors.secondaryText),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tushundim'),
                  ),
                ),
              ],
            ),
          ),
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

    mlpShowDialog(
      context: context,
      builder: (_) => MLPLiquidSurface(
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: MLPColors.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Fokus muvaffaqiyatli!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MLPColors.success,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Siz mukammal diqqatni saqlab qoldingiz. +$earnedCoins coin!',
                textAlign: TextAlign.center,
                style: TextStyle(color: MLPColors.secondaryText),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Davom etish'),
                ),
              ),
            ],
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [MLPColors.turquoise, MLPColors.primary],
                ).createShader(bounds),
                child: const Text(
                  'Proof-of-Focus',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Diqqatni jamlang. Ilovadan chiqsangiz,\ncoin berilmaydi!',
                textAlign: TextAlign.center,
                style: TextStyle(color: MLPColors.secondaryText),
              ),
              const SizedBox(height: 60),
              MLPLiquidSurface(
                radius: 140,
                blur: true,
                tint: MLPColors.primary.withValues(alpha: 0.1),
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(
                            Color.lerp(
                              MLPColors.turquoise,
                              MLPColors.primary,
                              progress,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: MLPColors.text,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              if (!_isRunning)
                MLPPressResponse(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: const LinearGradient(
                        colors: [
                          MLPColors.turquoise,
                          MLPColors.primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MLPColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
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
                    ),
                  ),
                )
              else
                MLPLiquidSurface(
                  radius: 100,
                  blur: false,
                  child: TextButton(
                    onPressed: _cancelTimer,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Bekor qilish (0 coin)',
                      style: TextStyle(
                        fontSize: 16,
                        color: MLPColors.secondaryText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
