// config/database.js — Connexion SQL Server via mssql
const sql = require('mssql/msnodesqlv8'); 
require('dotenv').config();

const config = {
  server: 'localhost\\SQLEXPRESS01',
  database: process.env.DB_DATABASE || 'FinFlowDB',
  port: parseInt(process.env.DB_PORT) || 1433,
  driver: 'msnodesqlv8',
  options: {
    trustedConnection: true,
    encrypt: false,           // Requis pour Azure SQL
    trustServerCertificate: true, // Pour dev local avec certificat auto-signé
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let pool = null;

// Connexion unique (singleton)
async function getPool() {
  if (!pool) {
    try {
      pool = await sql.connect(config);
      console.log('✅ Connecté à SQL Server — FinFlowDB');
    } catch (err) {
      // CHANGEMENT ICI : On utilise JSON.stringify ou err directement pour tout voir
      console.error('❌ Erreur connexion SQL Server:', JSON.stringify(err, null, 2));
      console.error('Détail brut:', err); 
      throw err;
    }
  }
  return pool;
}

module.exports = { getPool, sql };