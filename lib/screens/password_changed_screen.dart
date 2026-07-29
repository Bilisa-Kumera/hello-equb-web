import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/screens/complete_profile_screen.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/style_constants.dart';

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
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
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
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 46.0, right: 46),
                child: SizedBox(
                  child: Center(
                    child: Text(
                      textScaleFactor: 1.0,
                      'Almost Done!',
                      style: AppTextStyles.poppins70032
                          .copyWith(color: AppColors.darkBlueGray),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 46.0, right: 46),
                child: Center(
                  child: SizedBox(
                    child: Text(
                      textScaleFactor: 1.0,
                      "You're almost done. Please complete your profile to get full experience.",
                      style: AppTextStyles.poppins50016
                          .copyWith(color: AppColors.coolGray),
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
                    child: Text(
                      textScaleFactor: 1.0,
                      "Skip To Homepage",
                      style: AppTextStyles.poppins40014.copyWith(color: AppColors.vibrantGreen),
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
