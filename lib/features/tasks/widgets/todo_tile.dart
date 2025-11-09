// ignore_for_file: must_be_immutable

import 'dart:async'; // Import async for Timer
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/tasks/services/task_service.dart'; // Import TaskService

class TodoTile extends StatefulWidget {
  final String taskId;
  final String initialTaskName;
  final bool initialIsCompleted;
  
  // --- Timer parameters ---
  final int initialDurationSeconds;
  final int initialRemainingSeconds;
  final bool initialIsRunning;
  // --- End timer parameters ---

  final TaskService taskService; // Service for updating Firestore
  Function(bool?)? onChanged;
  Function(BuildContext)? deleteTask;

  TodoTile({
    required Key key,
    required this.taskId,
    required this.initialTaskName,
    required this.initialIsCompleted,
    required this.initialDurationSeconds,
    required this.initialRemainingSeconds,
    required this.initialIsRunning,
    required this.taskService, // Receive the service
    required this.onChanged,
    required this.deleteTask,
  }) : super(key: key);

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  late bool _isCompleted;
  final TextEditingController _timerInputController = TextEditingController();
  
  // --- Timer State ---
  Timer? _timer;
  late Duration _fullDuration;
  late Duration _currentTime;
  late bool _isRunning;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // --- End Timer State ---

  @override
  void initState() {
    super.initState();
    // Initialize local state from the widget's parameters
    _isCompleted = widget.initialIsCompleted;
    _fullDuration = Duration(seconds: widget.initialDurationSeconds);
    _currentTime = Duration(seconds: widget.initialRemainingSeconds);
    _isRunning = widget.initialIsRunning;

    // If Firestore says the timer was running, auto-start it
    if (_isRunning && !_isCompleted) {
      _startTimer();
    }
  }
 
  @override
  void dispose() {
    _timer?.cancel(); // IMPORTANT: Stop the timer when widget is removed
    _timerInputController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- Timer Control Functions ---
  void _toggleTimer() {
    if (_isCompleted) return; // Don't start timer if task is already done

    if (_isRunning) {
      _pauseTimer();
    } else {
      // If timer is at 00:00, reset it to the full duration before starting
      if (_currentTime == Duration.zero) {
        _resetTimer(notifyFirestore: false);   // Don't notify, _startTimer will
      }
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    // Save the "running" state to Firestore
    widget.taskService.updateTimerState(
      context, 
      widget.taskId, 
      remainingSeconds: _currentTime.inSeconds, 
      isRunning: true
    );

    // Start the 1-second countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime.inSeconds > 0) {
        setState(() {
          _currentTime -= const Duration(seconds: 1);
        });
      } else {
        // Timer finished
        _timerFinished();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    // Save the "paused" state and remaining time to Firestore
    widget.taskService.updateTimerState(
      context, 
      widget.taskId, 
      remainingSeconds: _currentTime.inSeconds, 
      isRunning: false
    );
  }

  // Resets the timer to its full duration
  void _resetTimer({bool notifyFirestore = true}) {
    _timer?.cancel();
    setState(() {
      _currentTime = _fullDuration;
      _isRunning = false;
    });
    if (notifyFirestore) {
      // Save the "reset" state to Firestore
      widget.taskService.updateTimerState(
        context, 
        widget.taskId, 
        remainingSeconds: _fullDuration.inSeconds, 
        isRunning: false
      );
    }
  }

  // Called when the timer hits 00:00
  void _timerFinished() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentTime = _fullDuration; // Reset timer UI
      if (!_isCompleted) {
         _isCompleted = true; // Mark as complete
         // Call the main screen's function to update Firestore
         widget.onChanged?.call(true); 
      }
    });
    
