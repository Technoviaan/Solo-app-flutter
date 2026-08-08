import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import '../core/utils/app_size.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(20), vertical: AppSize.h(10)),
              child: const SoloLogo(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSize.h(20)),
                    Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(17)),
                    Text(
                      "How can we\nhelp you today?",
                      style: TextStyle(
                        fontSize: AppSize.sp(40),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: AppSize.h(16)),
                    Text(
                      "We're here to listen. Tell us what you need below and we’ll get back to you soon.",
                      style: TextStyle(
                        fontSize: AppSize.sp(14),
                        color: const Color(0xFF8A99A6),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: AppSize.h(15)),
                    
                    // Subject Field
                    Text.rich(
                      TextSpan(
                        text: "Subject",
                        style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12)),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: subjectController,
                        maxLines: 1,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8A99A6))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E))),
                      ),
                    ),
                    SizedBox(height: AppSize.h(15)),
                    
                    // Description Field
                    Text.rich(
                      TextSpan(
                        text: "Description",
                        style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12)),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color:  Color(0xFF8A99A6))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E))),
                      ),
                    ),
                    SizedBox(height: AppSize.h(14)),
                    Text(
                      "Please include all relevant details so we can assist you better. Maximum length is 500 characters.",
                      style: TextStyle(
                        fontSize: AppSize.sp(10),
                        color: const Color(0xFF8A99A6),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: AppSize.h(24)),
                    
                    // Attachments
                    Text(
                      "Attachments",
                      style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12),fontWeight: FontWeight.w400),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    Container(
                      width: double.infinity,
                      height: AppSize.h(41),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8A99A6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Add file",
                            style: TextStyle(
                              color: const Color(0xFF14B8A6),
                              fontSize: AppSize.sp(9),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          SizedBox(width: AppSize.w(4)),
                          Text(
                            "Click to add a screenshot or photo",
                            style: TextStyle(
                              color: const Color(0xFF8A99A6),
                              fontSize: AppSize.sp(9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSize.h(27)),
                    
                    // Submit Button
                    GestureDetector(
                      onTap: () {
                        // Handle submit
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSize.w(35), vertical: AppSize.h(13)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF002C3E),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSize.sp(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppSize.h(40)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
