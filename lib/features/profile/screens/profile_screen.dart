// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart'; // Import AuthService

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService(); // Instantiate AuthService

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              // Add user profile picture if available (e.g., from Google Sign In)
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null, // Placeholder or default image
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              currentUser?.displayName ?? 'User Name',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              currentUser?.email ?? 'user@example.com',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Sign Out'),
              onPressed: () async {
                await authService.signOut(context);
                // StreamBuilder in main.dart handles navigation
              },
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  backgroundColor: Colors.red[50], // Light red background
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 40),
             Text(
              'Stats - Coming Soon!',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
