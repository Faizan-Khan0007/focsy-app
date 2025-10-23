
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/features/auth/screens/auth_screen.dart';
import 'package:my_todo_app/features/home/screens/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/tasks/screens/todo.dart';
import 'package:my_todo_app/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //initialize the hive

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(),
        // Apply Poppins globally
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder:(context, snapshot) {
          if(snapshot.connectionState==ConnectionState.waiting){
             return  const Scaffold(
              body: Center(child: CircularProgressIndicator(),),
             );
          }   
          if(snapshot.hasData){
            return const MyTodo();
          }   
          return const AuthScreen();
        },),
    );
  }
}
