import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/utils/app_size.dart';
import '../home/privacy_policy_page.dart';
import '../home/terms_of_use_page.dart';
import '../widgets/solo_animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'registration_email_page.dart';

class SoloOnboardingPage extends StatefulWidget {
  const SoloOnboardingPage({super.key});

  @override
  State<SoloOnboardingPage> createState() => _SoloOnboardingPageState();
}

class _SoloOnboardingPageState extends State<SoloOnboardingPage> {

  final PageController controller = PageController();
  final TextEditingController nameController = TextEditingController();
  int page = 0;
  final FocusNode nameFocusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    nameFocusNode.addListener(() {
      setState(() {
        isFocused = nameFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    nameController.dispose();
    super.dispose();
  }

  String _getMascotAsset() {
    if (page == 0) {
      return isFocused ? 'assets/svg/second.svg' : 'assets/svg/first.svg';
    } else if (page == 1 || page == 2) {
      return 'assets/svg/third.svg';
    } else {
      return 'assets/svg/fourth.svg';
    }
  }

  Widget _buildMascot() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SvgPicture.asset(
        _getMascotAsset(),
        key: ValueKey(_getMascotAsset()),
        width: AppSize.w(195.13),
        height: AppSize.w(195.13),
      ),
    );
  }

  void next() {

    if (page < 3) {

      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RegistrationEmailPage(),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    AppSize.init(context);

    return Scaffold(

      backgroundColor: const Color(0xFF88C7CF),

      body: Stack(
        children: [
          PageView(
            controller: controller,

            onPageChanged: (p) {
              setState(() {
                page = p;
              });
            },

            children: [

              pageOne(),
              pageTwo(),
              pageThree(),
              pageFour(),

            ],
          ),

          // Bottom navigation and Footer
          Positioned(
            bottom: AppSize.h(40),
            left: AppSize.w(24),
            right: AppSize.w(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Next",
                      style: TextStyle(
                        fontSize: AppSize.sp(22),
                        color: const Color(0xFF0B3948).withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSize.w(15)),
                    GestureDetector(
                      onTap: next,
                      child: SvgPicture.asset(
                        "assets/svg/nextbutton.svg",
                        height: AppSize.h(64),
                        width: AppSize.h(64),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSize.h(30)),
                Text.rich(
                  TextSpan(
                    text: "By continuing, you agree to our ",
                    children: [
                      TextSpan(
                        text: "Privacy Policy",
                        style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                            );
                          },
                      ),
                      const TextSpan(text: " & "),
                      TextSpan(
                        text: "Terms of Service",
                        style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
                            );
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSize.sp(12),
                    color: const Color(0xFF0B3948).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                // Home Indicator Placeholder (Optional, just for aesthetics in design)
                Container(
                  width: AppSize.w(150),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pageOne() {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(20)),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //SizedBox(height: AppSize.h(60)),

          // Avatar on the right
          Align(
            alignment: Alignment.centerRight,
            child: _buildMascot(),
          ),

       //   SizedBox(height: AppSize.h(10)),

          Text(
            "Hello",
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B3948),
            ),
          ),

          SizedBox(height: AppSize.h(20)),

          // Input field
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w(15)),
            height: AppSize.h(64),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B3948),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                SizedBox(width: AppSize.w(15)),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      hintText: "Add First Name",
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.8),
                        fontSize: AppSize.sp(18),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget pageTwo() {

    return Padding(
      padding: EdgeInsets.all(AppSize.w(24)),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: AppSize.h(60)),

          Align(
            alignment: Alignment.centerRight,
            child: _buildMascot(),
          ),

          SizedBox(height: AppSize.h(10)),

          Text(
            "Hello Ehtesham...",
            style: TextStyle(
              fontSize: AppSize.sp(36),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B3948),
            ),
          ),

        ],
      ),
    );
  }

  Widget pageThree() {

    return Padding(
      padding: EdgeInsets.all(AppSize.w(24)),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: AppSize.h(60)),

          Align(
            alignment: Alignment.centerRight,
            child: _buildMascot(),
          ),

          SizedBox(height: AppSize.h(10)),

          Text(
            "I’m SOLO your daily\nCheck-in Buddy",
            style: TextStyle(
              fontSize: AppSize.sp(28),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B3948),
            ),
          ),

          SizedBox(height: AppSize.h(10)),

          Text(
            "I’ll be here for you",
            style: TextStyle(
              fontSize: AppSize.sp(20),
              color: const Color(0xFF0B3948).withOpacity(0.8),
            ),
          ),

        ],
      ),
    );
  }

  Widget pageFour() {

    return Padding(
      padding: EdgeInsets.all(AppSize.w(24)),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: AppSize.h(60)),

          Align(
            alignment: Alignment.centerRight,
            child: _buildMascot(),
          ),

         // SizedBox(height: AppSize.h(5)),

          Text(
            "How SOLO works",
            style: TextStyle(
              fontSize: AppSize.sp(46), 
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B3948),
            ),
          ),

          SizedBox(height: AppSize.h(20)),

          buildStep("1", "Choose when I check in on you each day"),
          buildStep("2", "Choose when I alert your contacts"),
          buildStep("3", "I alert your contacts by SMS"),
          buildStep("4", "SOS button for emergency"),

        ],
      ),
    );
  }

  Widget buildStep(String number,String text){

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h(16)),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: Colors.black87,
            child: Text(number),
          ),

          SizedBox(width: AppSize.w(10)),

          Expanded(child: Text(text))

        ],
      ),
    );
  }
}