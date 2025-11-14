// ignore_for_file: must_be_immutable, use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // <-- IMPORTED
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/tasks/services/task_service.dart';

class FocusScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String taskDescription;
  final int initialDurationSeconds;
  final int initialRemainingSeconds;
  final bool initialIsRunning;
  final TaskService taskService;
  final Function(bool?) onTaskCompleted; // Callback to update the task list

  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.taskDescription,
    required this.initialDurationSeconds,
    required this.initialRemainingSeconds,
    required this.initialIsRunning,
    required this.taskService,
    required this.onTaskCompleted,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // --- STATE REFACTORED ---
  final _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  late Duration _fullDuration;
  late int _currentSeconds; // Changed from Duration to int
  late bool _isRunning;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // --- END REFACTOR ---

  @override
  void initState() {
    super.initState();
    _fullDuration = Duration(seconds: widget.initialDurationSeconds);
    
    // Set initial time
    _currentSeconds = widget.initialRemainingSeconds > 0
        ? widget.initialRemainingSeconds
        : widget.initialDurationSeconds;
    
    _isRunning = widget.initialIsRunning;
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

    // --- NEW: Listen to the background service ---
    _serviceSubscription = _service.on('update').listen((payload) {
      if (payload == null) return;
      
      int newSeconds = payload['remainingSeconds'];
      
      // Update the UI state from the service
      if (mounted) {
        setState(() {
          _currentSeconds = newSeconds;
          if (newSeconds == 0 && _isRunning) {
            // Timer finished while we were watching
            _isRunning = false; 
            _timerFinished(); // Call the dialog/sound function
          }
        });
      }
    });
    // --- END NEW ---

    // Auto-start timer if it was running when we entered the screen
    if (_isRunning) {
      _startTimerService();
    }
  }

  @override
  void dispose() {
    // --- NEW: Stop listening to the service ---
    _serviceSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- TIMER LOGIC REFACTORED TO CONTROL SERVICE ---
  
  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimerService();
    } else {
      if (_currentSeconds == 0) {
        // If timer is at 0, reset it before starting
        _resetTimer(notifyService: false); // Don't notify, _startTimer will
      }
      _startTimerService();
    }
  }

  void _startTimerService() {
    if (_fullDuration.inSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Set a timer on the Tasks screen first!")),
      );
      return;
    }
    
    setState(() { _isRunning = true; });

    // Tell the service to start
    _service.invoke('start', {
      'taskId': widget.taskId,
      'taskName': widget.taskName,
      'remainingSeconds': _currentSeconds,
    });

    // We also save the 'running' state from the UI side
    widget.taskService.updateTimerState(context, widget.taskId,
        remainingSeconds: _currentSeconds, isRunning: true);
    
    // Tell the service to show the notification
    _service.invoke('setAsForeground');
  }

  void _pauseTimerService() {
    setState(() { _isRunning = false; });
    
    // Tell the service to pause
    _service.invoke('pause');
    
    // The service handles saving the state to Firestore now,
    // so no updateTimerState call is needed from the UI.
  }

  void _resetTimer({bool notifyService = true}) {
    setState(() {
      _currentSeconds = _fullDuration.inSeconds;
      _isRunning = false;
    });

    if (notifyService) {
      // Tell the service to reset
      _service.invoke('reset', {
        'taskId': widget.taskId,
        'fullDuration': _fullDuration.inSeconds,
      });
    }
  }

  // This function is now just for sound/dialog
  void _timerFinished() async {
    // Call the callback to mark task as complete on the main list
    widget.onTaskCompleted(true);

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      print("Error playing sound: $e");
    }

    // Show a dialog that timer is done
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Session Complete!",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
              "'${widget.taskName}' is finished and has been marked as complete.",
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to task list
              },
              child: Text("Awesome!",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  // --- UPDATED to accept int seconds ---
  String _formatDuration(int totalSeconds) {
    final d = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours.abs();
    final minutes = d.inMinutes.remainder(60).abs();
    final seconds = d.inSeconds.remainder(60).abs();
    if (hours > 0) return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
  // --- END UPDATE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Focus Mode",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Task Title
              Text(
                widget.taskName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Task Description
              Text(
                widget.taskDescription.isEmpty
                    ? "No description for this task."
                    : widget.taskDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 60),

              // Big Timer Display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  // --- UPDATED to use _currentSeconds ---
                  _formatDuration(_currentSeconds),
                  style: GoogleFonts.poppins(
                    fontSize: 72,
                    fontWeight: FontWeight.w600,
                    color: _isRunning
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Start/Pause Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer, // <-- Controls the service
                  icon:
                      Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 30),
                  label: Text(
                    _isRunning ? "PAUSE" : "START FOCUS",
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.orange[700]
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Reset Button
              TextButton.icon(
                onPressed: () => _resetTimer(notifyService: true), // <-- Controls the service
                icon: Icon(Icons.refresh, color: Colors.grey[600]),
                label: Text(
                  "Reset Timer",
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              )
            ],
          ),
        ),
      ),
    );
  }
}