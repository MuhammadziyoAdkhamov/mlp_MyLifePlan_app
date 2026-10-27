import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'demo/demo_app.dart';
import 'demo/demo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = DemoStore(prefs);
  await store.init();
  runApp(MplDemoApp(store: store, prefs: prefs, enableOnboarding: true));
}
