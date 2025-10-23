// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/screens/auth_screen.dart';


class MyHome extends StatefulWidget {
  static const String routeName='/home-screen';
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -100,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 0,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
                ),
              ),
            ),
          ),
          Center(
            // Apply padding to shift the image upwards
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/login.png'),
                          fit: BoxFit
                              .cover, // Ensures the image covers the container properly
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text("Get Your Things done with todo",
                      style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ))),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text(
                        "Welcome to your personal productivity hub!\n   Stay organized, manage your tasks,and \nachieve more with our advanced To-Do app.",
                        style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                        ))),
                  ),
                  SizedBox(
                    height: 80,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AuthScreen.routeName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6398A7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: Text("GET STARTED",
                        style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ))),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
