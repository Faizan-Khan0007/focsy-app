// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart';
import 'package:my_todo_app/features/tasks/screens/todo.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<void> signUpUserAndSendOTP({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      showTopFlushbar(context, "Sign up successful!");
    }on FirebaseAuthException catch (e) {
      showTopFlushbar(context, e.message??"An error occured during sign up.");
    }catch(e){
      showTopFlushbar(context, "An unexpected error occured");
    }
  }

  //this fn is called by otp screen when the user enters the code and connect
  //backend to verify the otpee
  void verifyOTP({
    required BuildContext context,
    required String otp,
  }) async {
    showTopFlushbar(context, "Verfication Successful");
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushNamedAndRemoveUntil(
      context,
      MyTodo.routeName,
      (route) => false,
    );
  }

  Future<void> signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try{
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      showTopFlushbar(context, "Sign In successful!"); 
    }on FirebaseAuthException catch (e) {
      showTopFlushbar(context, e.message ?? "An error occurred during sign in.");
    } catch (e) {
      showTopFlushbar(context, "An unexpected error occurred.");
    }
  }

  //Sign in with google
  Future<void> signInWithGoogle(BuildContext context)async{
    try{
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if(googleUser==null){
        showTopFlushbar(context, "Google Sign in cancelled.");
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      showTopFlushbar(context, "Google Sign in successful!");
    } on FirebaseAuthException catch(e){
      showTopFlushbar(context, e.message?? "Google Sign in failed.");
    }catch (e){
      showTopFlushbar(context, "An unexpected error occurred: ${e.toString()}");
    }
  }

  //Sign out
  Future<void> signOut(BuildContext context)async{
    try{
      await _googleSignIn.signOut();
      await _auth.signOut();
    }catch(e){
      showTopFlushbar(context, "Error signing out: ${e.toString()}");
    }
  }
}
