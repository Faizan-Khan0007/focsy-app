import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/routine/screens/routine_details_screen.dart';
import 'package:my_todo_app/features/routine/services/routine_service.dart';
// We will create this file in the next step 

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final RoutineService _routineService = RoutineService();
  final TextEditingController _templateNameController = TextEditingController();

  // --- Function to show the "Add New Template" bottom sheet ---
  void __showAddOrEditTemplateSheet({String? existingRoutineId, String? existingName}) {
    bool isEditing = existingRoutineId != null;
    if(isEditing){
      _templateNameController.text=existingName??'';
    }else{
      _templateNameController.clear();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Edit Template Name" : "New Routine Template", // Dynamic title
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _templateNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "e.g., 'JEE Weekday Plan'",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
                onSubmitted: (_) { // Allow submit on enter
                   if (isEditing) {
                    _updateRoutineTemplate(existingRoutineId);
                  } else {
                    _addRoutineTemplate();
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // --- Call the correct function ---
                    if (isEditing) {
                      _updateRoutineTemplate(existingRoutineId);
                    } else {
                      _addRoutineTemplate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Save Changes" : "Create Template", // Dynamic button text
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- Function to add a new template ---
  void _addRoutineTemplate() {
    if (_templateNameController.text.trim().isNotEmpty) {
      _routineService.addRoutineTemplate(
        context,
        _templateNameController.text.trim(),
      );
      _templateNameController.clear();
      Navigator.pop(context); // Close the bottom sheet
    }
  }
  
  void _updateRoutineTemplate(String routineId) {
     if (_templateNameController.text.trim().isNotEmpty) {
      _routineService.updateRoutineTemplateName(
        context: context,
        routineId: routineId,
        newName: _templateNameController.text.trim(),
      );
      _templateNameController.clear();
      Navigator.pop(context); // Close the bottom sheet
    }
  }

  // --- Function to navigate to the details screen ---
  void _navigateToDetails(String routineId, String routineName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineDetailsScreen(
          routineId: routineId,
          routineName: routineName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: __showAddOrEditTemplateSheet,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Routine Template',
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 24.0, bottom: 20.0),
              child: Text(
                "My Routines", // Title is now "My Routines"
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // --- Routine Template List ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _routineService.getRoutinesStream(), // Gets the list of templates
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading routines."));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No routine templates yet.\nTap '+' to create your first plan!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Build the list of ROUTINE TEMPLATES
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      String routineId = doc.id;
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String templateName = data['name'] ?? 'No Name';

                      return ListTile(
                        leading: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                        title: Text(
                          templateName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "Tap to view or edit items",
                           style: GoogleFonts.poppins(),
                        ),
                       trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Squeeze buttons together
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.grey[600], size: 22),
                              onPressed: () {
                                // Call the bottom sheet in "edit" mode
                                __showAddOrEditTemplateSheet(
                                  existingRoutineId: routineId,
                                  existingName: templateName
                                );
                              },
                              tooltip: "Edit name",
                            ),
                            IconButton( 
                              icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 22),
                              onPressed: () {
                                // Optional: Show confirmation dialog
                                _routineService.deleteRoutineTemplate(context, routineId);
                              },
                              tooltip: "Delete routine",
                            ),
                          ],
                        ),
                        onTap: () {
                          // Go to the new details screen
                          _navigateToDetails(routineId, templateName);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}