import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/mlp_environment.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_appearance.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_widgets.dart';

class MLPBackgroundSettingsPage extends StatefulWidget {
  const MLPBackgroundSettingsPage({
    super.key,
    this.picker = const MLPGalleryBackgroundPicker(),
  });
  final MLPBackgroundPicker picker;
  @override
  State<MLPBackgroundSettingsPage> createState() => _BackgroundSettingsState();
}

class _BackgroundSettingsState extends State<MLPBackgroundSettingsPage> {
  bool opening = false;
  String? status, failure;

  Future<void> choose(MLPAppearanceController controller) async {
    if (opening || controller.busy) return;
    setState(() {
      opening = true;
      status = null;
      failure = null;
    });
    try {
      final chosen = await controller.chooseBackground(widget.picker);
      if (mounted) {
        setState(
          () => status = chosen
              ? 'Yangi fon saqlandi va butun ilovaga qo‘llandi.'
              : 'Tanlash bekor qilindi. Avvalgi fon saqlandi.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => failure =
              error is PlatformException &&
                  [
                    'photo_access_denied',
                    'photo_access_restricted',
                  ].contains(error.code)
              ? 'Galereyaga ruxsat berilmadi. Qurilma sozlamalarida ruxsatni tekshirib, qayta urinib ko‘ring.'
              : error is FormatException
              ? error.message
              : controller.error ??
                    'Rasmni ochib bo‘lmadi. Boshqa rasm tanlang yoki qayta urinib ko‘ring.',
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> reset(MLPAppearanceController controller) async {
    final yes = await MLPConfirmationSheet.show(
      context,
      title: 'Standart fon tiklansinmi?',
      message:
          'Faqat tanlangan fon rasmi shu qurilmadan o‘chadi. Maqsadlar, vazifalar va boshqa ma’lumotlar saqlanadi.',
    );
    if (!yes || !mounted) return;
    setState(() {
      failure = null;
      status = null;
    });
    try {
      await controller.setBackground(null);
      if (mounted) {
        setState(() => status = 'Standart Liquid Glass foni tiklandi.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => failure =
              controller.error ?? 'Fon tiklanmadi. Qayta urinib ko‘ring.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = MLPAppearanceScope.maybeOf(context);
    if (controller == null) {
      return const MLPPage(
        title: 'Mavzu va fon',
        children: [
          MLPNotice(
            'Fon sozlamasi asosiy ilovada mavjud. Asosiy oynaga qayting.',
          ),
        ],
      );
    }
    final bytes = controller.backgroundBytes;
    final disabled = opening || controller.busy || !controller.initialized;
    return MLPPage(
      title: 'Mavzu va fon',
      children: [
        const Text(
          'Sizning makoningiz',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'iOS uslubidagi Liquid Glass · faol',
          style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height:
                248 +
                (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) *
                    180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF122C46),
                        MLPColors.background,
                        Color(0xFF231238),
                      ],
                    ),
                  ),
                ),
                if (bytes != null)
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    cacheWidth: 720,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66040916), Color(0xB3040916)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MLP',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fokusli hayot uchun',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      MLPLiquidSurface(
                        grouped: false,
                        radius: 18,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: MLPColors.turquoise,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bytes == null
                                    ? 'Standart qorong‘i fon'
                                    : 'Shaxsiy foningiz · ko‘rinish',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        MLPPrimaryButton(
          label: opening
              ? 'Galereya ochilmoqda…'
              : controller.busy
              ? 'Fon tayyorlanmoqda…'
              : 'Galereyadan rasm tanlash',
          icon: Icons.photo_library_outlined,
          busy: opening || controller.busy,
          onPressed: disabled ? null : () => choose(controller),
        ),
        const SizedBox(height: 10),
        MLPSecondaryButton(
          label: 'Standart fonni tiklash',
          icon: Icons.restart_alt_rounded,
          onPressed: disabled || (bytes == null && controller.error == null)
              ? null
              : () => reset(controller),
        ),
        const SizedBox(height: 18),
        if (failure != null || controller.error != null)
          MLPNotice(failure ?? controller.error!, warning: true),
        if (status != null)
          Semantics(liveRegion: true, child: MLPNotice(status!)),
        const MLPNotice(
          'Tanlangan rasm faqat shu qurilmada saqlanadi, serverga yuborilmaydi. Keyingi ochilishda ham fon tiklanadi. Matn o‘qilishi uchun ustiga qorong‘i qatlam qo‘yiladi.',
        ),
        const Text(
          'Rasmning eng uzun tomoni ko‘pi bilan 1440 pikselga keltiriladi. Saqlangan siqilgan nusxa 700 KB dan oshmaydi. Asl galereya rasmi o‘zgarmaydi.',
          style: TextStyle(color: MLPColors.muted, fontSize: 11, height: 1.6),
        ),
      ],
    );
  }
}
