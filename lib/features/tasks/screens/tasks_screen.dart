import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/navbar/widgets/daile_quote_dialog.dart';
import 'package:my_todo_app/features/tasks/screens/focus_timer_screen.dart';
// import 'package:my_todo_app/features/auth/services/auth_service.dart'; // Not used here
import 'package:my_todo_app/features/tasks/services/task_service.dart';
import 'package:my_todo_app/features/tasks/widgets/todo_tile.dart';

class TasksScreen extends StatefulWidget {
  static const String routeName = '/tasks-screen';
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  //services
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // final AuthService _authService = AuthService(); // Not used here
  final TaskService _taskService = TaskService();
  
  // Controllers for the bottom sheet
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
  }

  //functions call taskservice methods
  void deleteTask(String taskId) {
    _taskService.deleteTask(context, taskId);
  }

  void checkboxChanged(bool? value, String taskId) {
    if (value == null) return;
    _taskService.updateTaskCompletion(context, taskId, value);
  }

  // --- NEW: Helper Function for parsing duration ---
  int _parseDuration() {
    int totalSeconds = 0;
    final input = _durationController.text.trim();
    if (input.isNotEmpty) {
      final parts = input.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      try {
        if (parts.length == 3) { // HH:MM:SS
          totalSeconds = (parts[0] * 3600) + (parts[1] * 60) + parts[2];
        } else if (parts.length == 2) { // MM:SS
          totalSeconds = (parts[0] * 60) + parts[1];
        } else if (parts.length == 1) { // M (Minutes)
          totalSeconds = int.parse(input) * 60; // Handle single number as minutes
        }
      } catch (e) { /* Fails silently */ }
    }
    return totalSeconds;
  }
  
  // --- NEW: Helper to clear controllers and pop ---
  void _clearControllersAndPop() {
     _titleController.clear();
    _descriptionController.clear();
    _durationController.clear();
    Navigator.of(context).pop(); // Close the bottom sheet
  }

  // --- MODIFIED: This function is now called by the bottom sheet to ADD ---
  void _saveNewTask() {
    if (_titleController.text.trim().isEmpty) return;
    int totalSeconds = _parseDuration(); // Use helper

    _taskService.addTask(
      context,
      _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: totalSeconds,
    );
    
    _clearControllersAndPop();
  }

  // --- NEW: Function to UPDATE ---
  void _updateTask(String taskId) {
    if (_titleController.text.trim().isEmpty) return;
    int totalSeconds = _parseDuration(); // Use helper

    _taskService.updateTaskDetails(
      context: context,
      taskId: taskId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: totalSeconds,
    );

    _clearControllersAndPop();
  }

  // --- MODIFIED: This now shows the advanced bottom sheet for ADD or EDIT ---
  void _showTaskSheet({DocumentSnapshot? taskDoc}) {
    bool isEditing = taskDoc != null;
    
    // If editing, pre-fill the controllers
    if (isEditing) {
      final data = taskDoc.data() as Map<String, dynamic>;
      _titleController.text = data['taskName'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      final duration = Duration(seconds: data['timerDurationSeconds'] ?? 0);
      // Format as HH:MM:SS
      _durationController.text = duration.toString().split('.').first.padLeft(8, "0");
    } else {
      // If adding, clear them
      _titleController.clear();
      _descriptionController.clear();
      _durationController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Edit Task" : "Add New Task", // Dynamic Title
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Task Title (e.g., Physics)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Details (e.g., Chapter 4 & 5)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              // Duration
              TextField(
                controller: _durationController,
                decoration: InputDecoration(
                  hintText: "Set Timer (e.g., 45 or 1:30:00)", // Updated hint
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              // Add/Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // --- Call the correct function ---
                    if (isEditing) {
                      _updateTask(taskDoc.id);
                    } else {
                      _saveNewTask();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Save Changes" : "Add Task", // Dynamic Text
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showQuote() {
    showDialog(
      context: context,
      builder: (context) => const DailyQuoteDialog(),
    );
  }

  void _navigateToFocusScreen(Map<String, dynamic> taskData, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          taskId: taskId,
          taskName: taskData['taskName'] ?? 'Unnamed Task',
          taskDescription: taskData['description'] ?? '',
          initialDurationSeconds: taskData['timerDurationSeconds'] ?? 0,
          initialRemainingSeconds: taskData['timerRemainingSeconds'] ?? 0,
          initialIsRunning: taskData['isTimerRunning'] ?? false,
          taskService: _taskService,
          onTaskCompleted: (value) {
            checkboxChanged(value, taskId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskSheet(), // <-- MODIFIED to call the new function
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: 'Add Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Stack(
        children: [
          // Background circles
          Positioned(
            top: -50,
            left: -100,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 0,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          SafeArea(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 70.0, left: 24.0, bottom: 20.0,), // More top padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Changed to spaceBetween
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Todo Tasks",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: _showQuote,
                      icon: Icon(
                        Icons.format_quote_rounded,
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                        size: 28,
                      ),
                      tooltip: "Quote of the Day",
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                stream: _taskService.getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // --- This is the "Empty State" UI ---
                    return Center(
                      child: Text(
                        "No tasks yet!\nGo to the Routine tab to load your plan.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                      ),
                    );
                    // --- End Empty State ---
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 12.0, right: 12.0, bottom: 90.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> taskData =
                          doc.data() as Map<String, dynamic>;
                      String taskId = doc.id;
                      bool isCompleted = taskData['isCompleted'] ?? false;

                      return TodoTile(
                        key: ValueKey(taskId),
                        taskId: taskId,
                        taskName: taskData['taskName'] ?? 'Unnamed Task',
                        isCompleted: isCompleted,
                        durationSeconds: taskData['timerDurationSeconds'] ?? 0,
                        taskService: _taskService, // Pass the service
                        onChanged: (value) => checkboxChanged(value, taskId),
                        deleteTask: (p0) => deleteTask(taskId),
                        onTap: () {
                          if (!isCompleted) {
                            _navigateToFocusScreen(taskData, taskId);
                          }
                        },
                        // --- WIRE UP THE NEW EDIT CALLBACK ---
                        onEdit: () {
                          _showTaskSheet(taskDoc: doc);
                        },
                        // --- END WIRE UP ---
                      );
                    },
                  );
                },
              ))
            ],
          )),
        ],
      ),
    );
  }
}