// lib/models/compte.dart — Modèle de données Compte
class Compte {
  final int id;
  final String numCompte;
  final double solde;
  final String typeCompte;
  final String proprietaire;
  final DateTime dateOuverture;

  Compte({
    required this.id,
    required this.numCompte,
    required this.solde,
    required this.typeCompte,
    required this.proprietaire,
    required this.dateOuverture,
  });

  // Numéro masqué : **** **** **** 1234
  String get numMasque {
    if (numCompte.length >= 4) {
      return '**** **** **** ${numCompte.substring(numCompte.length - 4)}';
    }
    return numCompte;
  }

  factory Compte.fromJson(Map<String, dynamic> json) {
    return Compte(
      id:            json['id'] as int,
      numCompte:     json['num_compte'] as String,
      solde:         (json['solde'] as num).toDouble(),
      typeCompte:    json['type_compte'] as String,
      proprietaire:  json['proprietaire'] as String? ?? '',
      dateOuverture: DateTime.parse(json['date_ouverture'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'num_compte':     numCompte,
    'solde':          solde,
    'type_compte':    typeCompte,
    'proprietaire':   proprietaire,
    'date_ouverture': dateOuverture.toIso8601String(),
  };
}