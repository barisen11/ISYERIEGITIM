import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Retrieve notes from SharedPreferences
  List<String> savedNotes = await getSavedNotes();

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Colors.teal,
        ledColor: Colors.teal,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      ),
    ],
  );

  runApp(MyApp(savedNotes));
}

class MyApp extends StatelessWidget {
  final List<String> savedNotes;

  const MyApp(this.savedNotes);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrNote 1.1',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(savedNotes),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> savedNotes;

  const MyHomePage(this.savedNotes);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> notes = [];

  @override
  void initState() {
    super.initState();
    // Initialize the notes list with saved notes
    notes = widget.savedNotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DrNote 1.1'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddNotePage()),
                );
                if (result != null) {
                  setState(() {
                    notes.add(result);
                  });
                  // Save notes to SharedPreferences
                  saveNotes(notes);
                }
              },
              child: Text('Not Ekle'),
            ),
            ElevatedButton(
              onPressed: () async {
                List<NotificationModel> notifications =
                    await AwesomeNotifications().listScheduledNotifications();

                if (notifications.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Notlar'),
                      content: Column(
                        children: notifications
                            .map((notification) =>
                                Text(notification.content!.body!))
                            .toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Notlar'),
                      content: Text('Henüz not eklenmedi.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Notları Görüntüle'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _scheduleNotification(BuildContext context) async {
    if (_noteController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Hata'),
          content: Text('Lütfen geçerli bir not girin, tarih ve saat seçin.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    final scheduledDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'DrNote 1.1',
        body: _noteController.text,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Başarılı'),
        content: Text('Not eklendi ve bildirim planlandı.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_noteController.text);
            },
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Ekle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Notunuz'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Not boş olamaz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                        _selectedTime = pickedTime;
                      });
                    }
                  }
                },
                child: Text('Tarih ve Saat Seç'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _scheduleNotification(context);
                },
                child: Text('Not Ekle ve Bildirim Planla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void saveNotes(List<String> notes) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList('notes', notes);
}

Future<List<String>> getSavedNotes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? savedNotes = prefs.getStringList('notes');
  return savedNotes ?? [];
}
