import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notifications = NotificationService();
  await notifications.initialize();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MYLifePlanApp(notifications: notifications));
}

class MYLifePlanApp extends StatelessWidget {
  const MYLifePlanApp({super.key, required this.notifications});

  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(notificationService: notifications)..init(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MYLife Plan',
        theme: AppTheme.dark(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
