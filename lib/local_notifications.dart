// This file handles all local notification logic for the Chorewars app.
// We use flutter_local_notifications for cross-platform notifications.
// The goal is to provide timely reminders and updates for tasks, shopping, chat, and household events.
//
// Key design decisions:
// - We group notifications by type (tasks, household, communication, shopping) for clarity and management.
// - Each notification type has its own channel and group, making it easy to control notification settings per category.
// - We use unique IDs for notifications based on content (e.g., taskId.hashCode) to avoid collisions.
// - We support scheduling, immediate, and recurring notifications.
// - We provide web stubs for notification actions, so the codebase is cross-platform.
// - All navigation from notifications is handled via payloads and a global navigator key.
//
// If you add a new notification type, create a new channel and group as needed, and follow the established pattern.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Global navigator key for handling navigation from notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LocalNotificationService {
  // Main plugin instance for notifications
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Channel Groups: Used to organize notification channels by feature area
  static const String taskGroup = 'tasks';
  static const String householdGroup = 'household';
  static const String communicationGroup = 'communication';
  static const String shoppingGroup = 'shopping';

  // Channel IDs: Each notification type gets its own channel for user control
  static const String taskRemindersChannel = 'task_reminders';
  static const String taskEventsChannel = 'task_events';
  static const String taskPointsChannel = 'task_points';
  static const String householdUpdatesChannel = 'household_updates';
  static const String householdReportsChannel = 'household_reports';
  static const String chatMessagesChannel = 'chat_messages';
  static const String shoppingRemindersChannel = 'shopping_reminders';
  static const String shoppingUpdatesChannel = 'shopping_updates';
  static const String expenseUpdatesChannel = 'expense_updates';

  // Initialization: Sets up the plugin, channels, and timezone data
  static Future<void> initialize() async {
    // We use the app launcher icon for notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings("@drawable/ic_launcher");
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const WindowsInitializationSettings windowsSettings =
        WindowsInitializationSettings(
      appName: 'Chorewars',
      appUserModelId: '8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a',
      guid: 'ad0dbfaa-c7ea-4f5e-8bbe-caf269b4170c',
    );

    InitializationSettings initializationSettings =
        const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      windows: windowsSettings,
    );

    // Initialize the plugin and set up the notification tap handler
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details);
      },
    );

    // On Android, create all notification channels and groups
    if (!kIsWeb) {
      await _createNotificationChannels();
    }

    // Always initialize timezone data for scheduling
    tz.initializeTimeZones();
  }

  // Creates all notification channel groups and channels for Android
  static Future<void> _createNotificationChannels() async {
    // Each group is created for logical separation in Android settings
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          const AndroidNotificationChannelGroup(taskGroup, 'Tasks',
              description: 'Notifications related to household tasks'),
        );

    // Household Group
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          const AndroidNotificationChannelGroup(householdGroup, 'Household',
              description: 'Notifications about household updates and reports'),
        );

    // Communication Group
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          const AndroidNotificationChannelGroup(
              communicationGroup, 'Communication',
              description: 'Chat and communication notifications'),
        );

    // Shopping Group
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          const AndroidNotificationChannelGroup(shoppingGroup, 'Shopping',
              description: 'Shopping list and expense notifications'),
        );

    // Create individual channels
    await _createNotificationChannel(
      taskRemindersChannel,
      'Task Reminders',
      'Reminders for upcoming tasks',
      taskGroup,
    );

    await _createNotificationChannel(
      taskEventsChannel,
      'Task Events',
      'Updates about task assignments and completions',
      taskGroup,
    );

    await _createNotificationChannel(
      taskPointsChannel,
      'Task Points',
      'Notifications about earned points and achievements',
      taskGroup,
    );

    await _createNotificationChannel(
      householdUpdatesChannel,
      'Household Updates',
      'Important household announcements and changes',
      householdGroup,
    );

    await _createNotificationChannel(
      householdReportsChannel,
      'Household Reports',
      'Weekly household activity summaries',
      householdGroup,
    );

    await _createNotificationChannel(
      chatMessagesChannel,
      'Chat Messages',
      'New chat messages and mentions',
      communicationGroup,
    );

    await _createNotificationChannel(
      shoppingRemindersChannel,
      'Shopping Reminders',
      'Daily shopping list reminders',
      shoppingGroup,
    );

    await _createNotificationChannel(
      shoppingUpdatesChannel,
      'Shopping Updates',
      'Updates to the shopping list',
      shoppingGroup,
    );

    await _createNotificationChannel(
      expenseUpdatesChannel,
      'Expense Updates',
      'Notifications about new expenses and bills',
      shoppingGroup,
    );
  }

  // Helper to create a single notification channel
  static Future<void> _createNotificationChannel(
    String channelId,
    String channelName,
    String description,
    String groupId,
  ) async {
    // We use high importance and vibration for all channels by default
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: description,
      groupId: groupId,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handles what happens when a user taps a notification
  static void _handleNotificationTap(NotificationResponse details) {
    if (details.payload != null) {
      // We use payloads to determine navigation
      final String payload = details.payload!;
      if (payload.startsWith('task_')) {
        // TODO: Navigate to task details screen
      } else if (payload.startsWith('shopping_')) {
        // TODO: Navigate to shopping list
      } else if (payload.startsWith('chat_')) {
        // TODO: Navigate to chat screen
      }
    }
  }

  // Schedules a notification to remind the user about a task
  static Future<void> scheduleTaskReminder(String taskId, String taskName,
      DateTime dueDate, int leadTimeDays) async {
    // On web, we just print instead of scheduling
    if (kIsWeb) {
      print(
          '[Web Stub] schedule reminder for task: $taskName, due in $leadTimeDays days');
      return;
    }

    // We use the timezone package to ensure correct scheduling
    final scheduledTime = tz.TZDateTime.from(
        dueDate.subtract(Duration(days: leadTimeDays)), tz.local);
    await _notificationsPlugin.zonedSchedule(
      taskId.hashCode,
      'Task Reminder',
      'Your task "$taskName" is due in $leadTimeDays days(s)!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminder notifications for tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: taskId,
    );
  }

  // Cancels a scheduled task reminder by taskId
  static void cancelTaskReminder(String taskId) {
    if (kIsWeb) {
      print('[Web Stub] cancel reminder for task: $taskId');
      return;
    }

    int notificationId = taskId.hashCode;
    _notificationsPlugin.cancel(notificationId);
  }

  // Shows a notification when an expense is added
  static Future<void> sendExpenseNotification(
      double amount, String category) async {
    if (kIsWeb) {
      print('[Web Stub] Expense Added: \$$amount in $category');
      return;
    }

    await _notificationsPlugin.show(
      category.hashCode,
      'Expense Added',
      'An expense of \$${amount.toStringAsFixed(2)} was added in $category.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          expenseUpdatesChannel,
          'Expense Updates',
          channelDescription: 'Notifications for new expenses',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: shoppingGroup,
        ),
        iOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      payload: 'expense_$category',
    );
  }

  // Shows a notification for a task event (e.g., assigned, completed)
  static Future<void> sendTaskNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('[Web Notification] $title: $body');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
            ?.showSnackBar(SnackBar(
          content: Text('$title: $body'),
          duration: const Duration(seconds: 3),
        ));
      });
      return;
    }

    await _notificationsPlugin.show(
      title.hashCode, // unique id for the notification
      title, // title of the notification
      body, // body of the notification
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_events', // channel id
          'Task Events', // channel name
          channelDescription: "Notifications for task events",
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      payload: payload, // helps handle notification tap
    );
  }

  // Schedules a daily shopping reminder for the user
  static Future<void> scheduleShoppingReminder({
    required String householdID,
    required String userID,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) {
      print(
          '[Web Stub] schedule shopping reminder for household: $householdID, user: $userID at $hour:$minute');
      return;
    }

    // Query Firestore for the user's shopping list to count items
    final snap = await FirebaseFirestore.instance
        .collection('household')
        .doc(householdID)
        .collection('members')
        .doc(userID)
        .collection('shopping_list')
        .where('done', isEqualTo: false)
        .get();
    final count = snap.docs.length;

    // Schedule for the next occurrence of the specified time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      1000,
      'Shopping Reminder',
      count > 0
          ? 'You have $count items in your shopping list.'
          : 'Your shopping list is empty.',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'shopping_reminders',
          'Shopping Reminders',
          channelDescription: 'Notifications for shopping reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'shopping_reminder',
    );
  }

  // Cancels the daily shopping reminder
  static Future<void> cancelShoppingReminder() async {
    if (kIsWeb) {
      print('[Web Stub] cancel shopping reminder');
      return;
    }
    await _notificationsPlugin.cancel(1000);
  }

  // Shows a notification when a shopping item is added
  static Future<void> sendShoppingItemAddedNotification(String itemName) async {
    if (kIsWeb) {
      print('[Web Stub] Shopping item added: $itemName');
      return;
    }

    await _notificationsPlugin.show(
      itemName.hashCode,
      'Item Added',
      'You added "$itemName" to your shopping list.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shopping_item_added',
          'Shopping Item Added',
          channelDescription: 'Notifications when you add a new shopping item',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      payload: 'shopping_added',
    );
  }

  // Shows a notification when points are earned for a task
  static Future<void> sendTaskPointsNotification(
      String taskName, int points) async {
    if (kIsWeb) {
      print('[Web Stub] Task points earned: $points for task: $taskName');
      return;
    }

    await _notificationsPlugin.show(
      ('points_$taskName').hashCode,
      'Points Earned!',
      'You earned $points points for completing "$taskName"',
      NotificationDetails(
        android: AndroidNotificationDetails(
          taskPointsChannel,
          'Task Points',
          channelDescription:
              'Notifications about earned points and achievements',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: taskGroup,
        ),
        iOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      payload: 'points_earned_$taskName',
    );
  }

  // Shows a notification for household updates
  static Future<void> sendHouseholdUpdateNotification(
      String title, String message) async {
    if (kIsWeb) {
      print('[Web Stub] Household update: $title - $message');
      return;
    }

    await _notificationsPlugin.show(
      title.hashCode,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          householdUpdatesChannel,
          'Household Updates',
          channelDescription: 'Important household announcements and changes',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: householdGroup,
        ),
        iOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      payload: 'household_update',
    );
  }

  // Schedules a weekly household report notification (Sunday 9am)
  static Future<void> scheduleWeeklyHouseholdReport(String householdId) async {
    if (kIsWeb) {
      print('[Web Stub] Schedule weekly report for household: $householdId');
      return;
    }

    // Find the next Sunday at 9am
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    // Move to next Sunday if needed
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    await _notificationsPlugin.zonedSchedule(
      'weekly_report_$householdId'.hashCode,
      'Weekly Household Report',
      'Your weekly household activity summary is ready!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          householdReportsChannel,
          'Household Reports',
          channelDescription: 'Weekly household activity summaries',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: householdGroup,
        ),
        iOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );
  }

  // Shows a notification for a new chat message
  static Future<void> sendChatMessageNotification(String sender, String message,
      {String? chatId}) async {
    if (kIsWeb) {
      print('[Web Stub] Chat message from $sender: $message');
      return;
    }

    // Use chatId for grouping if available, otherwise use a timestamp
    final int notificationId = chatId != null
        ? chatId.hashCode
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      notificationId,
      sender,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chatMessagesChannel,
          'Chat Messages',
          channelDescription: 'New chat messages and mentions',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: communicationGroup,
        ),
        iOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      payload: chatId != null ? 'chat_message_$chatId' : 'chat_message',
    );
  }

  // Cancels all notifications for a specific channel
  static Future<void> cancelChannelNotifications(String channelId) async {
    if (kIsWeb) {
      print('[Web Stub] Cancel notifications for channel: $channelId');
      return;
    }

    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      if (notification.payload?.contains(channelId) ?? false) {
        await _notificationsPlugin.cancel(notification.id);
      }
    }
  }
}
