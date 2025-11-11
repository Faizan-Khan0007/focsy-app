// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

class TodoTile extends StatelessWidget { // Changed to StatelessWidget
  final String taskId;
  final String taskName;
  final bool isCompleted;
  final int durationSeconds; // We still pass this
  
  Function(bool?)? onChanged;
  Function(BuildContext)? deleteTask;
  VoidCallback? onTap; // --- NEW: Callback for tapping the tile ---

  TodoTile({
    required Key key,
    required this.taskId,
    required this.taskName,
    required this.isCompleted,
    required this.durationSeconds, // Pass duration
    required this.onChanged,
    required this.deleteTask,
    required this.onTap, // --- NEW ---
  }) : super(key: key);

  // Helper to format Duration (e.g., 01:00:00 or 25:00)
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
    // Only show minutes and seconds if duration is less than an hour
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: deleteTask,
              icon: Icons.delete_outline,
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            )
          ],
        ),
        // --- MODIFIED: Use InkWell to make it tappable ---
        child: InkWell(
          onTap: isCompleted ? null : onTap, // Call the new onTap callback, disable if complete
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Made it taller
            decoration: BoxDecoration(
              color: isCompleted ? Colors.grey.shade200 : Colors.white,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: onChanged, // Call the passed-in function
                  activeColor: Theme.of(context).primaryColor,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      taskName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        color: isCompleted ? Colors.grey[600] : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // --- SIMPLE TIMER DISPLAY (Non-interactive) ---
                // Shows the *total* duration planned for the task
                if (durationSeconds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Theme.of(context).primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(durationSeconds),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                // --- END SIMPLE TIMER DISPLAY ---
              ],
            ),
          ),
        ),
      ),
    );
  }
}