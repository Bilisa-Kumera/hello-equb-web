import 'package:flutter/material.dart';
import '../models/equb_model.dart';

class EqubCard extends StatelessWidget {
  final EqubModel equb;
  const EqubCard({super.key, required this.equb});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Image.asset('assets/car.png', height: 60),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // const Icon(Icons.group, size: 16),
                // const SizedBox(width: 4),
                // Text("${equb.numberOfEqubers}"),
                const SizedBox(width: 10),
                const Icon(Icons.sync_alt, size: 16),
                const SizedBox(width: 4),
                Text("${equb.currentRound} Cycle"),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                "${equb.equbAmount?.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} Birr",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Join Equb",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            )
          ],
        ),
        trailing: Container(
          width: 12,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
