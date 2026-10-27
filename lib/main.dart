import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'demo/demo_app.dart';
import 'demo/demo_store.dart';
import 'app/theme/mlp_design_system.dart';
import 'core/design_system/mlp_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MLPBootstrap());
}

class MLPBootstrap extends StatefulWidget {
  const MLPBootstrap({super.key});
  @override
  State<MLPBootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<MLPBootstrap> {
  DemoStore? store;
  late Future<SharedPreferences> loading;
  @override
  void initState() {
    super.initState();
    loading = load();
  }

  Future<SharedPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final next = DemoStore(prefs);
    try {
      await next.init();
    } catch (_) {
      next.dispose();
      rethrow;
    }
    if (!mounted) {
      next.dispose();
      throw StateError('Ilova yopildi.');
    }
    store?.dispose();
    store = next;
    return prefs;
  }

  @override
  void dispose() {
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return MplDemoApp(store: store!, prefs: snapshot.data!);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MLPTheme.dark,
        home: MLPScaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? MLPErrorState(
                      message:
                          'Mahalliy saqlovni ochib bo‘lmadi. Mavjud ma’lumotlar o‘chirilmagan. Qurilmadagi bo‘sh joyni tekshirib qayta urinib ko‘ring.',
                      onRetry: () => setState(() => loading = load()),
                    )
                  : const MLPLoadingState(label: 'MLP ochilmoqda…'),
            ),
          ),
        ),
      );
    },
  );
}
