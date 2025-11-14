// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference _userTasksCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception("User is not logged in");
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  //real time stream of tasks for current user ordered by created time
  Stream<QuerySnapshot> getTasksStream() {
    try {
      return _userTasksCollection()
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }

  //CRUD Operations
  //Adding a new task to Firestore
  Future<void> addTask(
    BuildContext context,
    String taskName, {
    int durationSeconds = 0, // Default to 0 if not provided
    String description = '', // Default to empty if not provided
  }) async {
    if (taskName.trim().isEmpty) {
      showTopFlushbar(context, "Task name cannot be empty.");
      return;
    }
    try {
      await _userTasksCollection().add({
        'taskName': taskName.trim(),
        'description': description, // Add description
        'isCompleted': false,
        'createdAt': Timestamp.now(),
        // Add timer fields (using 0 as default instead of null)
        'timerDurationSeconds': durationSeconds,
        'timerRemainingSeconds': durationSeconds, // Start with full duration
        'isTimerRunning': false,
      });
    } catch (e) {
      showTopFlushbar(context, "Error adding task: ${e.toString()}");
    }
  }

  //updating task details
  Future<void> updateTaskDetails({
    required BuildContext context,
    required String taskId,
    required String title,
    required String description,
    required int durationSeconds,
  }) async {
    if (title.trim().isEmpty) {
      showTopFlushbar(context, "Task title cannot be empty.");
      return;
    }
    try {
      await _userTasksCollection().doc(taskId).update({
        'taskName': title.trim(),
        'description': description.trim(),
        'timerDurationSeconds': durationSeconds,
        // We also reset the remaining time and pause the timer
        'timerRemainingSeconds': durationSeconds,
        'isTimerRunning': false,
      });
      showTopFlushbar(context, "Task updated successfully!");
    } catch (e) {
      showTopFlushbar(context, "Error updating task: ${e.toString()}");
    }
  }

  //updating task completion
  Future<void> updateTaskCompletion(
      BuildContext context, String taskId, bool isCompleted) async {
    try {
      await _userTasksCollection().doc(taskId).update({
        'isCompleted': isCompleted,
        'isTimerRunning': false,
        'timerRemainingSeconds': 0,
      });
    } catch (e) {
      showTopFlushbar(context, "Error updating task: ${e.toString()}");
    }
  }

  //Delete a specific task from Firestore
  Future<void> deleteTask(BuildContext context, String taskId) async {
    try {
      await _userTasksCollection().doc(taskId).delete();
      //later timer delete logic
    } catch (e) {
      showTopFlushbar(context, "Error deleting task: ${e.toString()}");
    }
  }

  // --Timer Functions
  Future<void> setTimerDuration(
      BuildContext context, String taskId, int durationSeconds) async {
    if (durationSeconds < 0) {
      durationSeconds = 0;
    }
    try {
      await _userTasksCollection().doc(taskId).update({
        'timerDurationSeconds': durationSeconds,
        'timerRemainingSeconds': durationSeconds,
        'isTimerRunning': false, //stopping the timer when setting new duration
      });
    } catch (e) {
      return showTopFlushbar(context, "Error setting timer : ${e.toString()}");
    }
  }

  Future<void> updateTimerState(BuildContext context, String taskId,
      {required int remainingSeconds, required bool isRunning}) async {
    try {
      await _userTasksCollection().doc(taskId).update({
        'timerRemainingSeconds': remainingSeconds,
        'isTimerRunning': isRunning,
      });
    } catch (e) {
      print("Error saving timer state: ${e.toString()}");
    }
  }

  // --- NEW FUNCTION (Step 4) ---
  // For background service to update timer
  Future<void> updateTimerStateNoContext(
    String taskId, {
    required int remainingSeconds,
    required bool isRunning,
  }) async {
    if (currentUserId == null) return; // Guard clause
    try {
      await _userTasksCollection().doc(taskId).update({
        'timerRemainingSeconds': remainingSeconds,
        'isTimerRunning': isRunning,
      });
    } catch (e) {
      print("Error saving timer state from background: ${e.toString()}");
    }
  }

  // --- NEW FUNCTION (Step 4) ---
  // For background service to complete task
  Future<void> updateTaskCompletionNoContext(
      String taskId, bool isCompleted) async {
    if (currentUserId == null) return; // Guard clause
    try {
      await _userTasksCollection().doc(taskId).update({
        'isCompleted': isCompleted,
        'isTimerRunning': false,
        'timerRemainingSeconds': 0,
      });
    } catch (e) {
      print("Error updating task from background: ${e.toString()}");
    }
  }
}