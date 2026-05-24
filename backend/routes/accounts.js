// routes/accounts.js — Comptes & Transactions
const express = require('express');
const { getPool, sql } = require('../config/database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/accounts/:userId
// Récupère tous les comptes d'un utilisateur avec leur solde
router.get('/:userId', verifyToken, async (req, res) => {
  const { userId } = req.params;

  // Sécurité : un utilisateur ne peut voir que ses propres comptes
  if (parseInt(userId) !== req.user.userId) {
    return res.status(403).json({ error: 'Accès interdit à ces comptes.' });
  }

  try {
    const pool = await getPool();

    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .query(`
        SELECT
          c.id,
          c.num_compte,
          c.solde,
          c.type_compte,
          c.date_ouverture,
          u.nom AS proprietaire
        FROM dbo.Comptes c
        INNER JOIN dbo.Utilisateurs u ON u.id = c.utilisateur_id
        WHERE c.utilisateur_id = @userId AND c.actif = 1
        ORDER BY c.date_ouverture ASC
      `);

    res.status(200).json({
      userId,
      comptes: result.recordset,
      total: result.recordset.length,
    });

  } catch (err) {
    console.error('Erreur /accounts:', err);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des comptes.' });
  }
});

// GET /api/accounts/:userId/transactions
// Récupère les transactions récentes d'un utilisateur
router.get('/:userId/transactions', verifyToken, async (req, res) => {
  const { userId } = req.params;
  const limit = parseInt(req.query.limit) || 20;

  if (parseInt(userId) !== req.user.userId) {
    return res.status(403).json({ error: 'Accès interdit.' });
  }

  try {
    const pool = await getPool();

    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit)
          t.id,
          t.type,
          t.montant,
          t.date,
          t.motif,
          cs.num_compte AS compte_source,
          cd.num_compte AS compte_destination
        FROM dbo.Transactions t
        LEFT JOIN dbo.Comptes cs ON cs.id = t.compte_source_id
        LEFT JOIN dbo.Comptes cd ON cd.id = t.compte_dest_id
        WHERE cs.utilisateur_id = @userId OR cd.utilisateur_id = @userId
        ORDER BY t.date DESC
      `);

    res.status(200).json({
      transactions: result.recordset,
      total: result.recordset.length,
    });

  } catch (err) {
    console.error('Erreur /transactions:', err);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des transactions.' });
  }
});

// POST /api/accounts/transfer
// Effectuer un virement entre deux comptes
router.post('/transfer', verifyToken, async (req, res) => {
  const { compteSourceId, compteDestId, montant, motif } = req.body;

  if (!compteSourceId || !compteDestId || !montant || montant <= 0) {
    return res.status(400).json({ error: 'Paramètres de virement invalides.' });
  }

  try {
    const pool = await getPool();

    // Vérifier le solde suffisant
    const soldeResult = await pool.request()
      .input('id', sql.Int, compteSourceId)
      .query('SELECT solde FROM dbo.Comptes WHERE id = @id AND actif = 1');

    if (soldeResult.recordset.length === 0) {
      return res.status(404).json({ error: 'Compte source introuvable.' });
    }

    const soldeActuel = parseFloat(soldeResult.recordset[0].solde);
    if (soldeActuel < montant) {
      return res.status(400).json({ error: 'Solde insuffisant.' });
    }

    // Transaction atomique
    const transaction = new pool.transaction();
    await transaction.begin();

    try {
      const request = transaction.request();

      // Débiter le compte source
      await request
        .input('montant', sql.Decimal(15, 2), montant)
        .input('sourceId', sql.Int, compteSourceId)
        .query('UPDATE dbo.Comptes SET solde = solde - @montant WHERE id = @sourceId');

      // Créditer le compte destination
      await request
        .input('destId', sql.Int, compteDestId)
        .query('UPDATE dbo.Comptes SET solde = solde + @montant WHERE id = @destId');

      // Enregistrer la transaction
      await request
        .input('motif', sql.NVarChar(255), motif || 'Virement')
        .query(`
          INSERT INTO dbo.Transactions (type, montant, motif, compte_source_id, compte_dest_id)
          VALUES ('virement', @montant, @motif, @sourceId, @destId)
        `);

      await transaction.commit();
      res.status(200).json({ message: 'Virement effectué avec succès.', montant });

    } catch (innerErr) {
      await transaction.rollback();
      throw innerErr;
    }

  } catch (err) {
    console.error('Erreur /transfer:', err);
    res.status(500).json({ error: 'Erreur lors du virement.' });
  }
});

module.exports = router;