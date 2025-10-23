// ignore_for_file: sized_box_for_whitespace, prefer_typing_uninitialized_variables, must_be_immutable

import 'package:flutter/material.dart';
import 'package:my_todo_app/widget/my_button.dart';

class DialogBox extends StatelessWidget {
  DialogBox({
    super.key,
    required this.controller,
    required this.onsaved,
    required this.oncancel,
  });
  final controller;
  //saving task
  VoidCallback onsaved;
  VoidCallback oncancel;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.yellow[200],
      content: Container(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Add a new task",
              ),
            ),
            //button->
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                  text: "save",
                  onChanged: onsaved,
                ),
                SizedBox(
                  width: 8,
                ),
                MyButton(text: "cancel", onChanged: oncancel)
              ],
            )
          ],
        ),
      ),
    );
  }
}
