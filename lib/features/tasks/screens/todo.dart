import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';// Assuming TodoTile is here and updated
import 'package:my_todo_app/features/tasks/services/task_service.dart';
import 'package:my_todo_app/widget/dialog_box.dart';
import 'package:my_todo_app/widget/todotile.dart'; // Import TaskService

class MyTodo extends StatefulWidget {
  static const String routeName = '/todo-screen';
  const MyTodo({super.key});

  @override
  State<MyTodo> createState() => _MyTodoState();
}

class _MyTodoState extends State<MyTodo> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService(); // Instantiate TaskService
  final _controller = TextEditingController();

  // No local list needed, StreamBuilder handles data

  @override
  void initState() {
    super.initState();
    // StreamBuilder handles data loading
  }

  // --- Functions call TaskService methods ---

  // Called when checkbox is tapped
  void checkboxChanged(bool? value, String taskId) {
    if (value == null) return;
    _taskService.updateTaskCompletion(context, taskId, value);
    // UI updates via StreamBuilder
  }

  // Called when saving a new task from the dialog
  void saveNewTask() {
    if (_controller.text.trim().isEmpty) return;
    _taskService.addTask(context, _controller.text.trim());
    _controller.clear();
    Navigator.of(context).pop(); // Close the dialog
    // UI updates via StreamBuilder
  }

  // Opens the dialog to add a new task
  void createNewTask() {
    _controller.clear(); // Clear controller before showing dialog
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onsaved: saveNewTask, // Corrected spelling if needed
          oncancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  // Called when deleting a task (e.g., via Slidable action)
  void deleteTask(String taskId) {
    _taskService.deleteTask(context, taskId);
    // UI updates via StreamBuilder
  }

  // Called when logout button is pressed
  void _signOut() async {
    await _authService.signOut(context);
    // StreamBuilder in main.dart handles navigation back to AuthScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: false,
        title: Text(
          // Display user's first name or fallback
          "Welcome, ${currentUser?.displayName?.split(' ').first ?? 'User'}",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.black54),
            onPressed: _signOut,
            tooltip: "Sign Out",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: const Color(0xFF6398A7),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column( // Use Column for structure
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16.0, bottom: 10.0),
            child: Text(
              "Your Tasks",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            // --- Firestore StreamBuilder ---
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskService.getTasksStream(), // Listen to the stream
              builder: (context, snapshot) {
                // Handle errors
                if (snapshot.hasError) {
                  print("Firestore Error: ${snapshot.error}"); // Log the error
                  return Center(child: Text("Error loading tasks. Please try again."));
                }
                // Show loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show message if no tasks
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No tasks yet!\nTap '+' to add one.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                // --- Display the list of tasks ---
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80.0), // Padding for FAB
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    // Get the task document
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    // Get data as a Map
                    Map<String, dynamic> taskData = doc.data() as Map<String, dynamic>;
                    String taskName = taskData['taskName'] ?? 'Unnamed Task';
                    bool isCompleted = taskData['isCompleted'] ?? false;
                    String taskId = doc.id; // Crucial: Get the document ID

                    return TodoTile(
                      key: ValueKey(taskId), // Add key for better list updates
                      taskname: taskName,
                      taskcompleted: isCompleted,
                      onChanged: (value) => checkboxChanged(value, taskId), // Pass taskId
                      deleteTask: (ctx) => deleteTask(taskId), // Pass taskId
                    );
                  },
                );
              },
            ),
            // --- End StreamBuilder ---
          ),
        ],
      ),
    );
  }
}

