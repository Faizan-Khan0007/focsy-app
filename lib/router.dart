// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:my_todo_app/features/auth/screens/auth_screen.dart';
import 'package:my_todo_app/features/auth/screens/otp_screen.dart';
import 'package:my_todo_app/features/tasks/screens/tasks_screen.dart';

Route<dynamic> generateRoute(RouteSettings routeSettings){
  switch(routeSettings.name){
    case AuthScreen.routeName:
        return MaterialPageRoute(
          settings: routeSettings,
          builder:(context) => const AuthScreen(),);
     case TasksScreen.routeName:
        return MaterialPageRoute(
          settings: routeSettings,
          builder:(context) => const TasksScreen(),);  
     case OtpScreen.routeName:
       final arguments = routeSettings.arguments as Map<String,dynamic>;
       final phoneNumber=arguments['phoneNumber'] as String;
       return MaterialPageRoute(
        settings: routeSettings,
        builder: (context) => OtpScreen(phoneNumber: phoneNumber),);      
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Route not found')),
        ),
      );      
  }
}