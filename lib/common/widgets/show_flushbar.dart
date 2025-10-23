import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

void showTopFlushbar(BuildContext context,String text) {
  Flushbar(
    message: text,
    icon: Icon(
      Icons.info_outline,
      size: 28.0,
      color: Colors.blue[300],
    ),
    duration: const Duration(seconds: 4),
    leftBarIndicatorColor: Colors.blue[300],
    flushbarPosition: FlushbarPosition.TOP, 
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(8),
  ).show(context);
}