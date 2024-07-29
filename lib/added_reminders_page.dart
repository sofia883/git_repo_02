import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddedRemindersPage extends StatefulWidget {
  @override
  _AddedRemindersPageState createState() => _AddedRemindersPageState();
}

class _AddedRemindersPageState extends State<AddedRemindersPage> {
  List<Map<String, String>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData = prefs.getStringList('reminders') ?? [];

    setState(() {
      reminders = remindersData
          .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
          .toList();
    });
  }

  Future<void> _saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData =
        reminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersData);
  }

  void _deleteReminder(int index) async {
    setState(() {
      reminders.removeAt(index);
      _saveReminders();
    });
  }

  Future<void> _editReminder(int index) async {
    final reminder = reminders[index];
    final titleController = TextEditingController(text: reminder['title']);
    final descriptionController =
        TextEditingController(text: reminder['description']);
    final dateController = TextEditingController(text: reminder['date']);
    final timeController = TextEditingController(text: reminder['time']);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context, dateController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectTime(context, timeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate date and time before saving
                DateTime? selectedDateTime = _parseDateTime(
                  dateController.text,
                  timeController.text,
                );

                if (selectedDateTime == null ||
                    selectedDateTime.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Date and time should not be in the past.'),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                setState(() {
                  reminders[index] = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                  };
                  _saveReminders();
                });

                // Show success SnackBar after saving
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminder edited successfully!'),
                  ),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      // Parse the date
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);

      // Parse the time
      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1].split(' ')[0]);

      // Adjust hour for AM/PM
      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      // Combine date and time
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );
    } catch (e) {
      print('Error parsing date or time: $e');
      return null;
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('d MMMM yyyy')
          .format(pickedDate); // Adjust format as needed
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay initialTime = TimeOfDay(hour: now.hour, minute: now.minute);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      controller.text = pickedTime.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Added Reminders'),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Text(
                'No reminders added yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final dateTimeText =
                    reminder['date'] != null && reminder['time'] != null
                        ? '${reminder['date']} at ${reminder['time']}'
                        : '';

                return Card(
                  elevation: 20,
                  shadowColor: Colors.black,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          reminder['description'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Scheduled time:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reminder['date'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    reminder['time'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editReminder(index),
                                ),
                                Container(
                                  height:
                                      24.0, // Adjust the height to fit the icons properly
                                  child: VerticalDivider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    width: 20,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.delete, color: Colors.orange),
                                  onPressed: () => _deleteReminder(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}