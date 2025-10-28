

// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

class TodoTile extends StatefulWidget {
  final String taskId;
  final String initialTaskName;
  final bool initialIsCompleted;
  Function(bool?)? onChanged; // Callback for checkbox change
  Function(BuildContext)? deleteTask; 

  TodoTile({
    super.key,
    required this.taskId,
    required this.initialTaskName,
    required this.initialIsCompleted,
    required this.onChanged,
    required this.deleteTask,
  });

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
   late bool _isCompleted;
  final TextEditingController _timerInputController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _isCompleted = widget.initialIsCompleted;
  }
   @override
  void didUpdateWidget(covariant TodoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial completed state changes from the parent, update local state
    if (widget.initialIsCompleted != oldWidget.initialIsCompleted) {
      setState(() {
        _isCompleted = widget.initialIsCompleted;
      });
    }
    // Note: We don't update taskName here, assuming it doesn't change frequently.
    // If editing is added later, this would need updating.
  }
  @override
  void dispose() {
    _timerInputController.dispose();
    super.dispose();
  }
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    // String hours = twoDigits(d.inHours); // Uncomment if using hours
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    // return "$hours:$minutes:$seconds";
    return "00:$minutes:$seconds"; // Default format HH:MM:SS, showing 00 hours for now
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding around each tile
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Slidable(
        // Delete action when sliding left
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25, // How far the action pane opens
          children: [
            SlidableAction(
              onPressed: widget.deleteTask, // Call the delete callback
              icon: Icons.delete_outline,
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // label: 'Delete', // Optional label
            )
          ],
        ),
        // The main content of the tile
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _isCompleted ? Colors.grey.shade200 : Colors.white, // Background changes slightly when completed
            borderRadius: BorderRadius.circular(12),
            boxShadow: [ // Subtle shadow for depth
              BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 spreadRadius: 1,
                 blurRadius: 4,
                 offset: const Offset(0, 2),
              )
            ]
          ),
          child: Column( // Main layout is vertical
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Row: Checkbox, Task Name, Timer Display & Controls ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                children: [
                  // Checkbox
                  Checkbox(
                    value: _isCompleted,
                    onChanged: (value) {
                      // Update local state immediately for responsiveness
                      setState(() { _isCompleted = value ?? false; });
                      // Call the actual update function passed from parent
                      widget.onChanged?.call(value);
                    },
                    activeColor: Theme.of(context).primaryColor, // Use theme color
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  // Task Name (Takes up remaining space)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0), // Small space after checkbox
                      child: Text(
                        widget.initialTaskName,
                        maxLines: 2, // Allow text to wrap
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          // Apply line-through and change color when completed
                          decoration: _isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: _isCompleted ? Colors.grey[600] : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // --- Placeholder Timer Display and Controls ---
                  Text(
                    _formatDuration(Duration.zero), // Display "00:00:00" for now
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                    iconSize: 24, // Slightly larger icon
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Start Timer (Coming Soon)',
                    onPressed: () {
                       print("Start/Pause Timer pressed (No logic yet)");
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(duration: Duration(seconds: 1), content: Text("Timer coming soon!")),
                         );
                    },
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
                  // --- End Placeholder Timer ---
                ],
              ),
              const SizedBox(height: 12), // Space between the two rows

              // --- Bottom Row: Timer Input Field and Set Button ---
               Row(
                 children: [
                   Expanded(
                     child: SizedBox( // Constrain height for a neat look
                       height: 45,
                       child: TextField(
                          controller: _timerInputController,
                          keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false), // Better for time input
                          decoration: InputDecoration(
                            hintText: "Set timer (HH:MM:SS)",
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // Adjust padding
                            filled: true,
                            fillColor: Colors.white, // White field background
                            border: OutlineInputBorder( // Consistent border styling
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            ),
                             enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(8),
                               borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5), // Highlight on focus
                             ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   ElevatedButton(
                     onPressed: () {
                        print("Set Timer pressed: ${_timerInputController.text} (No logic yet)");
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(duration: Duration(seconds: 1), content: Text("Timer setting coming soon!")),
                         );
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        _timerInputController.clear();
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.grey[200], // Light background for button
                       foregroundColor: Colors.black54, // Text color
                       elevation: 0, // Flat design
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Button padding
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
