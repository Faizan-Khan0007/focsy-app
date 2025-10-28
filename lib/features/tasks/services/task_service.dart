import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart';

class TaskService {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 String? get currentUserId => _auth.currentUser?.uid;
 
 CollectionReference _userTasksCollection(){
  final userId=currentUserId;
  if(userId==null){
    throw Exception("User is not logged in");
  }
  return _firestore.collection('users').doc(userId).collection('tasks');
 }

 //real time stream of tasks for current user ordered by created time
 Stream<QuerySnapshot> getTasksStream(){
  try{
    return _userTasksCollection().orderBy('createdAt',descending: true).snapshots();
  }catch(e){
    print("Error getting tasks stream: $e");
    return const Stream.empty();
  }
 }

 //CRUD Operations
 //Adding a new task to Firestore
 Future<void> addTask(BuildContext context,String taskName)async{
  if(taskName.trim().isEmpty){
    showTopFlushbar(context, "Task name cannot be empty.");
    return;
  }
  try{
    await _userTasksCollection().add({
      'taskName':taskName.trim(),
      'isCompleted':false,
      'createdAt':Timestamp.now(),
      // --- Timer Fields (Placeholders for V1) ---
        // Add these when implementing the timer feature
        // 'timerDurationSeconds': null, // e.g., 1500 for 25 minutes
        // 'timerRemainingSeconds': null,
        // 'isTimerRunning': false,
        // --- End Timer Fields ---
    });
  }catch(e){
    showTopFlushbar(context, "Error adding task: ${e.toString()}");
  }
 }
  
 Future<void> updateTaskCompletion(BuildContext context,String taskId,bool isCompleted)async{
  try{
    await _userTasksCollection().doc(taskId).update({
      'isCompleted':isCompleted,
    //later on timer update logic  
    });
  }catch(e){
     showTopFlushbar(context, "Error updating task: ${e.toString()}");
  }
 } 

 //Delete a specific task from Firestore
 Future<void> deleteTask(BuildContext context,String taskId)async{
   try{
    await _userTasksCollection().doc(taskId).delete();
    //later timer delete logic
   }catch(e){
    showTopFlushbar(context, "Error deleting task: ${e.toString()}");
   }
 }
}