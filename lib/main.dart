import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final app = await Firebase.initializeApp(
    options: (defaultTargetPlatform == TargetPlatform.android)
        ? DefaultFirebaseOptions.android
        : DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Firebase initialized for project: ${app.options.projectId}');
  
  runApp(
    const ProviderScope(
      child: TechMarathonApp(),
    ),
  );
}

class TechMarathonApp extends ConsumerWidget {
  const TechMarathonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Tech Marathon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
