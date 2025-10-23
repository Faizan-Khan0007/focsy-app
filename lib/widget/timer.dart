import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';  // Import the audioplayers package

class TodoTile extends StatefulWidget {
  final String taskname;
  final bool taskcompleted;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteTask;

  const TodoTile({
    super.key,
    required this.taskname,
    required this.taskcompleted,
    required this.onChanged,
    required this.deleteTask,
  });

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  bool isTimerRunning = false;
  Duration remainingTime = Duration.zero;
  Duration initialTime = Duration.zero; // Store initial user input time
  Timer? _timer;
  final TextEditingController timerController = TextEditingController();

  // Initialize the audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Function to play the sound when the timer finishes
  Future<void> playSound() async {
  //print("Playing sound...");  // Add a log to check if this function is called
  await _audioPlayer.play(AssetSource('assets/ringtone.mp3'));
}
  void toggleTimer() {
    if (isTimerRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    setState(() {
      isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > Duration.zero) {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        setState(() {
          isTimerRunning = false;
        });
        playSound(); // Play sound when timer finishes
      }
    });
  }

  void pauseTimer() {
    setState(() {
      isTimerRunning = false;
    });
    _timer?.cancel();
  }

  void resetTimer() {
    setState(() {
      remainingTime = initialTime; // Reset to the user's initial input
      isTimerRunning = false;
    });
    _timer?.cancel();
  }

  void setTimerFromInput() {
    final input = timerController.text;
    final parts = input.split(':');
    if (parts.length == 3) {
      try {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        setState(() {
          initialTime = Duration(hours: hours, minutes: minutes, seconds: seconds);
          remainingTime = initialTime; // Set both initial and current remaining time
        });
        timerController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid time format. Use HH:MM:SS.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time format. Use HH:MM:SS.')),
      );
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    timerController.dispose();
    _audioPlayer.dispose(); // Dispose of the audio player when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 25),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.yellowAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: widget.taskcompleted,
                        onChanged: widget.onChanged,
                      ),
                      Expanded(
                        child: Text(
                          widget.taskname,
                          style: TextStyle(
                            decoration: widget.taskcompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${remainingTime.inHours}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        isTimerRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.blue,
                      ),
                      onPressed: toggleTimer,
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay, color: Colors.green),
                      onPressed: resetTimer,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: timerController,
                    decoration: InputDecoration(
                      hintText: "Set timer (HH:MM:SS)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: setTimerFromInput,
                  child: const Text("Set Timer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
