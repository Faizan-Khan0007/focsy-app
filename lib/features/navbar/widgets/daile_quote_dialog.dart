import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyQuoteDialog extends StatelessWidget {
  const DailyQuoteDialog({super.key});

  // A hardcoded list of quotes for V1
  static const List<Map<String, String>> _quotes = [
    {
      'quote': 'The secret to getting ahead is getting started.',
      'author': 'Mark Twain',
    },
    {
      'quote': 'You don\'t have to be great to start, but you have to start to be great.',
      'author': 'Zig Ziglar',
    },
    {
      'quote': 'Focus on being productive instead of busy.',
      'author': 'Tim Ferriss',
    },
    {
      'quote': 'A year from now you may wish you had started today.',
      'author': 'Karen Lamb',
    },
    {
      'quote': 'Discipline is the bridge between goals and accomplishment.',
      'author': 'Jim Rohn',
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Pick a random quote
    final randomQuote = _quotes[Random().nextInt(_quotes.length)];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Start Your Day!",
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"${randomQuote['quote']}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "- ${randomQuote['author']}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text(
            "Let's Go!",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}