import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/common/widgets/show_flushbar.dart'; // Import for SnackBar
import 'package:my_todo_app/features/auth/services/auth_service.dart';
// Import the ProfileService
import 'package:my_todo_app/features/profile/services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get instances of our services
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
              // --- User Avatar ---
              CircleAvatar(
                radius: 50,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                backgroundColor: Colors.grey[200], // Fallback color
                child: currentUser?.photoURL == null
                    ? Text(
                        // Show first letter of name if no photo
                        currentUser?.displayName?.isNotEmpty == true
                            ? currentUser!.displayName![0].toUpperCase()
                            : "U", // Default to 'U' if no name
                        style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor),
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // --- User Name ---
              Text(
                currentUser?.displayName ?? 'User Name',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // --- User Email ---
              Text(
                currentUser?.email ?? 'user@example.com',
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- STREAK DISPLAY ---
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
                    // This StreamBuilder listens to the user's doc
                    StreamBuilder<DocumentSnapshot>(
                      stream: profileService.getUserDataStream(),
                      builder: (context, snapshot) {
                        // While loading, show a placeholder
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        // If no data (or doc deleted), show 0
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
                        // We have data! Show the streak
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
                      },
                    ),
                  ],
                ),
              ),
              // --- END STREAK DISPLAY ---

              const SizedBox(height: 20), // Reduced space

              // --- NEW: "STATS COMING SOON" BUTTON ---
              InkWell(
                onTap: () {
                  // Just show a simple snackbar
                  showTopFlushbar(context, "Full statistics are coming soon!");
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            "My Statistics",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "COMING SOON",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- END NEW BUTTON ---

              const SizedBox(height: 30), // Adjusted space

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