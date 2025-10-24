import 'package:flutter/material.dart';
import 'package:my_todo_app/features/profile/screens/profile_screen.dart';
import 'package:my_todo_app/features/routine/screens/routine_screen.dart';
import 'package:my_todo_app/features/tasks/screens/tasks_screen.dart'; 

class NavBarScreen extends StatefulWidget {
  const NavBarScreen({super.key});

  @override
  State<NavBarScreen> createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {
  int _selectedIndex = 0; 

  
  static const List<Widget> _widgetOptions = <Widget>[
    TasksScreen(),    
    RoutineScreen(), 
    ProfileScreen(),  
  ];

  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle), // Icon when selected
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
             activeIcon: Icon(Icons.calendar_today),
            label: 'Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, 
        selectedItemColor: const Color(0xFF6398A7),
        unselectedItemColor: Colors.grey[600], 
        onTap: _onItemTapped, 
        showUnselectedLabels: true, 
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}
