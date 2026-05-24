// lib/models/transaction.dart — Modèle de données Transaction
class Transaction {
  final int id;
  final String type; // 'credit' | 'debit' | 'virement'
  final double montant;
  final DateTime date;
  final String? motif;
  final String? compteSource;
  final String? compteDestination;

  Transaction({
    required this.id,
    required this.type,
    required this.montant,
    required this.date,
    this.motif,
    this.compteSource,
    this.compteDestination,
  });

  bool get isCredit => type == 'credit';
  bool get isDebit  => type == 'debit';

  double get montantAffiche => isDebit ? -montant : montant;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id:                json['id'] as int,
      type:              json['type'] as String,
      montant:           (json['montant'] as num).toDouble(),
      date:              DateTime.parse(json['date'] as String),
      motif:             json['motif'] as String?,
      compteSource:      json['compte_source'] as String?,
      compteDestination: json['compte_destination'] as String?,
    );
  }
}