import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '/models/task.dart';
import '/ui/pages/notification_screen.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String selectedNotificationPayload = '';

  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  initializeNotification() async {
    tz.initializeTimeZones();
    _configureSelectNotificationSubject();
    await _configureLocalTimeZone();
    // await requestIOSPermissions(flutterLocalNotificationsPlugin);
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('appicon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          debugPrint('notification payload: ' + payload);
        }
        selectNotificationSubject.add(payload!);
      },
    );
  }

  displayNotification({required String title, required String body}) async {
    debugPrint('doing test');
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.max, priority: Priority.high);
    var iOSPlatformChannelSpecifics = const IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  scheduledNotification(int hour, int minutes, Task task) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id!,
      task.title,
      task.note,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      _nextInstanceOfTenAM(hour, minutes, task),
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description'),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${task.title}|${task.note}|${task.startTime}|',
    );
  }

  tz.TZDateTime _nextInstanceOfTenAM(int hour, int minutes, Task task) {
    int taskYear = int.parse(task.date!.split('/')[2]);
    int taskMonth = int.parse(task.date!.split('/')[0]);
    int taskDay = int.parse(task.date!.split('/')[1]);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, taskYear, taskMonth, taskDay, hour, minutes);

    if (scheduledDate.isBefore(now)) {
      if (task.repeat == 'Daily') {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      if (task.repeat == 'Weekly') {
        scheduledDate = tz.TZDateTime(
            tz.local, taskYear, taskMonth, taskDay + 7, hour, minutes);
      }
      if (task.repeat == 'Monthly') {
        scheduledDate = tz.TZDateTime(
            tz.local, taskYear, taskMonth + 1, taskDay, hour, minutes);
      }
    }
    scheduledDate = remindTime(task, scheduledDate);
    debugPrint("final scheduled date = $scheduledDate");
    return scheduledDate;
  }

  tz.TZDateTime remindTime(Task task, tz.TZDateTime scheduledDate) {
    if (task.remind == 5) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 5));
    } else if (task.remind == 10) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));
    } else if (task.remind == 15) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 15));
    } else if (task.remind == 20) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 20));
    }
    return scheduledDate;
  }


  cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin.cancel(task.id!);
  }

  cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    Get.dialog(Text(body!));
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      debugPrint('My payload is ' + payload);
      await Get.to(() => NotificationScreen(
            payLoad: payload,
          ));
    });
  }

  void wasApplicationLaunchedFromNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails == null) {
      debugPrint('');
    } else {
      if (notificationAppLaunchDetails.didNotificationLaunchApp) {
        Get.to(() =>
            NotificationScreen(payLoad: notificationAppLaunchDetails.payload!));
      }
    }
  }
}
