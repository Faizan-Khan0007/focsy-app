// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
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
  // Timer State
  Timer? _timer;
  late Duration _fullDuration;
  late Duration _currentTime;
  late bool _isRunning;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fullDuration = Duration(seconds: widget.initialDurationSeconds);
    // If remaining time is 0, start with the full duration
    _currentTime = Duration(
        seconds: widget.initialRemainingSeconds > 0
            ? widget.initialRemainingSeconds
            : widget.initialDurationSeconds);
    _isRunning = widget.initialIsRunning;
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

    // Auto-start timer if it was running
    if (_isRunning) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    // When leaving the screen, pause the timer and save the state
    if (_isRunning) {
      _pauseTimer(saveState: true);
    }
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- Timer Logic (Moved from TodoTile) ---
  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer(saveState: true);
    } else {
      if (_currentTime == Duration.zero) {
        _resetTimer(notifyFirestore: false); // Don't notify, _startTimer will
      }
      _startTimer();
    }
  }

  void _startTimer() {
    if (_fullDuration.inSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Set a timer on the Tasks screen first!")),
      );
      return;
    }
    setState(() {
      _isRunning = true;
    });
    // Save timer state to Firestore
    widget.taskService.updateTimerState(context, widget.taskId,
        remainingSeconds: _currentTime.inSeconds, isRunning: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime.inSeconds > 0) {
        setState(() {
          _currentTime -= const Duration(seconds: 1);
        });
      } else {
        _timerFinished();
      }
    });
  }

  void _pauseTimer({bool saveState = false}) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    if (saveState) {
      // Save timer state to Firestore
      widget.taskService.updateTimerState(context, widget.taskId,
          remainingSeconds: _currentTime.inSeconds, isRunning: false);
    }
  }

  void _resetTimer({bool notifyFirestore = true}) {
    _timer?.cancel();
    setState(() {
      _currentTime = _fullDuration;
      _isRunning = false;
    });
    if (notifyFirestore) {
      // Save the "reset" state to Firestore
      widget.taskService.updateTimerState(context, widget.taskId,
          remainingSeconds: _fullDuration.inSeconds, isRunning: false);
    }
  }

  void _timerFinished() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentTime = _fullDuration; // Reset timer UI
    });
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

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours.abs();
    final minutes = d.inMinutes.remainder(60).abs();
    final seconds = d.inSeconds.remainder(60).abs();
    if (hours > 0) return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

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
                  _formatDuration(_currentTime),
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
                  onPressed: _toggleTimer,
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
                onPressed: () => _resetTimer(notifyFirestore: true),
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