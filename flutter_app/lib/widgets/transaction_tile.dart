// lib/widgets/transaction_tile.dart — Élément de transaction
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  IconData get _icon {
    switch (transaction.motif?.toLowerCase()) {
      case String s when s.contains('salaire'): return Icons.work_outline;
      case String s when s.contains('loyer'):   return Icons.home_outlined;
      case String s when s.contains('netflix'): return Icons.movie_outlined;
      case String s when s.contains('virement'): return Icons.swap_horiz;
      default: return transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(transaction.date);
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? const Color(0xFF22C983) : const Color(0xFFE05252);
    final iconBg = isCredit
        ? const Color(0xFF22C983).withOpacity(0.12)
        : const Color(0xFFE05252).withOpacity(0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141D2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2D45).withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(_icon, color: amountColor, size: 18),
        ),
        title: Text(
          transaction.motif ?? 'Opération',
          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          dateStr,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8892A4)),
        ),
        trailing: Text(
          '${isCredit ? "+" : "-"} ${fmt.format(transaction.montant)}',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: amountColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}