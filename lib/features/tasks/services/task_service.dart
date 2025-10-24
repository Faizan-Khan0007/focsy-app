import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}