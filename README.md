# 🏦 FinFlow – Application Bancaire Intelligente

FinFlow est une application bancaire moderne composée d'une application mobile **Flutter** et d'un backend **Node.js (Express)** connecté à **SQL Server**. Elle intègre un chatbot **RAG (Retrieval-Augmented Generation)** 100% local propulsé par **Ollama (Llama 3.2)**.

## ✨ Fonctionnalités
- 🔐 **Authentification sécurisée** : Inscription et connexion avec jetons JWT.
- 💼 **Gestion de comptes** : Visualisation des comptes Courant, Épargne et Crédit en temps réel.
- 💸 **Virements bancaires** : Transferts de fonds sécurisés avec gestion de transactions SQL Server (Débit/Crédit atomique).
- 🤖 **Assistant IA Local (RAG)** : Chatbot intelligent connecté à la base de données via Ollama pour répondre précisément aux questions sur les soldes et l'historique de l'utilisateur.

## 🛠️ Technologies utilisées
- **Frontend** : Flutter, Provider (State Management), Intl (Localisation)
- **Backend** : Node.js, Express, JSON Web Tokens (JWT)
- **Base de données** : Microsoft SQL Server (MS SQL)
- **Intelligence Artificielle** : Ollama (Modèle `llama3.2`)

## 🚀 Installation & Lancement

### 1. Backend
```bash
cd backend
npm install
# Configurez votre fichier .env avec vos identifiants SQL Server
node server.js
