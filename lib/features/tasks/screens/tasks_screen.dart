import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:my_todo_app/features/tasks/services/task_service.dart';
import 'package:my_todo_app/features/tasks/widgets/todo_tile.dart';
import 'package:my_todo_app/widget/dialog_box.dart';

class TasksScreen extends StatefulWidget {
  static const String routeName = '/tasks-screen';
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  //services
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final _controller = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  //functions call taskservice methods
  void deleteTask(String taskId){
    _taskService.deleteTask(context, taskId);
  }
  void checkboxChanged(bool?value,String taskId){
    if(value==null)return;
    _taskService.updateTaskCompletion(context, taskId, value);
  }
  void saveNewTask() {
    if (_controller.text.trim().isEmpty) return;
    _taskService.addTask(context, _controller.text.trim());
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

  @override
  Widget build(BuildContext context) {
    //final screenHeight=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text("TODO TASKS"),
      //   backgroundColor: Colors.blueGrey,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, size: 28),
        tooltip: 'Add Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Stack(
        children: [
           Positioned(
            top: -50,
            left: -100,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 0,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
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
                child: Center(
                  child: Text(
                    "Todo Tasks", // Header from design
                    style: GoogleFonts.poppins(
                      fontSize: 30, // Larger header font
                      fontWeight: FontWeight.bold, // Bold header
                      color: Colors.black87,
                    ),
                  ),
                ),
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
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tasks yet. Add your first task!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 90.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc=snapshot.data!.docs[index];
                    Map<String,dynamic> taskData=doc.data() as Map<String,dynamic>;//firestore returns data in the form of map data like json object so we are converting to dart map to easily worked on 
                    String taskName=taskData['taskName']??'Unnamed Task';
                    bool isCompleted=taskData['isCompleted']?? false;
                    String taskId=doc.id;
                    return TodoTile(
                      taskId: taskId,
                      initialTaskName: taskName,
                      initialIsCompleted: isCompleted,
                      onChanged: (value)=>checkboxChanged(value, taskId),
                      deleteTask: (p0) => deleteTask(taskId),);
                  },);
                },
              ))
            ],
          )),
        ],
      ),
    );
  }
}
