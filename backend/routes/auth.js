// routes/auth.js — Authentification (POST /api/auth/login)
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getPool, sql } = require('../config/database');

const router = express.Router();


// POST /api/auth/register — Inscription d'un nouvel utilisateur
// ============================================================
router.post('/register', async (req, res) => {
  const { nom, email, password } = req.body;

  // Validation des champs
  if (!nom || !email || !password) {
    return res.status(400).json({ error: 'Tous les champs (nom, email, password) sont requis.' });
  }

  try {
    const pool = await getPool();

    // 1. Vérifier si l'email existe déjà en base
    const userCheck = await pool.request()
      .input('email', sql.NVarChar(150), email)
      .query('SELECT id FROM dbo.Utilisateurs WHERE email = @email');

    if (userCheck.recordset.length > 0) {
      return res.status(400).json({ error: 'Cet email est déjà utilisé.' });
    }

    // 2. Hacher le mot de passe avec bcryptjs
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // 3. Insérer le nouvel utilisateur dans SQL Server
    await pool.request()
      .input('nom', sql.NVarChar(100), nom)
      .input('email', sql.NVarChar(150), email)
      .input('password', sql.NVarChar(255), passwordHash)
      .query(`
        INSERT INTO dbo.Utilisateurs (nom, email, mot_de_passe_hashe)
        VALUES (@nom, @email, @password)
      `);

    res.status(201).json({ message: 'Utilisateur créé avec succès !' });

  } catch (err) {
    console.error('Erreur /register:', err);
    res.status(500).json({ error: 'Erreur serveur lors de l\'inscription.' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // Validation des champs
  if (!email || !password) {
    return res.status(400).json({ error: 'Email et mot de passe requis.' });
  }

  try {
    const pool = await getPool();

    // Recherche de l'utilisateur par email
    const result = await pool.request()
      .input('email', sql.NVarChar(150), email)
      .query(`
        SELECT id, nom, email, mot_de_passe_hashe, actif
        FROM dbo.Utilisateurs
        WHERE email = @email
      `);

    if (result.recordset.length === 0) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect.' });
    }

    const user = result.recordset[0];

    // Vérifier si le compte est actif
    if (!user.actif) {
      return res.status(403).json({ error: 'Compte désactivé. Contactez le support.' });
    }

    // Vérification du mot de passe avec bcrypt
    const passwordMatch = await bcrypt.compare(password, user.mot_de_passe_hashe);
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect.' });
    }

    // Génération du token JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.status(200).json({
      message: 'Connexion réussie',
      token,
      user: {
        id: user.id,
        nom: user.nom,
        email: user.email,
      },
    });

  } catch (err) {
    console.error('Erreur /login:', err);
    res.status(500).json({ error: 'Erreur serveur. Réessayez plus tard.' });
  }
});

module.exports = router;