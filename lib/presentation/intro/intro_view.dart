import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/formatting/widget/white_app_button.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/signup/signup.dart';

class IntroviewPage extends StatelessWidget {
  const IntroviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppLayout.pagePadding(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    height: 500,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/images/introview.png"),
                        fit: BoxFit.fitWidth,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
            
                  const SizedBox(height: 15),
            
                  // Title
                   Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: Text(
                      'Join the KudiKit Tribe and start your journey today!',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 22),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ),
            
                  const SizedBox(height: 30),
            
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Column(
                      children: [
                        ColorAppButton(
                          press: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          text: 'Get started',
                        ),
                        const SizedBox(height: 16),
                        WhiteAppButton(
                          press: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          text: "Login",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
