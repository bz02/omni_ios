import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class EnergyDNACard extends StatelessWidget {
  final EnergyDNA dna;

  const EnergyDNACard({super.key, required this.dna});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(dna.colorHex).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(dna.colorHex),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡️ Energy DNA',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dna.type,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(dna.colorHex),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dna.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