    // --- Play Sound ---
    try {
      // Make sure you have 'alarm.mp3' (or your sound file) in 'assets/sounds/'
      // And you added it to pubspec.yaml
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  // --- Set Timer from Input ---
  void _setTimerFromInput() {
    FocusScope.of(context).unfocus(); // Hide keyboard
    final input = _timerInputController.text;
    if (input.isEmpty) return;

    final parts = input.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    int totalSeconds = 0;

    try {
      if (parts.length == 3) { // HH:MM:SS format
        totalSeconds = (parts[0] * 3600) + (parts[1] * 60) + parts[2];
      } else if (parts.length == 2) { // MM:SS format
        totalSeconds = (parts[0] * 60) + parts[1];
      } else if (parts.length == 1) { // Minutes-only format
        totalSeconds = parts[0] * 60;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time format.')),
      );
      return;
    }

    if (totalSeconds < 0) totalSeconds = 0;

    // Update state locally AND in Firestore
    setState(() {
      _fullDuration = Duration(seconds: totalSeconds);
      _currentTime = _fullDuration;
      _isRunning = false;
    });
    _timer?.cancel();
    _timerInputController.clear();
    
    // Call service to update Firestore
    widget.taskService.setTimerDuration(context, widget.taskId, totalSeconds);
  }

  // Helper to format Duration (e.g., 01:29:00 or 25:00)
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    // .abs() handles rare cases where duration might be slightly negative
    final hours = d.inHours.abs();
    final minutes = d.inMinutes.remainder(60).abs();
    final seconds = d.inSeconds.remainder(60).abs();

    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
    return "${twoDigits(minutes)}:${twoDigits(seconds)}"; // MM:SS format
  }

  @override
  Widget build(BuildContext context) {
    // --- Sync with Firestore ---
    // This part is crucial. It ensures that when the StreamBuilder in
    // tasks_screen rebuilds this widget, the local state is updated
    // with the latest data from Firestore.
    _isCompleted = widget.initialIsCompleted;
    // Only update local timer values if the timer isn't *currently* running.
    // This prevents the local countdown from "jumping" every time
    // Firestore syncs.
    if (!_isRunning) { 
      _fullDuration = Duration(seconds: widget.initialDurationSeconds);
      _currentTime = Duration(seconds: widget.initialRemainingSeconds);
    }
    // --- End Sync ---

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: widget.deleteTask,
              icon: Icons.delete_outline,
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            )
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _isCompleted ? Colors.grey.shade200 : Color(0xFFB7D5DA),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 spreadRadius: 1,
                 blurRadius: 4,
                 offset: const Offset(0, 2),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isCompleted,
                    onChanged: (value) {
                      // If user checks it, pause the timer
                      if (value == true) _pauseTimer();
                      widget.onChanged?.call(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        widget.initialTaskName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          decoration: _isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: _isCompleted ? Colors.grey[600] : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // --- Timer Section (Wired Up) ---
                  Text(
                    _formatDuration(_currentTime), // Display running time
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isRunning ? Theme.of(context).primaryColor : Colors.black54,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    color: Theme.of(context).primaryColor,
                    iconSize: 24,
                    visualDensity: VisualDensity.compact,
                    tooltip: _isRunning ? 'Pause Timer' : 'Start Timer',
                    onPressed: _isCompleted ? null : _toggleTimer, // Disable if task is done
                  ),
                   IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey[600]),
                     iconSize: 22, // Slightly smaller reset icon
                     visualDensity: VisualDensity.compact,
                     tooltip: 'Reset Timer (Coming Soon)',
                    onPressed: () {
                        print("Reset Timer pressed (No logic yet)");
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(duration: Duration(seconds: 1), content: Text("Timer coming soon!")),
                         );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.music_note_outlined, color: Colors.grey, size: 20),
                    tooltip: "Focus Music (Coming Soon!)",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text("Focus Music is coming soon in a future update!"),
                        ),
                      );
                    },
                  ),
                  // --- End Timer Section ---
                ],
              ),
              const SizedBox(height: 12),
              Row(
                 children: [
                   Expanded(
                     child: SizedBox(
                       height: 45,
                       child: TextField(
                          controller: _timerInputController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "Set timer (e.g., 25 or 1:30:00)",
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            ),
                             enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(8),
                               borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                             ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   ElevatedButton(
                     onPressed: _setTimerFromInput, // Wire up set timer function
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.grey[200],
                       foregroundColor: Colors.black54,
                       elevation: 0,
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                     child: Text(
                       "Set Timer",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                   ),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }
}