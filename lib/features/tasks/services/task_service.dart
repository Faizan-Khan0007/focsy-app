import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart'; // Assuming your flushbar is here

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get a stream of tasks for the current user
  Stream<QuerySnapshot> getTasksStream() {
    if (currentUserId == null) {
      // Return an empty stream if user is not logged in (shouldn't happen with AuthGate)
      return const Stream.empty();
    }
    return _firestore
        .collection('users') // Collection for all users
        .doc(currentUserId) // Document for the current user
        .collection('tasks') // Subcollection for this user's tasks
        .orderBy('createdAt', descending: true) // Order by creation time, newest first
        .snapshots(); // Get a stream of snapshots
  }

  // Add a new task
  Future<void> addTask(BuildContext context, String taskName) async {
    if (currentUserId == null || taskName.trim().isEmpty) {
      showTopFlushbar(context, "Cannot add task. Please ensure you are logged in.");
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .add({
        'taskName': taskName.trim(),
        'isCompleted': false,
        'createdAt': Timestamp.now(), // Store creation time
        // Add other fields later if needed (e.g., timer info)
      });
      // No need to show success flushbar, list updates automatically
    } catch (e) {
      showTopFlushbar(context, "Error adding task: ${e.toString()}");
    }
  }

  // Update task completion status
  Future<void> updateTaskCompletion(BuildContext context, String taskId, bool isCompleted) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(taskId) // Reference the specific task document by its ID
          .update({'isCompleted': isCompleted});
    } catch (e) {
      showTopFlushbar(context, "Error updating task: ${e.toString()}");
    }
  }

  // Delete a task
  Future<void> deleteTask(BuildContext context, String taskId) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(taskId) // Reference the specific task document by its ID
          .delete();
      // Optional: Show success message if needed
      // showTopFlushbar(context, "Task deleted.");
    } catch (e) {
      showTopFlushbar(context, "Error deleting task: ${e.toString()}");
    }
  }
}
