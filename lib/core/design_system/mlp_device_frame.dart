import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';

/// Optional web presentation frame. This is not a native device simulator.
class MLPIPhoneFrame extends StatefulWidget {
  const MLPIPhoneFrame({super.key, required this.child, this.enabled = kIsWeb});
  final Widget child;
  final bool enabled;

  @override
  State<MLPIPhoneFrame> createState() => _MLPIPhoneFrameState();
}

class _MLPIPhoneFrameState extends State<MLPIPhoneFrame> {
  bool showFrame = true;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Short windows, mobile, keyboard and large text use the full layout.
      if (!widget.enabled ||
          constraints.maxWidth < 720 ||
          constraints.maxHeight < 650 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
          MediaQuery.viewInsetsOf(context).bottom > 0) {
        return widget.child;
      }
      return ColoredBox(
        color: MLPColors.background,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'MLP · Mobil ko‘rinish namunasi',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => showFrame = !showFrame),
                      icon: Icon(
                        showFrame
                            ? CupertinoIcons.fullscreen
                            : CupertinoIcons.device_phone_portrait,
                        size: 18,
                      ),
                      label: Text(
                        showFrame ? 'Keng ekranga o‘tish' : 'Mobil ko‘rinish',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: showFrame
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: AspectRatio(
                          aspectRatio: 9 / 19.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(44),
                              border: Border.all(
                                color: MLPColors.border,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: MLPColors.turquoise.withValues(
                                    alpha: .12,
                                  ),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: LayoutBuilder(
                                builder: (context, viewport) {
                                  final original = MediaQuery.of(context);
                                  return MediaQuery(
                                    data: original.copyWith(
                                      size: viewport.biggest,
                                      padding: const EdgeInsets.only(
                                        top: 44,
                                        bottom: 24,
                                      ),
                                      viewPadding: const EdgeInsets.only(
                                        top: 44,
                                        bottom: 24,
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        widget.child,
                                        const Positioned(
                                          top: 12,
                                          left: 0,
                                          right: 0,
                                          child: IgnorePointer(
                                            child: Center(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(20),
                                                      ),
                                                ),
                                                child: SizedBox(
                                                  width: 96,
                                                  height: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          bottom: 9,
                                          left: 0,
                                          right: 0,
                                          child: IgnorePointer(
                                            child: Center(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.white38,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(4),
                                                      ),
                                                ),
                                                child: SizedBox(
                                                  width: 100,
                                                  height: 4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : widget.child,
            ),
          ],
        ),
      );
    },
  );
}
