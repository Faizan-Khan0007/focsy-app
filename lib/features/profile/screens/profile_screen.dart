import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:my_todo_app/features/profile/services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();
    final ProfileService profileService = ProfileService();
    return Scaffold(
      backgroundColor: Colors.white, // Set background
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        // Remove the back arrow
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                backgroundColor: Colors.grey[200],
                child: currentUser?.photoURL == null
                    ? Text(
                        currentUser?.displayName?.isNotEmpty == true
                            ? currentUser!.displayName![0].toUpperCase()
                            : "U",
                        style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              //name
              Text(
                currentUser?.displayName ?? 'User Name',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              //email
              Text(
                currentUser?.email ?? 'user@example.com',
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.orange.shade200, width: 1.5)),
                child: Column(
                  children: [
                    Text(
                      'Your Daily Streak',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500),
                    ),
                     const SizedBox(height: 10),
                     StreamBuilder<DocumentSnapshot>(
                      stream: profileService.getUserDataStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        //if no data show 0
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text(
                            "0 🔥",
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final int streak = data['currentStreak'] ?? 0;
                         return Text(
                          "$streak 🔥",
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: streak > 0 ? Colors.orange[700] : Colors.grey,
                          ),
                        );
                      },), 
                  ],
                ),        
              ),
              const SizedBox(height: 40),

              // --- Sign Out Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.logout_outlined, size: 20),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  await authService.signOut(context);
                  // StreamBuilder in main.dart handles navigation
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
