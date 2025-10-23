import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final String hinttext;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isObscure;
  final IconData? prefixIcon;
  final bool isRequired;
   String? Function(String?)? validator;
   CustomTextfield({
    super.key,
    required this.hinttext,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isObscure = false,
    this.prefixIcon,
    this.isRequired=true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboardType,
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hinttext,
        prefixIcon: prefixIcon!=null?Icon(prefixIcon):null,
        hintStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
      validator:validator?? (value) {
        if(!isRequired){
          return null;
        }
        if (value == null || value.isEmpty) {
          return 'Enter your $hinttext';
        }
        return null;
      },
    );
  }
}
