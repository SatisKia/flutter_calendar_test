import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State {
  double contentWidth  = 0.0;
  double contentHeight = 0.0;

  DeviceCalendarPlugin? deviceCalendarPlugin;
  String? eventId;
  String title = '';
  DateTime start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour + 1);
  DateTime end = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour + 2);
  String description = '';

  Future<bool> requestPermissions() async {
    try {
      Result<bool> permissionsGranted = await deviceCalendarPlugin!.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await deviceCalendarPlugin!.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return false;
        }
      }
    } catch(e) {
      return false;
    }
    return true;
  }

  Future<String?> getCalendarId() async {
    UnmodifiableListView<Calendar>? cals = (await deviceCalendarPlugin!.retrieveCalendars()).data;
    for( Calendar cal in cals! ){
      if( cal.isDefault! ){
        return cal.id;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    deviceCalendarPlugin = DeviceCalendarPlugin();
    tz.initializeTimeZones(); // タイムゾーンデータベースの初期化
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo')); // タイムゾーンを設定
  }

  @override
  Widget build(BuildContext context) {
    contentWidth  = MediaQuery.of( context ).size.width;
    contentHeight = MediaQuery.of( context ).size.height - MediaQuery.of( context ).padding.top - MediaQuery.of( context ).padding.bottom;

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0
      ),
      body: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('eventId', style: TextStyle(fontSize: 20)),
        MyTextField( onChanged: (value) {
          eventId = value;
        } ),
        Text('title', style: TextStyle(fontSize: 20)),
        MyTextField( onChanged: (value) {
          title = value;
        } ),
        Text('start', style: TextStyle(fontSize: 20)),
        InkWell(
            onTap: () {
              DatePicker.showDateTimePicker(context,
                showTitleActions: true,
                minTime: DateTime.now(),
                maxTime: DateTime.now().add(Duration(days: 30)),
                currentTime: start,
                locale: LocaleType.jp,
                onChanged: (DateTime dateTime) {
                },
                onConfirm: (DateTime dateTime) {
                  setState(() {
                    start = dateTime;
                  });
                },
              );
            },
            child: Container(
                width: contentWidth,
                height: 50,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(
                    left: 10.0, top: 0.0, right: 10.0, bottom: 0.0
                ),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38)
                ),
                child: Text('$start', style: TextStyle(fontSize: 20))
            )
        ),
        Text('end', style: TextStyle(fontSize: 20)),
        InkWell(
            onTap: () {
              DatePicker.showDateTimePicker(context,
                showTitleActions: true,
                minTime: DateTime.now(),
                maxTime: DateTime.now().add(Duration(days: 30)),
                currentTime: end,
                locale: LocaleType.jp,
                onChanged: (DateTime dateTime) {
                },
                onConfirm: (DateTime dateTime) {
                  setState(() {
                    end = dateTime;
                  });
                },
              );
            },
            child: Container(
                width: contentWidth,
                height: 50,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(
                    left: 10.0, top: 0.0, right: 10.0, bottom: 0.0
                ),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38)
                ),
                child: Text('$end', style: TextStyle(fontSize: 20))
            )
        ),
        Text('description', style: TextStyle(fontSize: 20)),
        MyTextField( onChanged: (value) {
          description = value;
        } ),
        Row( children: [
          ElevatedButton(
            child: const Text('イベント送信'),
            onPressed: () async {
              if( await requestPermissions() ){
                String? calendarId = await getCalendarId();
                if( calendarId == null ){
                  // 送信先カレンダーが見つからなかった場合の処理
                } else {
                  Event event = Event(calendarId,
                      eventId: eventId, // nullまたは存在しないイベントIDの場合、新規作成になる
                      title: title,
                      start: tz.TZDateTime.from(start, tz.local),
                      end: tz.TZDateTime.from(end, tz.local),
                      description: description
                  );
                  Result<String>? result = await deviceCalendarPlugin!.createOrUpdateEvent(event);
                  if (result!.isSuccess && (result.data?.isNotEmpty ?? false)) {
                    setState(() {
                      eventId = result.data; // 作成または更新したイベントIDが取得できる
                    });
                  }
                }
              }
            },
          ),
          SizedBox(width: 10),
          Text('eventId: ' + ((eventId == null) ? 'null' : eventId!), style: TextStyle(fontSize: 20)),
        ] ),
      ] ),
    );
  }
}

class MyTextField extends TextField {
  MyTextField({required void Function(String) onChanged, Key? key}) : super(key: key,
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
    ),
    autocorrect: false,
    keyboardType: TextInputType.text,
    onChanged: onChanged,
  );
}
