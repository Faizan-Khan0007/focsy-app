import 'package:flutter/material.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  static const String routeName='/otp-screen';
  final String phoneNumber;
  const OtpScreen({super.key,required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final AuthService authService=AuthService();
  final TextEditingController _otpController = TextEditingController();
  void verifyOTP(){
    if(_otpController.text.length==6){
      authService.verifyOTP(context: context, otp: _otpController.text);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code.')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22,color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      )
    );
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: ()=>Navigator.of(context).pop(), 
          icon: const Icon(Icons.arrow_back,color: Colors.black,)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Verify your account',
              style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8,),
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              //pinput for otp fields
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color:Theme.of(context).primaryColor),
                  ),
                ),
                onCompleted: (pin) => verifyOTP(),
              ),
              const SizedBox(height: 24,),
              ElevatedButton(
                onPressed: verifyOTP,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code?",
                      style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(onPressed: (){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP Resent!")));
                  }, child: Text(
                    'Resend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ))
                ],
              )
            ],
          ),
        )),
    );
  }
}