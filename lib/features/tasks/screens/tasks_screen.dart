import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:my_todo_app/features/navbar/widgets/daile_quote_dialog.dart';
import 'package:my_todo_app/features/tasks/screens/focus_timer_screen.dart';
import 'package:my_todo_app/features/tasks/services/task_service.dart';
import 'package:my_todo_app/features/tasks/widgets/todo_tile.dart';
import 'package:my_todo_app/widget/dialog_box.dart'; // <-- IMPORT NEW SCREEN

class TasksScreen extends StatefulWidget {
  static const String routeName = '/tasks-screen';
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  //services
  final User? currentUser = FirebaseAuth.instance.currentUser;
  //final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final _controller = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  //functions call taskservice methods
  void deleteTask(String taskId) {
    _taskService.deleteTask(context, taskId);
  }

  void checkboxChanged(bool? value, String taskId) {
    if (value == null) return;
    _taskService.updateTaskCompletion(context, taskId, value);
  }

  void saveNewTask() {
    if (_controller.text.trim().isEmpty) return;
    _taskService.addTask(
      context,
      _controller.text.trim(),
    );
    _controller.clear();
    Navigator.of(context).pop();
  }

  void createNewTask() {
    _controller.clear();
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
            controller: _controller,
            onsaved: saveNewTask,
            oncancel: () => Navigator.of(context).pop());
      },
    );
  }

  void _showQuote() {
    showDialog(
      context: context,
      builder: (context) => const DailyQuoteDialog(),
    );
  }

  // --- NEW: Function to navigate to Focus Screen ---
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
            // This callback is passed to FocusScreen to mark task complete
            checkboxChanged(value, taskId);
          },
        ),
      ),
    );
  }
  // --- END NEW ---

  @override
  Widget build(BuildContext context) {
    //final screenHeight=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: 'Add Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -100,
            child: Opacity(
              opacity: 0.1, // Made it more subtle
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor, // Use theme color
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 0,
            child: Opacity(
              opacity: 0.1, // Made it more subtle
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor, // Use theme color
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
                    top: 80.0, left: 24.0, bottom: 20.0,), // More top padding
                // --- MODIFIED HEADER ---
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Todo Tasks", // Header from design
                      style: GoogleFonts.poppins(
                        fontSize: 30, // Larger header font
                        fontWeight: FontWeight.bold, // Bold header
                        color: Colors.black87,
                      ),
                    ),
                    // --- YOUR NEW QUOTE BUTTON ---
                    IconButton(
                      onPressed: _showQuote,
                      icon: Icon(
                        Icons.format_quote_rounded, // The quote icon
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                        size: 28,
                      ),
                      tooltip: "Quote of the Day",
                    ),
                    // --- END NEW BUTTON ---
                  ],
                ),
                // --- END MODIFIED HEADER ---
              ),
              //task list from the stream
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
                    // We can add the "Plan Your Day" button here later
                    return Center(
                      child: Text(
                        "No tasks yet. Add your first task!",
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

                      return TodoTile(
                        key: ValueKey(taskId),
                        // taskService: _taskService, // No longer needed in tile
                        taskId: taskId,
                        taskName: taskData['taskName'] ?? 'Unnamed Task',
                        isCompleted: taskData['isCompleted'] ?? false,
                        durationSeconds: taskData['timerDurationSeconds'] ?? 0,
                        onChanged: (value) => checkboxChanged(value, taskId),
                        deleteTask: (p0) => deleteTask(taskId),
                        // --- WIRE UP THE TAP CALLBACK ---
                        onTap: () {
                          // Don't navigate if task is already complete
                          if (!(taskData['isCompleted'] ?? false)) {
                             _navigateToFocusScreen(taskData, taskId);
                          }
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