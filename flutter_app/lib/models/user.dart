// lib/models/user.dart — Modèle Utilisateur
class User {
  final int id;
  final String nom;
  final String email;

  User({required this.id, required this.nom, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:    json['id'] as int,
      nom:   json['nom'] as String,
      email: json['email'] as String,
    );
  }
}