import 'package:flutter/material.dart';
import 'package:helloequb/utils/style_constants.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SUZUKI DEZIRE 2022",
                    style: AppTextStyles.poppins70016.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text("Start car equb today",
                    style: AppTextStyles.poppins40014.copyWith(color: Colors.white70)),
                const Spacer(),
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196D6),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text("Join Now"),
                ),
              ],
            ),
          ),
          Image.asset('assets/car.png', height: 100),
        ],
      ),
    );
  }
}
