import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/routine/services/routine_service.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final RoutineService _routineService = RoutineService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<String, String> _selectedItems = {};
  bool _isLoading = false;

  void _addRoutineItem() {
    if (_titleController.text.trim().isNotEmpty) {
      _routineService.addRoutineItem(
          context, _titleController.text, _descriptionController.text);
      _titleController.clear();
      _descriptionController.clear();
      Navigator.of(context).pop();
    }
  }

  void _showAddRoutineSheet() {
    _titleController.clear();
    _descriptionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // Padding to avoid the keyboard
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only needed height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add New Goal",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Title TextField
              TextField(
                controller: _titleController,
                autofocus: true, // Automatically focus the title
                decoration: InputDecoration(
                  hintText: "Goal Title (e.g., Study Science)",
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
              // Description TextField
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Details (e.g., Finish Chapter 4...)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3, // Allow for more text
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 20),
              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addRoutineItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Add to Routine",
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
  void _convertTasks()async{
    setState(() {
       _isLoading=true;
    });
    await _routineService.convertSelectedToTasks(context, Map.from(_selectedItems));
    //clear the map now
    if(mounted){
      setState(() {
        _selectedItems.clear();
        _isLoading=false;
      });
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoutineSheet,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Routine Item',
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
             Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 24.0, bottom: 20.0),
              child: Text(
                "Today's Routine",
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

          // --routine list--
          Expanded(
            child:
              StreamBuilder<QuerySnapshot>(
                stream: _routineService.getRoutineStream(),
                 builder: (context, snapshot) {
                    if (snapshot.hasError) {
                    return const Center(child: Text("Error loading routine."));
                  }
                   if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No routine items yet.\nTap '+' to plan your day!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: snapshot.data!.docs.length, 
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc=snapshot.data!.docs[index];
                      String docId=doc.id;
                      Map<String,dynamic>data=doc.data() as Map<String,dynamic>;
                      String itemTitle=data['title'] ?? 'No Title';
                      String itemDescription=data['description'] ?? 'No Description';
                      bool isSelected = _selectedItems.containsKey(docId);

                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            setState(() {
                              if(value == true){
                                _selectedItems[docId]=itemTitle;
                              }else{
                                _selectedItems.remove(docId);
                              }
                            });
                          },),
                        title: Text(
                          itemTitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.grey[500] : Colors.black87,
                            decoration: isSelected ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ), 
                        subtitle: itemDescription.isNotEmpty
                            ? Text(
                                itemDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.grey[400] : Colors.grey[600],
                                  decoration: isSelected ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              )
                            : null,
                         trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                          onPressed: () {
                            _routineService.deleteRoutineItem(context, docId);
                            setState(() {
                              _selectedItems.remove(docId); // Remove from selection if deleted
                            });
                          },
                        ),   
                      );
                    },);
                 },
                ),
             ),

             if (_selectedItems.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), // Padding at the bottom
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    label: Text(
                      "Convert ${_selectedItems.length} to Task(s)",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white
                      ),
                    ),
                    onPressed: _convertTasks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),   
          ],
        ),
      ),
    );
  }
}
