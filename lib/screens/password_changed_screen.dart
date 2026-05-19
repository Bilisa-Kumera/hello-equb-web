import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/screens/complete_profile_screen.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/utils/custom_button.dart';

// ignore: must_be_immutable
class JinEkubDetail extends StatelessWidget {
  const JinEkubDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18.0, top: 40),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                      border:
                          Border.all(color: AppColors.lightBlueGray, width: 1)),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_back_ios, color: AppColors.black),
                    ), // Set icon color to black
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(top: 0, left: 26.0, right: 8),
                child: Center(
                  child: SizedBox(
                      width: 228,
                      height: 228,
                      child: Image.asset('assets/almost.png')),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 46.0, right: 46),
                child: SizedBox(
                  child: Center(
                    child: Text(
                      textScaleFactor: 1.0,
                      'Almost Done!',
                      style: TextStyle(
                          color: AppColors.darkBlueGray,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Urbanist',
                          fontSize: 30),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 46.0, right: 46),
                child: Center(
                  child: SizedBox(
                    child: Text(
                      textScaleFactor: 1.0,
                      "You're almost done. Please complete your profile to get full experience.",
                      style: TextStyle(
                          color: AppColors.coolGray,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Urbanist',
                          fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(26.0),
                child: CustomTextButton(
                  text: "Complete Now",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CompleteProfileScreen(
                                  serviceCharge: '',
                                )));
                  },
                  textColor: AppColors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 26.0, right: 26),
                child: SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: TextButton(
                    style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // Match container's border radius
                            side: const BorderSide(
                              width: 1,
                              color: AppColors.vibrantGreen , // Match container's border color
                            ),
                          ),
                        ),
                        backgroundColor:
                            const MaterialStatePropertyAll(AppColors.white),
                        foregroundColor:
                            const MaterialStatePropertyAll(AppColors.white)),
                    child: const Text(
                      textScaleFactor: 1.0,
                      "Skip To Homepage",
                      style: TextStyle(
                        color: AppColors.vibrantGreen,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomeScreen()));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
