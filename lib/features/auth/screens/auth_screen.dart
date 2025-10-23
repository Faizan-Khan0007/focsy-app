import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:my_todo_app/common/widgets/custom_textfield.dart';

enum Auth { signin, signup }

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth-screen';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Auth _auth = Auth.signup;
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();
  final AuthService authService = AuthService();
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController =TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose(); // Dispose the correct controller
  }
  void signUpUser() async{
    if (_signUpFormKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match!")),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
     await authService.signUpUserAndSendOTP(
          context: context,
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phoneNumber: _phoneController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void signInUser() async{
    if (_signInFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
    await authService.signInUser(
        context: context,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    await authService.signInWithGoogle(context);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -screenHeight * 0.05,
            left: -screenHeight * 0.1,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: screenHeight * 0.25,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            top: -screenHeight * 0.1,
            left: screenHeight * 0.05,
            child: Opacity(
              opacity: 0.64,
              child: Container(
                width: screenHeight * 0.25,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB7D5DA),
                  //color: Colors.black,
                ),
              ),
            ),
          ),
          Center(
            // Apply padding to shift the image upwards
            child: SingleChildScrollView(
              child: Padding(
                padding: _auth == Auth.signin
                    ? const EdgeInsets.only(top: 100)
                    : const EdgeInsets.only(top: 150),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (_auth == Auth.signup)
                      Form(
                        key: _signUpFormKey,
                        child: Column(
                          children: [
                            Text("Welcome Onboard!",
                                style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ))),
                            SizedBox(
                              height: 20,
                            ),
                            Center(
                              child: Text("Lets help you meet your tasks",
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ))),
                            ),
                            SizedBox(height: 40,),
                            SizedBox(
                                width: 350,
                                child: CustomTextfield(
                                  hinttext: "Username",
                                  controller: _nameController,
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty){
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                )),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: 350,
                              child: CustomTextfield(
                                hinttext: "Email Address",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty){
                                    return 'Please enter your email';
                                  }
                                  final emailRegex = RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                  if (!emailRegex.hasMatch(value.trim())){
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: 350,
                              child: CustomTextfield(
                                  hinttext: "Phone Number",
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty){
                                      return null;
                                    }
                                    final phoneRegex = RegExp(r"^[6-9]\d{9}$");
                                    if (!phoneRegex.hasMatch(value.trim())){
                                      return 'Enter a valid 10-digit number';
                                    }
                                    return null;
                                  }),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                                width: 350,
                                child: CustomTextfield(
                                  hinttext: "Password",
                                  controller: _passwordController,
                                  isObscure: true,
                                  prefixIcon: Icons.lock_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty){
                                      return 'Please enter a password';
                                    }
                                    if (value.trim().length < 6){
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                )),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                                width: 350,
                                child: CustomTextfield(
                                  hinttext: "Confirm Password",
                                  controller: _confirmPasswordController,
                                  isObscure: true,
                                  prefixIcon: Icons.lock_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty){
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text){
                                      return 'Password do not match';
                                    }
                                    return null;
                                  },
                                )),
                            SizedBox(
                              height: 50,
                            ),
                            _isLoading? const CircularProgressIndicator() : ElevatedButton(
                              onPressed: signUpUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6398A7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 100, vertical: 15),
                              ),
                              child: Text("REGISTER",
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ))),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Text("Already have an account ?"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _auth = Auth.signin;
                                      });
                                    },
                                    child: Text(
                                      "Sign In",
                                      style:
                                          TextStyle(color: Color(0xFF0FB0C5)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    if (_auth == Auth.signin)
                      Form(
                          key: _signInFormKey,
                          child: Column(
                            children: [
                              Text("Welcome Back!",
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                  ))),
                              SizedBox(
                                height: 20,
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/signin.png'),
                                      fit: BoxFit
                                          .cover, // Ensures the image covers the container properly
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                              SizedBox(
                                width: 350,
                                child: CustomTextfield(
                                hinttext: "Email Address",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty){
                                    return ' Enter Email Address';
                                  }
                                  final emailRegex = RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                  if (!emailRegex.hasMatch(value.trim())){
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                width: 350,
                                child: CustomTextfield(
                                  controller: _passwordController, hinttext: "Password", isObscure: true, prefixIcon: Icons.lock_outline,
                                validator: (value) { // Added validation
                                  if (value == null || value.trim().isEmpty) return 'Please enter your password';
                                  return null;
                                }
                                  )
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              _isLoading? const CircularProgressIndicator():
                              ElevatedButton(
                                onPressed: signInUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6398A7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 100, vertical: 15),
                                ),
                                child: Text("SIGN IN",
                                    style: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ))),
                              ),
                              const SizedBox(height: 20),
                                     Row( // Divider with OR
                                       children: [
                                         Expanded(child: Divider(color: Colors.grey[300])),
                                         Padding(
                                           padding: const EdgeInsets.symmetric(horizontal: 10),
                                           child: Text("OR", style: TextStyle(color: Colors.grey[500])),
                                         ),
                                         Expanded(child: Divider(color: Colors.grey[300])),
                                       ],
                                     ),
                              const SizedBox(height: 20),       
                              //now google sign in up is missing   
                              SizedBox(
                                width: 300,
                                child: ElevatedButton.icon(
                                  onPressed: _signInWithGoogle,
                                  icon: Image.asset('assets/google-tile.png',height: 20.0,),
                                  label: Text("Sign In with Google", style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  ),
                              ), 
                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Text("Don't have an account ?"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _auth = Auth.signup;
                                        });
                                      },
                                      child: Text(
                                        "Sign Up",
                                        style:
                                            TextStyle(color: Color(0xFF0FB0C5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            ],
                          ),
                          )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
