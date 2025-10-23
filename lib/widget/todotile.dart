// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Removed Hive import

class TodoTile extends StatelessWidget { // Changed to StatelessWidget
  final String taskname;
  final bool taskcompleted;
  Function(bool?)? onChanged; // Callback for checkbox change
  Function(BuildContext)? deleteTask; // Callback for delete action
  // Removed taskIndex as it might not be directly needed if we use Firestore IDs

  TodoTile({
    super.key,
    required this.taskname,
    required this.taskcompleted,
    required this.onChanged,
    required this.deleteTask,
    // required int taskIndex, // Removed from constructor
  });

  // --- Removed All State and Timer Logic ---
  // No initState, no Timer variables, no timer functions

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0), // Adjusted padding
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteTask, // Use the passed-in function
              icon: Icons.delete_outline, // Changed icon
              backgroundColor: Colors.red.shade300, // Softer red
              borderRadius: BorderRadius.circular(12),
              label: 'Delete', // Added label
            )
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20), // Adjusted padding
          decoration: BoxDecoration( // Use decoration for background and border
             color: taskcompleted ? Colors.grey[200] : Colors.grey[100], // Lighter grey background
             borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: taskcompleted,
                onChanged: onChanged, // Use the passed-in function
                activeColor: const Color(0xFF6398A7), // Match theme color
              ),

              // Task name (Expanded to take available space)
              Expanded(
                child: Text(
                  taskname,
                  style: TextStyle(
                    fontSize: 16, // Slightly larger font
                    decoration: taskcompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: taskcompleted ? Colors.black54 : Colors.black87, // Dim completed tasks
                  ),
                ),
              ),

              // --- Removed Timer UI Elements ---
              // Removed Text(remainingTime...), IconButton(play/pause), IconButton(reset)
              // Removed TextField and ElevatedButton for setting timer

            ],
          ),
        ),
      ),
    );
  }
}
