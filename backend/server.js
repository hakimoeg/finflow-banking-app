// server.js — Point d'entrée principal de l'API FinFlow
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { getPool } = require('./config/database');

const authRoutes     = require('./routes/auth');
const accountRoutes  = require('./routes/accounts');
const chatbotRoutes  = require('./routes/chatbot');

const app = express();

// ============================================================
//  Middleware globaux
// ============================================================
app.use(cors({
  origin: '*', // En production : restreignez aux domaines autorisés
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log des requêtes (dev)
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
  });
}

// ============================================================
//  Routes
// ============================================================
app.use('/api/auth',     authRoutes);
app.use('/api/accounts', accountRoutes);
app.use('/api/chatbot',  chatbotRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', service: 'FinFlow API', timestamp: new Date().toISOString() });
});

// Route inconnue
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} introuvable.` });
});

// Gestionnaire d'erreurs global
app.use((err, req, res, next) => {
  console.error('Erreur non gérée:', err);
  res.status(500).json({ error: 'Erreur interne du serveur.' });
});

// ============================================================
//  Démarrage du serveur
// ============================================================
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await getPool(); // Teste la connexion SQL au démarrage
    app.listen(PORT, () => {
      console.log(`🚀 FinFlow API démarrée sur http://localhost:${PORT}`);
      console.log(`   Endpoints disponibles :`);
      console.log(`   POST /api/auth/login`);
      console.log(`   GET  /api/accounts/:userId`);
      console.log(`   GET  /api/accounts/:userId/transactions`);
      console.log(`   POST /api/accounts/transfer`);
      console.log(`   POST /api/chatbot/message  ← Chatbot RAG`);
    });
  } catch (err) {
    console.error('❌ Impossible de démarrer le serveur:', err.message);
    process.exit(1);
  }
}

startServer();
