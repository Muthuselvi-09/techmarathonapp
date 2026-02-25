import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/home/domain/event_models.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'core/widgets/chat_notification_overlay.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification actions here
  debugPrint('Notification background tap: ${notificationResponse.payload}');
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

late final ProviderContainer container;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  container = ProviderContainer();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification received: ${response.payload}');
        if (response.payload != null) {
          final parts = response.payload!.split('|');
          if (parts.length >= 2) {
            final senderId = parts[0];
            final senderName = parts[1];
            
            // Navigate to chat
            final router = container.read(routerProvider);
            router.push('/chat', extra: Participant(
              id: senderId,
              name: senderName,
              email: '',
              mobile: '',
              profileCompletion: 1.0,
            ));
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Log FCM Token for debugging
    final initialToken = await messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $initialToken');
    }

    if (initialToken != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': initialToken, 'lastActive': FieldValue.serverTimestamp()});
      }
    }

    // Handle initial message when the app is opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Handle messages when the app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Request permissions for Android 13+
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle token refresh
    messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    });

    // Handle auth state changes for token updates
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': token, 
            'isOnline': true,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      
      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TechMarathonApp(),
    ),
  );
}

void _handleMessageTap(RemoteMessage message) {
  final senderId = message.data['senderId'];
  final senderName = message.data['senderName'];
  
  if (senderId != null && senderName != null) {
    final router = container.read(routerProvider);
    router.push('/chat', extra: Participant(
      id: senderId,
      name: senderName,
      email: '',
      mobile: '',
      profileCompletion: 1.0,
    ));
  }
}

void _showForegroundNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction('reply', 'Reply', showsUserInterface: true),
      AndroidNotificationAction('cancel', 'Cancel', cancelNotification: true),
    ],
  );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
    payload: '${message.data['senderId']}|${message.data['senderName']}',
  );
}

class TechMarathonApp extends ConsumerWidget {
  const TechMarathonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ChatNotificationOverlay(
      child: MaterialApp.router(
        title: 'Event App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    );
  }
}
