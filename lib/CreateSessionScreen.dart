import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateSessionScreen extends StatefulWidget {
  @override
  _CreateSessionScreenState createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final TextEditingController _classIdController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _createSession() async {
    if (_classIdController.text.isEmpty ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // Format Date and Time Correctly
    String formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    String formattedStartTime =
        "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00";
    String formattedEndTime =
        "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00";

    String sessionId =
        FirebaseFirestore.instance.collection('sessions').doc().id;

    await FirebaseFirestore.instance.collection('sessions').doc(sessionId).set({
      "session_id": sessionId,
      "class_id": _classIdController.text,
      "date": formattedDate,
      "start_time": formattedStartTime,
      "end_time": formattedEndTime,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Session Created Successfully")));
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null)
      setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Attendance Session")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _classIdController,
              decoration: InputDecoration(labelText: "Class ID"),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "Date: ${_selectedDate?.toLocal().toString().split(' ')[0] ?? 'Select'}",
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
            ),
            Row(
              children: [
                Text("Start Time: ${_startTime?.format(context) ?? 'Select'}"),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(true),
                ),
              ],
            ),
            Row(
              children: [
                Text("End Time: ${_endTime?.format(context) ?? 'Select'}"),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(false),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createSession,
              child: Text("Create Session"),
            ),
          ],
        ),
      ),
    );
  }
}
