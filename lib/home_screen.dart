import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

const MethodChannel platform = MethodChannel('dexterx.dev');

class HomeScreen extends StatefulWidget {
  static const routeName = '/';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const HomeScreen(this.flutterLocalNotificationsPlugin, {Key? key})
      : super(key: key);

  @override
  _HomeScreenState createState() =>
      _HomeScreenState(flutterLocalNotificationsPlugin);
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;

  List<Permission> permissions = [Permission.notification]; //+
  bool canContinue = false; // تمثل حالة الزر

  _HomeScreenState(this.flutterLocalNotificationsPlugin);
  bool s2 = false;

  @override
  void initState() {
    super.initState();
    _isAndroidPermissionGranted();
    _requestPermissions();
    checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    bool switchValue = false;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ElevatedButton(
          //   onPressed: () {
          //     _scheduleNotification();
          //   },
          //   child: const Text('Schedule Notification Every Minute'),
          // ),
          // ElevatedButton(
          //   onPressed: () async {
          //     await widget.flutterLocalNotificationsPlugin.cancelAll();
          //   },
          //   child: const Text('Stop'),
          // ),
          SwitchListTile(
            // switch at right side of label
            value: s2 &&
                _notificationsEnabled,
            onChanged: (bool value) {
              if (_notificationsEnabled) {
                setState(() {
                  s2 = value; // update value when switch changed
                });
                if (s2 == true) {
                  _scheduleNotification();
                } else {
                  widget.flutterLocalNotificationsPlugin.cancelAll();
                }
              } else {
                _requestPermissions();
              }
            },
            title: const Text("Turn on Notification"),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleNotification() async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Show a time picker to allow the user to select a custom time
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (selectedTime != null) {
      // Convert the selectedTime to a TZDateTime and schedule the notification
      DateTime now = DateTime.now();
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Notification Title',
        'Notification Body',
        scheduledDate,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'notification_payload',
      );
    }
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestPermission();
      setState(() {
        _notificationsEnabled = granted ?? false;
      });
    }
  }

  //------------------------------------

  // check permission
  Future<void> checkPermissions() async {
    bool arePermissionsGranted = await checkIfPermissionsGranted();
    setState(() {
      canContinue = arePermissionsGranted;
    });
  }

  // check if permissions enabled
  Future<bool> checkIfPermissionsGranted() async {
    Map<Permission, PermissionStatus> status = await permissions.request();
    bool granted = status.values.every((status) => status.isGranted);
    return granted;
  }
}
