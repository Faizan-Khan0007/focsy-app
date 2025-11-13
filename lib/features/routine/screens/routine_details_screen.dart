import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/routine/services/routine_service.dart';
import 'package:my_todo_app/providers/nav_bar_provider.dart';
import 'package:provider/provider.dart';

class RoutineDetailsScreen extends StatefulWidget {
  final String routineId;
  final String routineName;

  const RoutineDetailsScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  @override
  State<RoutineDetailsScreen> createState() => _RoutineDetailsScreenState();
}

class _RoutineDetailsScreenState extends State<RoutineDetailsScreen> {
  final RoutineService _routineService = RoutineService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(); // For H:M:S

  // Map to store selected items for conversion
  // Key: Item ID, Value: Map of the item's data
  final Map<String, Map<String, dynamic>> _selectedItems = {};
  bool _isLoading = false;

  // --- MODIFIED: This function now handles BOTH adding and editing ---
  void _showAddOrEditItemSheet({Map<String, dynamic>? existingItem}) {
    bool isEditing = existingItem != null;

    // --- Pre-fill fields if editing ---
    if (isEditing) {
      _titleController.text = existingItem['title'] ?? '';
      _descriptionController.text = existingItem['description'] ?? '';
      final duration = Duration(seconds: existingItem['durationSeconds'] ?? 0);
      _durationController.text = duration.toString().split('.').first.padLeft(8, "0");
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _durationController.clear();
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
                // Dynamic title
                isEditing ? "Edit Goal" : "Add New Goal",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Goal Title (e.g., Physics)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Details (e.g., Chapter 4 & 5)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              // Duration
              TextField(
                controller: _durationController,
                decoration: InputDecoration(
                  hintText: "Planned Duration (e.g., 45m or 2:30:00)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.text, // For H:M:S or M
              ),
              const SizedBox(height: 20),
              // Add/Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // --- Call the correct function ---
                    if (isEditing) {
                      _updateRoutineItem(existingItem['id']);
                    } else {
                      _addRoutineItem();
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
                    // Dynamic button text
                    isEditing ? "Save Changes" : "Add Goal",
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

  // --- Parse Duration Function (Helper) ---
  int _parseDuration() {
    int totalSeconds = 0;
    final input = _durationController.text.trim();
    if (input.isNotEmpty) {
      final parts = input.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      try {
        if (parts.length == 3) { // HH:MM:SS
          totalSeconds = (parts[0] * 3600) + (parts[1] * 60) + parts[2];
        } else if (parts.length == 2) { // MM:SS
          totalSeconds = (parts[0] * 60) + parts[1];
        } else if (parts.length == 1) { // M (Minutes)
          totalSeconds = parts[0] * 60;
        }
      } catch (e) { /* Fails silently, totalSeconds remains 0 */ }
    }
    return totalSeconds;
  }
  
  // --- Function to add a new item ---
  void _addRoutineItem() {
    if (_titleController.text.trim().isEmpty) return;
    final totalSeconds = _parseDuration();

    _routineService.addRoutineItem(
      context: context,
      routineId: widget.routineId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: totalSeconds,
    );
    Navigator.pop(context); // Close the bottom sheet
  }

  // --- NEW: Function to update an item ---
  void _updateRoutineItem(String itemId) {
     if (_titleController.text.trim().isEmpty) return;
    final totalSeconds = _parseDuration();

    _routineService.updateRoutineItem(
      context: context, 
      itemId: itemId, 
      title: _titleController.text.trim(), 
      description: _descriptionController.text.trim(), 
      durationSeconds: totalSeconds
    );
    Navigator.pop(context); // Close the bottom sheet
  }


  // --- Function to "Load" selected items to the Tasks tab ---
  void _loadTasks() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item to load.")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // Convert the Map to the List<Map> the service expects
    final List<Map<String, dynamic>> itemsToLoad = _selectedItems.values.toList();

    await _routineService.loadItemsToTasks(context, itemsToLoad);
    
    // Clear selection and stop loading
    if (mounted) {
      setState(() {
        _selectedItems.clear();
        _isLoading = false;
      });
    }
  }

  // --- Function to navigate to the Tasks tab ---
  void _goToTasksScreen() {
    // 1. Pop this screen to go back to the main NavBarScreen
    Navigator.pop(context);
    // 2. Use the provider to tell the NavBarScreen to switch to Tab 0
    Provider.of<NavBarProvider>(context, listen: false).setIndex(0);
  }
 
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.routineName, // Show the template name in AppBar
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      // --- Modified Bottom Action Bar ---
       bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(), // Shape for the FAB
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // <-- THIS IS KEY
            children: <Widget>[
              // Left side: "View Tasks" button (your new idea)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TextButton.icon(
                  onPressed: _goToTasksScreen, // Call our new function
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    "View Tasks",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              // Right side: "Load Tasks" button (CHANGED: No more AnimatedOpacity)
              Padding(
                padding: const EdgeInsets.only(right: 16.0), // Padding on the right
                child: ElevatedButton(
                  // Button is disabled if loading OR if no items are selected
                  onPressed: (_isLoading || _selectedItems.isEmpty) ? null : _loadTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // This makes the button grayed out when disabled
                    disabledBackgroundColor: Colors.grey.shade300, 
                  ),
                  child: Text(
                    // Dynamic text
                    _selectedItems.isEmpty
                        ? "Select Items" // Text when disabled
                        : _selectedItems.length==1?"Load ${_selectedItems.length} Task":"Load ${_selectedItems.length} Tasks", // Text when enabled
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // --- THIS IS THE FIX ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // <-- MOVED TO CENTER
      // --- END FIX ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditItemSheet(), // Call the multi-purpose function
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Goal to this Routine',
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Make it pop a bit more
        child: const Icon(Icons.add),
      ),
      // --- End Modified Bottom Action Bar ---
      body: Column(
        children: [
          // --- Routine Items List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _routineService.getRoutineItemsStream(widget.routineId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading items."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No goals in this routine yet.\nTap '+' to add your first goal!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Build the list of checkable routine items
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120,top: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    String docId = doc.id;
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    
                    // This is the full data for the item
                    final itemData = {
                      'id': docId,
                      'title': data['title'] ?? 'No Title',
                      'description': data['description'] ?? '',
                      'durationSeconds': data['durationSeconds'] ?? 0,
                    };
                    
                    bool isSelected = _selectedItems.containsKey(docId);
                    final duration = Duration(seconds: itemData['durationSeconds'] as int);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedItems[docId] = itemData; // Store the full item data
                            } else {
                              _selectedItems.remove(docId);
                            }
                          });
                        },
                      ),
                      title: Text(
                        itemData['title']!.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.grey[500] : Colors.black87,
                          decoration: isSelected ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        // Show "Desc: ... | Duration: ..."
                        "Desc: ${itemData['description']!.toString().isEmpty ? 'None' : itemData['description']}\nDuration: ${duration.toString().split('.').first.padLeft(8, "0")}",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      // --- NEW: Trailing buttons for Edit and Delete ---
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: Colors.grey[600], size: 20),
                            onPressed: () {
                              // Call the bottom sheet in "edit" mode
                              _showAddOrEditItemSheet(existingItem: itemData);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                            onPressed: () {
                              _routineService.deleteRoutineItem(context, docId);
                              setState(() {
                                _selectedItems.remove(docId);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Show loading indicator at bottom if loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}