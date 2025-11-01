// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart';
import 'package:my_todo_app/features/tasks/services/task_service.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskService _taskService = TaskService();

  String?get currentUserId => _auth.currentUser?.uid;

  CollectionReference _userRoutineCollection(){
    final userId=currentUserId;
    if(userId==null){
      throw Exception("User is not logged in");
    }
    return _firestore.collection('users').doc(userId).collection('routine');
  }

  //get a real time stream of routine items
  Stream<QuerySnapshot> getRoutineStream(){
    try{
     return _userRoutineCollection().orderBy('createdAt',descending: false).snapshots();
    }catch(e){
       print("Error getting routine stream: $e");
       return const Stream.empty();
    }
  }

  //CRUD operations

  //Add a new item to routine list
  Future<void> addRoutineItem(BuildContext context,String title,String description)async{
    if(title.trim().isEmpty){
      showTopFlushbar(context, "Routine title cannot be empty.");
      return;
    }
    try{
      await _userRoutineCollection().add({
        'title':title.trim(),
        'description':description.trim(),
        'createdAt':Timestamp.now(),
      });
    }catch(e){
      showTopFlushbar(context, "Error adding routine item: ${e.toString}");
    }
  }

  //delete an item from the routine list
  Future<void> deleteRoutineItem(BuildContext context,String itemId)async{
    try{
     await _userRoutineCollection().doc(itemId).delete();
    }catch(e){
      showTopFlushbar(context, "Error deleting routine item: ${e.toString()}");
    }
  }

  //USP 
  // converts selected routine items into actual tasks
  // takes title and create a task
  Future<void> convertSelectedToTasks(BuildContext context,Map<String,String> selectedItems)async{
    if(selectedItems.isEmpty){
      showTopFlushbar(context, "No items selected to convert.");
      return;
    }
    try{
      int convertedCount=0;
      for(var entry in selectedItems.entries){
        String itemId = entry.key;
        String taskTitle = entry.value;
        await _taskService.addTask(context, taskTitle);
        await _userRoutineCollection().doc(itemId).delete();
        convertedCount=convertedCount+1;
      }
      showTopFlushbar(context, "$convertedCount routine items moved to tasks!");
    }catch(e){
      showTopFlushbar(context, "Error converting items: ${e.toString()}");
    }
  }
}