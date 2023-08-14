import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/domain/entities/push_message.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  int pushMessageId = 0;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final Future<void> Function()? requestLocalNotificationsPermissions;
  final void Function({
    required int id,
    String? title,
    String? body,
    String? data,
  })? showLocalNotification;

  NotificationsBloc(
      {this.requestLocalNotificationsPermissions, this.showLocalNotification})
      : super(const NotificationsState()) {
    on<NotificationsStatusChanged>(_notificationStatusChanged);
    on<NotificationsReceived>(_onPushMessageReceived);

    // Verificar estado de las notificaciones
    _initialStatusCheck();
    // Listener para notificaciones en Foreground
    _onForegroundMessage();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _onPushMessageReceived(
      NotificationsReceived event, Emitter<NotificationsState> emit) {
    emit(state
        .copyWith(notifications: [event.pushMessage, ...state.notifications]));
  }

  void _notificationStatusChanged(
      NotificationsStatusChanged event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(status: event.status));
    _getFCMToken();
  }

  void _initialStatusCheck() async {
    final settings = await messaging.getNotificationSettings();
    add(NotificationsStatusChanged(settings.authorizationStatus));
    /*
      cristian@gmail.com: [
        token1,
        token2,
        token3,
      ]
     */
  }

  void _getFCMToken() async {
    // final settings = await messaging.getNotificationSettings();
    if (state.status != AuthorizationStatus.authorized) return;
    final token = await messaging.getToken();
    print(token);
  }

  void handleRemoveMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      final notification = PushMessage(
          messageId:
              message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          sentDate: message.sentTime ?? DateTime.now(),
          data: message.data,
          imageUrl: Platform.isAndroid
              ? message.notification!.android?.imageUrl
              : message.notification!.apple?.imageUrl);

      if (showLocalNotification != null) {
        showLocalNotification!(
            id: ++pushMessageId,
            body: notification.body,
            data: notification.messageId,
            title: notification.title);
      }

      add(NotificationsReceived(notification));
    }
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoveMessage);
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Solicitar permiso a la "Local Notifications"
    if (requestLocalNotificationsPermissions != null) {
      await requestLocalNotificationsPermissions!();
      // await LocalNotifications.requestPermissionLocalNotifications();
    }

    add(NotificationsStatusChanged(settings.authorizationStatus));

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  PushMessage? getMessageById(String pushMessageId) {
    final exist = state.notifications
        .any((element) => element.messageId == pushMessageId);
    if (!exist) return null;

    return state.notifications
        .firstWhere((element) => element.messageId == pushMessageId);
  }
}
