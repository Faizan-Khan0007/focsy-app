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

  CollectionReference _getRoutineTemplatesCollection() { // Renamed for clarity
    final userId = currentUserId;
    if (userId == null) throw Exception("User is not logged in");
    return _firestore.collection('users').doc(userId).collection('routines');
  }

  CollectionReference _getRoutineItemsCollection() { // Renamed for clarity
    final userId = currentUserId;
    if (userId == null) throw Exception("User is not logged in");
    return _firestore.collection('users').doc(userId).collection('routineItems');
  }
  
   // --- ROUTINE (TEMPLATE) FUNCTIONS ---

  // Get a stream of the ROUTINE TEMPLATES (e.g., "JEE Daily", "Weekend")
  Stream<QuerySnapshot> getRoutinesStream() {
    try {
      // Use the new, clearer function name
      return _getRoutineTemplatesCollection().orderBy('createdAt', descending: false).snapshots();
    } catch (e) {
      print("Error getting routines stream: $e");
      return const Stream.empty();
    }
  }
  //CRUD operations for template
  Future<void> addRoutineTemplate(BuildContext context, String templateName) async {
    if (templateName.trim().isEmpty) {
      showTopFlushbar(context, "Template name cannot be empty.");
      return;
    }
    try {
      // Use the new, clearer function name
      await _getRoutineTemplatesCollection().add({
        'name': templateName.trim(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      showTopFlushbar(context, "Error adding routine: ${e.toString()}");
    }
  }

  //updating the routine item template name
  Future<void> updateRoutineTemplateName({required BuildContext context,required String routineId,required String newName})async{
    if (newName.trim().isEmpty) {
      showTopFlushbar(context, "Template name cannot be empty.");
      return;
    }
    try{
      await _getRoutineTemplatesCollection().doc(routineId).update({'name':newName.trim()});
    }catch(e){
       showTopFlushbar(context, "Error updating routine: ${e.toString()}");
    }
  }
  
  // Delete an entire ROUTINE TEMPLATE (and all its items)
  Future<void> deleteRoutineTemplate(BuildContext context, String routineId) async {
    try {
      // 1. Delete the template doc
      // Use the new, clearer function name
      await _getRoutineTemplatesCollection().doc(routineId).delete();

      // 2. Query and delete all items linked to this template
      // Use the new, clearer function name
      QuerySnapshot itemsSnapshot = await _getRoutineItemsCollection()
          .where('routineId', isEqualTo: routineId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
    } catch (e) {
      showTopFlushbar(context, "Error deleting routine: ${e.toString()}");
    }
  }

  // --- ROUTINE ITEM FUNCTIONS ---

  // Get a stream of ITEMS *inside* a specific routine template
  Stream<QuerySnapshot> getRoutineItemsStream(String routineId) {
    try {
      // Use the new, clearer function name
      return _getRoutineItemsCollection()
          .where('routineId', isEqualTo: routineId)
          .orderBy('createdAt', descending: false)
          .snapshots();
    } catch (e) {
      print("Error getting routine items stream: $e");
      return const Stream.empty();
    }
  }
  //CRUD operations

  //Add a new item to a specific routine template
  Future<void> addRoutineItem({
    required BuildContext context,
    required String routineId,
    required String title,
    required String description,
    required int durationSeconds,
  }) async {
    if (title.trim().isEmpty) {
      showTopFlushbar(context, "Goal title cannot be empty.");
      return;
    }
    try {
      // Use the new, clearer function name
      await _getRoutineItemsCollection().add({
        'routineId': routineId,
        'title': title.trim(),
        'description': description.trim(),
        'durationSeconds': durationSeconds,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      showTopFlushbar(context, "Error adding item: ${e.toString()}");
    }
  }

  // --- NEW: UPDATE an existing item ---
  Future<void> updateRoutineItem({
    required BuildContext context,
    required String itemId,
    required String title,
    required String description,
    required int durationSeconds,
  }) async {
    if (title.trim().isEmpty) {
      showTopFlushbar(context, "Goal title cannot be empty.");
      return;
    }
    try {
      await _getRoutineItemsCollection().doc(itemId).update({
        'title': title.trim(),
        'description': description.trim(),
        'durationSeconds': durationSeconds,
        // We don't update createdAt, as that's just for ordering
      });
    } catch (e) {
      showTopFlushbar(context, "Error updating item: ${e.toString()}");
    }
  }

   // Delete a single ITEM from a routine template
  Future<void> deleteRoutineItem(BuildContext context, String itemId) async {
    try {
      // Use the new, clearer function name
      await _getRoutineItemsCollection().doc(itemId).delete();
    } catch (e) {
      showTopFlushbar(context, "Error deleting item: ${e.toString()}");
    }
  }

   // --- THE NEW USP FUNCTION ---
  // Copies selected items from a routine template to the main Tasks list
  Future<void> loadItemsToTasks(
    BuildContext context,
    List<Map<String, dynamic>> selectedItems // List of item data maps
  ) async {
    if (selectedItems.isEmpty) {
      showTopFlushbar(context, "No items selected to load.");
      return;
    }

    try {
      int loadedCount = 0;
      for (var itemData in selectedItems.reversed) {
        // Use TaskService to add this item as a NEW task
        await _taskService.addTask(
          context,
          itemData['title'] ?? 'No Title',
          // We pass the timer info directly
          durationSeconds: itemData['durationSeconds'] ?? 0,
          description: itemData['description'] ?? '',
        );
        loadedCount++;
      }
      showTopFlushbar(context, "$loadedCount items loaded to your daily tasks!");
    } catch (e) {
      showTopFlushbar(context, "Error loading items: ${e.toString()}");
    }
  }
}