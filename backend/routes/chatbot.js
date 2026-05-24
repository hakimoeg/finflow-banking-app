// routes/chatbot.js — Chatbot RAG bancaire (LLM Ollama Local + données SQL en temps réel)
const express = require('express');
const { getPool, sql } = require('../config/database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// ============================================================
//  Fonction RAG : Récupère les données bancaires de l'utilisateur
// ============================================================
async function fetchBankingContext(userId) {
  const pool = await getPool();

  // 1. Infos utilisateur
  const userResult = await pool.request()
    .input('userId', sql.Int, userId)
    .query(`SELECT nom, email FROM dbo.Utilisateurs WHERE id = @userId`);
  const user = userResult.recordset[0];

  // 2. Tous les comptes avec solde
  const comptesResult = await pool.request()
    .input('userId', sql.Int, userId)
    .query(`
      SELECT id, num_compte, solde, type_compte, date_ouverture
      FROM dbo.Comptes
      WHERE utilisateur_id = @userId AND actif = 1
      ORDER BY date_ouverture ASC
    `);
  const comptes = comptesResult.recordset;

  // 3. 10 dernières transactions globales
  const txResult = await pool.request()
    .input('userId', sql.Int, userId)
    .query(`
      SELECT TOP 10 t.type, t.montant, t.date, t.motif, 
                  cs.num_compte AS compte_source, cd.num_compte AS compte_destination
      FROM dbo.Transactions t
      LEFT JOIN dbo.Comptes cs ON cs.id = t.compte_source_id
      LEFT JOIN dbo.Comptes cd ON cd.id = t.compte_dest_id
      WHERE cs.utilisateur_id = @userId OR cd.utilisateur_id = @userId
      ORDER BY t.date DESC
    `);
  const transactions = txResult.recordset;

  // Construction du bloc de texte contextuel
  let contextText = `Nom du client : ${user ? user.nom : 'Inconnu'}\n`;
  contextText += `Email : ${user ? user.email : 'Inconnu'}\n\n`;

  contextText += `=== COMPTES BANCAIRES ===\n`;
  if (comptes.length === 0) contextText += `Aucun compte actif.\n`;
  comptes.forEach(c => {
    contextText += `- Compte ${c.type_compte} (ID: ${c.id}) : N° ${c.num_compte} | Solde: ${c.solde} €\n`;
  });

  contextText += `\n=== HISTORIQUE DES TRANSACTIONS RÉCENTES ===\n`;
  if (transactions.length === 0) contextText += `Aucune transaction récente.\n`;
  transactions.forEach(t => {
    const src = t.compte_source || 'Externe (Crédit)';
    const dst = t.compte_destination || 'Externe (Débit)';
    contextText += `- [${t.date.toISOString().split('T')[0]}] ${t.type.toUpperCase()} de ${t.montant} € | Motif: ${t.motif || 'Aucun'} | De: ${src} -> Vers: ${dst}\n`;
  });

  return contextText;
}

// ============================================================
//  POST /api/chatbot/message — Endpoint principal du bot
// ============================================================
router.post('/message', verifyToken, async (req, res) => {
  const { message, conversationHistory } = req.body; // conversationHistory: [{role: 'user', content: '...'}, {role: 'assistant', content: '...'}]

  if (!message) {
    return res.status(400).json({ error: 'Le champ message est requis.' });
  }

  try {
    // ── ÉTAPE 1 : Récupération du contexte SQL réel (RAG) ──
    const contextText = await fetchBankingContext(req.user.userId);

    // ── ÉTAPE 2 : Alignement du prompt système ──
 // ── ÉTAPE 2 : Alignement du prompt système ──
    const systemPrompt = `Tu es FinFlow AI, un assistant bancaire virtuel intelligent et sécurisé.
Tu as accès aux données réelles et en temps réel du client ci-dessous.
Utilise UNIQUEMENT ces données pour répondre aux questions de l'utilisateur.
Sois concis, professionnel et courtois. Ne mentionne jamais d'informations n'appartenant pas à ce client.
Si l'utilisateur pose une question en dehors du contexte de ses données, dis-le clairement.

${contextText}`;

    // Nettoyage et sécurisation de l'historique pour Ollama
    const cleanHistory = Array.isArray(conversationHistory) 
      ? conversationHistory.filter(msg => msg.role && msg.content) // On retire les messages vides
                           .map(msg => ({
                             role: msg.role === 'assistant' ? 'assistant' : 'user',
                             content: msg.content.toString()
                           }))
      : [];

    const messagesForOllama = [
      { role: 'system', content: systemPrompt },
      ...cleanHistory,
      { role: 'user', content: message.toString() }
    ];

    // ── ÉTAPE 3 : Appel à l'API locale d'Ollama ──
   // ── ÉTAPE 3 : Appel à l'API locale d'Ollama ──
    console.log("🤖 Envoi de la requête à Ollama...");
    const ollamaResponse = await fetch('http://localhost:11434/api/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama3.2', // <-- ON CHANGE LE NOM ICI !
        messages: messagesForOllama,
        stream: false,   
        options: {
          temperature: 0.3
        }
      }),
    });

    if (!ollamaResponse.ok) {
      throw new Error(`Erreur API Ollama: Statut ${ollamaResponse.status}`);
    }

    const ollamaData = await ollamaResponse.json();
    const botReply = ollamaData.message?.content || 'Désolé, je n\'ai pas pu générer une réponse.';

    res.status(200).json({
      reply: botReply,
      model: 'ollama/llama3',
    });

  } catch (err) {
    console.error('Erreur Chatbot (Ollama):', err);
    res.status(500).json({ error: 'Erreur lors de la génération de la réponse du chatbot.' });
  }
});

module.exports = router;