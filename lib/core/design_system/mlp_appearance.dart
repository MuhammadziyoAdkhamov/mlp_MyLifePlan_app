import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MLPBackgroundPicker {
  Future<Uint8List?> choose();
  Future<Uint8List?> recoverLostImage();
}

class MLPGalleryBackgroundPicker implements MLPBackgroundPicker {
  const MLPGalleryBackgroundPicker();
  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > MLPBackgroundImage.maxInputBytes) {
      throw const FormatException('Rasm 16 MB dan kichik bo‘lsin.');
    }
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> choose() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1440,
      maxHeight: 1440,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<Uint8List?> recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final result = await ImagePicker().retrieveLostData();
    if (result.exception != null) throw result.exception!;
    final file = result.files?.firstOrNull;
    return file == null ? null : _read(file);
  }
}

abstract final class MLPBackgroundImage {
  static const maxDimension = 1440;
  static const maxInputBytes = 16 * 1024 * 1024;
  // Base64 plus its small envelope remains below one MiB in preferences.
  static const maxImageBytes = 700 * 1024;
  static const maxStoredCharacters = 1024 * 1024;

  static Future<Uint8List> prepare(Uint8List source) async {
    if (source.isEmpty || source.length > maxInputBytes) {
      throw const FormatException('Rasm bo‘sh yoki 16 MB chegarasidan katta.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(source);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final factor = math.min(
        1.0,
        maxDimension / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * factor).round()),
        targetHeight: math.max(1, (descriptor.height * factor).round()),
      );
      var current = (await codec.getNextFrame()).image;
      image = current;
      var width = current.width;
      var height = current.height;
      for (var attempt = 0; attempt < 9; attempt++) {
        final encoded = await current.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (encoded == null) {
          throw const FormatException('Rasmni tayyorlab bo‘lmadi.');
        }
        final bytes = encoded.buffer.asUint8List(
          encoded.offsetInBytes,
          encoded.lengthInBytes,
        );
        if (bytes.length <= maxImageBytes) {
          return Uint8List.fromList(bytes).asUnmodifiableView();
        }
        width = math.max(1, (width * .75).floor());
        height = math.max(1, (height * .75).floor());
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImageRect(
          current,
          ui.Rect.fromLTWH(
            0,
            0,
            current.width.toDouble(),
            current.height.toDouble(),
          ),
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.medium,
        );
        final picture = recorder.endRecording();
        final resized = await picture.toImage(width, height);
        picture.dispose();
        current.dispose();
        current = resized;
        image = current;
      }
      throw const FormatException('Rasmni kichraytirib qayta tanlang.');
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static Future<void> validateStored(Uint8List bytes) async {
    if (bytes.isEmpty ||
        bytes.length > maxImageBytes ||
        bytes.length < 8 ||
        bytes[0] != 137 ||
        bytes[1] != 80 ||
        bytes[2] != 78 ||
        bytes[3] != 71) {
      throw const FormatException('Saqlangan fon rasmi noto‘g‘ri.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > maxDimension ||
          descriptor.height > maxDimension ||
          descriptor.width < 1 ||
          descriptor.height < 1) {
        throw const FormatException('Saqlangan fon o‘lchami noto‘g‘ri.');
      }
      codec = await descriptor.instantiateCodec();
      image = (await codec.getNextFrame()).image;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}

class MLPAppearanceController extends ChangeNotifier {
  static const storageKey = 'mlp_appearance_background_v1';
  SharedPreferences? _prefs;
  Uint8List? _bytes;
  Future<void> _queue = Future<void>.value();
  bool initialized = false, busy = false, _disposed = false;
  String? error;
  Uint8List? get backgroundBytes => _bytes;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init(SharedPreferences prefs) async {
    if (initialized) return;
    _prefs = prefs;
    try {
      final raw = prefs.get(storageKey);
      if (raw != null) {
        if (raw is! String ||
            raw.length > MLPBackgroundImage.maxStoredCharacters) {
          throw const FormatException('Fon saqlovi noto‘g‘ri.');
        }
        final data = jsonDecode(raw);
        if (data is! Map || data['version'] != 1 || data['png'] is! String) {
          throw const FormatException('Fon formati noto‘g‘ri.');
        }
        final bytes = base64Decode(data['png'] as String);
        await MLPBackgroundImage.validateStored(bytes);
        _bytes = bytes.asUnmodifiableView();
      }
    } catch (_) {
      error =
          'Saqlangan fonni ochib bo‘lmadi. Standart fon ishlatilmoqda; asl yozuv o‘chirilmagan.';
    }
    initialized = true;
    _notify();
  }

  Future<void> setBackground(Uint8List? source) {
    final operation = _queue.then((_) async {
      if (!initialized || _prefs == null || _disposed) {
        throw StateError('Fon sozlamasi hali tayyor emas.');
      }
      busy = true;
      error = null;
      _notify();
      try {
        final bytes = source == null
            ? null
            : await MLPBackgroundImage.prepare(source);
        final saved = bytes == null
            ? await _prefs!.remove(storageKey)
            : await _prefs!.setString(
                storageKey,
                jsonEncode({'version': 1, 'png': base64Encode(bytes)}),
              );
        if (!saved) throw StateError('Qurilma fon rasmini saqlamadi.');
        _bytes = bytes;
      } catch (failure) {
        error = failure is FormatException
            ? failure.message
            : 'Fon saqlanmadi. Avvalgi fon saqlandi. Qayta urinib ko‘ring.';
        try {
          await _prefs!.reload();
        } catch (_) {
          /* Published appearance stays intact. */
        }
        rethrow;
      } finally {
        busy = false;
        _notify();
      }
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }

  Future<bool> chooseBackground(MLPBackgroundPicker picker) async {
    final source = await picker.choose();
    if (source == null) return false;
    await setBackground(source);
    return true;
  }

  Future<void> recoverBackground(MLPBackgroundPicker picker) async {
    try {
      final source = await picker.recoverLostImage();
      if (source != null) await setBackground(source);
    } catch (_) {
      error =
          'Galereyadagi tanlov tiklanmadi. Sozlamalarda rasmni qayta tanlang.';
      _notify();
    }
  }

  Map<String, dynamic> exportState() => {
    'version': 1,
    'style': 'ios-liquid-glass-dark',
    'png': _bytes == null ? null : base64Encode(_bytes!),
  };

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MLPAppearanceScope extends InheritedNotifier<MLPAppearanceController> {
  const MLPAppearanceScope({
    super.key,
    required MLPAppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static MLPAppearanceController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MLPAppearanceScope>()
      ?.notifier;
}

class MLPAppearanceHost extends StatefulWidget {
  const MLPAppearanceHost({
    super.key,
    required this.prefs,
    required this.child,
  });
  final SharedPreferences prefs;
  final Widget child;
  @override
  State<MLPAppearanceHost> createState() => _AppearanceHostState();
}

class _AppearanceHostState extends State<MLPAppearanceHost> {
  final controller = MLPAppearanceController();
  @override
  void initState() {
    super.initState();
    unawaited(
      controller.init(widget.prefs).then((_) {
        if (mounted) {
          return controller.recoverBackground(
            const MLPGalleryBackgroundPicker(),
          );
        }
      }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MLPAppearanceScope(controller: controller, child: widget.child);
}
