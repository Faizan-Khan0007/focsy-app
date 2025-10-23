// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  MyButton({super.key, required this.text, required this.onChanged});

  String text;
  VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onChanged,
      color: Colors.amber,
      child: Text(text),
    );
  }
}
