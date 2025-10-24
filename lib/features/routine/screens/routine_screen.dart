import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daily Routine",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
         backgroundColor: Colors.white,
         foregroundColor: Colors.black87,
         elevation: 1,
         shadowColor: Colors.grey.withOpacity(0.2),
      ),
      body: Center(
        child: Text(
          'Routine Screen - Coming Soon!',
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
