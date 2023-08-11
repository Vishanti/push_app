part of 'notifications_bloc.dart';

class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationsStatusChanged extends NotificationsEvent {
  final AuthorizationStatus status;
  NotificationsStatusChanged(this.status);
}

class NotificationsReceived extends NotificationsEvent {
  final PushMessage pushMessage;
  NotificationsReceived(this.pushMessage);
}