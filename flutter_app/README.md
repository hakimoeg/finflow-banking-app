# ◈ FinFlow — Application Bancaire Mobile

Application bancaire complète Flutter + Node.js + SQL Server.

---

## 📁 Structure du projet

```
finflow/
├── database/
│   └── create_database.sql       ← Script SQL Server complet
│
├── backend/                       ← API REST Node.js/Express
│   ├── server.js                  ← Point d'entrée
│   ├── package.json
│   ├── .env.example               ← Copier en .env
│   ├── config/
│   │   └── database.js            ← Connexion SQL Server (mssql)
│   ├── middleware/
│   │   └── auth.js                ← Vérification JWT
│   └── routes/
│       ├── auth.js                ← POST /api/auth/login
│       └── accounts.js            ← GET /api/accounts/:userId
│
└── flutter/                       ← Application mobile Flutter
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── models/
        │   ├── compte.dart
        │   ├── transaction.dart
        │   └── user.dart
        ├── services/
        │   ├── api_service.dart   ← Service HTTP (fetchComptes, login...)
        │   └── auth_provider.dart ← Gestion d'état (Provider)
        ├── screens/
        │   ├── login_screen.dart
        │   └── dashboard_screen.dart
        └── widgets/
            ├── bank_card_widget.dart
            └── transaction_tile.dart
```

---

## 🚀 Installation

### 1. Base de données SQL Server

```sql
-- Dans SQL Server Management Studio ou Azure Data Studio :
-- Ouvrez database/create_database.sql et exécutez-le
```

### 2. Backend Node.js

```bash
cd backend

# Copier et remplir les variables d'environnement
cp .env.example .env
# Éditez .env avec vos identifiants SQL Server

# Installer les dépendances
npm install

# Lancer en développement
npm run dev

# Lancer en production
npm start
```

**Endpoints disponibles :**

| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/auth/login` | Connexion + retour JWT |
| GET | `/api/accounts/:userId` | Liste des comptes |
| GET | `/api/accounts/:userId/transactions` | Transactions récentes |
| POST | `/api/accounts/transfer` | Effectuer un virement |
| GET | `/api/health` | Vérification du serveur |

### 3. Application Flutter

```bash
cd flutter

# Installer les packages
flutter pub get

# Configurer l'URL de l'API dans lib/services/api_service.dart
# Pour émulateur Android : http://10.0.2.2:3000
# Pour simulateur iOS   : http://localhost:3000
# Pour production        : https://votre-domaine.com

# Lancer l'application
flutter run
```

---

## 🔐 Sécurité

- Mots de passe hashés avec **bcrypt** (coût 10)
- Authentification par **JWT** (expiration 24h)
- Requêtes SQL paramétrées (protection injection SQL)
- Vérification que l'utilisateur ne peut accéder qu'à ses propres comptes
- Virements en **transaction atomique** SQL (rollback si erreur)

---

## 🧪 Compte de test

| Email | Mot de passe |
|-------|-------------|
| jean@finflow.io | secret123 |

> ⚠️ Changez le hash bcrypt dans `create_database.sql` pour un vrai mot de passe en production.
> Générez-le avec : `bcrypt.hashSync('votre_mdp', 10)`