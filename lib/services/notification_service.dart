import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // ---------------------------------------------------------------------------
  // Local Notifications Plugin & Android Channel Configuration
  // ---------------------------------------------------------------------------
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'tech_drive_high_importance_channel',
    'Tech Drive Notifications',
    description:
        'High importance notifications for Tech Drive orders and alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static final Set<String> _seenNotificationDocIds = <String>{};
  static StreamSubscription<QuerySnapshot>? _notificationSubscription;
  static String? _activeUid;
  static final DateTime _sessionStartTime = DateTime.now();

  /// Initialize Local Notifications plugin and Android Notification Channel
  static Future<void> initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_androidChannel);
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == false) {
        debugPrint("⚠️ Android Notification permission was denied by user.");
      }
    }
  }

  /// Start global real-time Firestore notification listener for active user.
  /// Prevents multiple duplicate listeners from being created during rebuilds.
  static void startListening(String uid) {
    if (uid.isEmpty) return;

    // If already listening to the same UID, keep existing listener
    if (_activeUid == uid && _notificationSubscription != null) {
      return;
    }

    // Stop existing listener if user changed
    stopListening();
    _activeUid = uid;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final docId = doc.id;
            final data = doc.data();

            if (data == null) continue;

            // Prevent duplicate triggers for the same notification document
            if (_seenNotificationDocIds.contains(docId)) continue;
            _seenNotificationDocIds.add(docId);

            // Ignore old notifications created before the current app session started
            final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
            final DateTime? createdAt = createdAtTimestamp?.toDate();
            if (createdAt != null && createdAt.isBefore(_sessionStartTime)) {
              continue;
            }

            // Ignore notifications already marked as read
            final bool isRead = data['isRead'] as bool? ?? false;
            if (isRead) continue;

            // Trigger local heads-up notification with sound
            final String title = data['title'] as String? ?? 'Tech Drive Notification';
            final String body = data['body'] as String? ?? '';
            final String orderId = data['orderId'] as String? ?? '';

            showLocalNotification(
              id: docId.hashCode,
              title: title,
              body: body,
              payload: orderId,
            );
          }
        }
      },
      onError: (err) {
        debugPrint("❌ Global Notification Listener Error: $err");
      },
    );
  }

  /// Stop and dispose the active notification listener (called on logout)
  static void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _activeUid = null;
    _seenNotificationDocIds.clear();
  }

  /// Stream of real-time unread notification count for badge display
  static Stream<int> getUnreadCountStream(String uid) {
    if (uid.isEmpty) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Displays a local heads-up notification with max importance, sound & vibration
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tech_drive_high_importance_channel',
      'Tech Drive Notifications',
      channelDescription:
          'High importance notifications for Tech Drive orders and alerts.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // In-app Firestore notification (CLIENT — fully implemented)
  // ---------------------------------------------------------------------------
  /// Writes a notification document to users/{receiverId}/notifications/{docId}.
  static Future<void> saveNotification({
    required String receiverId,
    required String senderId,
    required String orderId,
    required String title,
    required String body,
    required String type,
  }) async {
    if (receiverId.isEmpty) return; // guard against empty UID
    final docId = '${orderId}_${type}_$receiverId';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .doc(docId)
        .set({
      'userId': receiverId,
      'orderId': orderId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // FCM push notification — NO-OP stub (backend required for Cloud Functions)
  // ---------------------------------------------------------------------------
  static Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Prepared for future FCM Cloud Function integration
  }
}