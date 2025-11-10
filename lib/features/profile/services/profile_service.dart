// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- Helper Function ---
  // Gets a reference to the current user's document
  DocumentReference _getUserDocRef() {
    final userId = currentUserId;
    if (userId == null) throw Exception("User is not logged in");
    return _firestore.collection('users').doc(userId);
  }

  // --- 1. Get User Data (for Profile Screen UI) ---
  // Gets a real-time stream of the user's document
  // The ProfileScreen will use this to show the streak
  Stream<DocumentSnapshot> getUserDataStream() {
    try {
      return _getUserDocRef().snapshots();
    } catch (e) {
      print("Error getting user stream: $e");
      return const Stream.empty();
    }
  }

  // --- 2. The Core Streak Logic (to be called by NavBarScreen) ---
  // This function checks if the streak needs to be updated
  // It returns 'true' if the daily quote should be shown
  Future<bool> checkAndUpdateStreak() async {
    try {
      final userDoc = await _getUserDocRef().get();

      if (!userDoc.exists) {
        print("ProfileService: User document not found.");
        return false; // Don't show quote if doc doesn't exist
      }

      final data = userDoc.data() as Map<String, dynamic>;
      // Read the streak, default to 0 if it's null
      final int currentStreak = data['currentStreak'] ?? 0;
      final Timestamp? lastLoginTimestamp = data['lastLoginDate'];

      final DateTime today = DateTime.now();

      // --- FIX: Handle First-Time Login (Day 1) AND Old Users ---
      if (lastLoginTimestamp == null) {
        print("ProfileService: First-time login or old user. Setting streak to 1.");
        // Set the login date to today AND set streak to 1
        await _getUserDocRef().update({
          'lastLoginDate': Timestamp.now(),
          'currentStreak': 1 // <-- THIS IS THE FIX
        });
        return true; // Show the quote!
      }
      // --- END FIX ---

      final DateTime lastLoginDate = lastLoginTimestamp.toDate();

      // Check if the last login was on the same day
      if (_isSameDay(lastLoginDate, today)) {
        print("ProfileService: User already logged in today. Streak: $currentStreak");
        return false; // Don't show quote, already logged in today
      }

      // Check if the last login was yesterday (Streak continues)
      final DateTime yesterday = today.subtract(const Duration(days: 1));
      if (_isSameDay(lastLoginDate, yesterday)) {
        print("ProfileService: Streak continues! Updating streak to ${currentStreak + 1}");
        // Increment streak
        await _getUserDocRef().update({
          'currentStreak': currentStreak + 1,
          'lastLoginDate': Timestamp.now(), // Update last login to today
        });
        return true; // Show the quote!
      }

      // If last login was not today or yesterday, the streak is broken
      print("ProfileService: Streak broken. Resetting streak to 1.");
      await _getUserDocRef().update({
        'currentStreak': 1, // Reset streak to 1
        'lastLoginDate': Timestamp.now(), // Update last login to today
      });
      return true; // Show the quote!
      
    } catch (e) {
      print("Error in checkAndUpdateStreak: $e");
      return false; // Don't show quote if there's an error
    }
  }

  // --- Helper to compare dates (ignoring time) ---
  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
           dateA.month == dateB.month &&
           dateA.day == dateB.day;
  }
}