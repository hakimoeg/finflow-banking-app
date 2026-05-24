// lib/widgets/bank_card_widget.dart — Widget carte bancaire
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/compte.dart';

class BankCardWidget extends StatelessWidget {
  final Compte compte;

  const BankCardWidget({super.key, required this.compte});

  Color get _cardColor {
    switch (compte.typeCompte) {
      case 'Epargne': return const Color(0xFF0F2318);
      case 'Credit':  return const Color(0xFF1F0F0F);
      default:        return const Color(0xFF111827);
    }
  }

  Color get _badgeColor {
    switch (compte.typeCompte) {
      case 'Epargne': return const Color(0xFF22C983);
      case 'Credit':  return const Color(0xFFE05252);
      default:        return const Color(0xFFC9A84C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isNegative = compte.solde < 0;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              compte.typeCompte.toUpperCase(),
              style: TextStyle(fontSize: 10, color: _badgeColor,
                  fontWeight: FontWeight.w500, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 14),

          // Numéro masqué
          Text(
            compte.numMasque,
            style: const TextStyle(
              fontSize: 13, color: Color(0xFF8892A4),
              letterSpacing: 1.5, fontFamily: 'monospace',
            ),
          ),
          const Spacer(),

          // Solde
          Text('Solde disponible',
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(compte.solde),
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500,
              color: isNegative ? const Color(0xFFE05252) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}