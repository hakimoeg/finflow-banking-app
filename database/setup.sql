-- ============================================================
--  FinFlow Banking App — Script de création SQL Server
--  Base de données : FinFlowDB
-- ============================================================

USE master;
GO

-- Créer la base de données si elle n'existe pas
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FinFlowDB')
BEGIN
    CREATE DATABASE FinFlowDB;
END
GO

USE FinFlowDB;
GO

-- ============================================================
--  NETTOYAGE : Suppression des tables dans le BON ORDRE
--  On supprime les tables enfants avant les tables parents.
-- ============================================================
IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL
    DROP TABLE dbo.Transactions;
GO

IF OBJECT_ID('dbo.Comptes', 'U') IS NOT NULL
    DROP TABLE dbo.Comptes;
GO

IF OBJECT_ID('dbo.Utilisateurs', 'U') IS NOT NULL
    DROP TABLE dbo.Utilisateurs;
GO


-- ============================================================
--  TABLE : Utilisateurs
-- ============================================================
CREATE TABLE dbo.Utilisateurs (
    id                 INT             IDENTITY(1,1)   PRIMARY KEY,
    nom              NVARCHAR(100)   NOT NULL,
    email           NVARCHAR(150)   NOT NULL        UNIQUE,
    mot_de_passe_hashe NVARCHAR(255) NOT NULL,
    date_creation   DATETIME        DEFAULT GETDATE(),
    actif           BIT             DEFAULT 1
);
GO

-- ============================================================
--  TABLE : Comptes
-- ============================================================
CREATE TABLE dbo.Comptes (
    id                 INT             IDENTITY(1,1)   PRIMARY KEY,
    num_compte      NVARCHAR(30)    NOT NULL        UNIQUE, -- Corrigé à 30 pour l'IBAN
    solde           DECIMAL(15, 2)  NOT NULL        DEFAULT 0.00,
    type_compte     NVARCHAR(30)    NOT NULL        CHECK (type_compte IN ('Courant', 'Epargne', 'Credit')),
    utilisateur_id  INT             NOT NULL,
    date_ouverture  DATETIME        DEFAULT GETDATE(),
    actif           BIT             DEFAULT 1,

    CONSTRAINT FK_Comptes_Utilisateurs
        FOREIGN KEY (utilisateur_id)
        REFERENCES dbo.Utilisateurs(id)
        ON DELETE CASCADE
);
GO

-- ============================================================
--  TABLE : Transactions
-- ============================================================
CREATE TABLE dbo.Transactions (
    id                 INT             IDENTITY(1,1)   PRIMARY KEY,
    type            NVARCHAR(20)    NOT NULL        CHECK (type IN ('credit', 'debit', 'virement')),
    montant         DECIMAL(15, 2)  NOT NULL        CHECK (montant > 0),
    date            DATETIME        DEFAULT GETDATE(),
    motif           NVARCHAR(255),
    compte_source_id INT,
    compte_dest_id  INT,

    CONSTRAINT FK_Transactions_Source
        FOREIGN KEY (compte_source_id)
        REFERENCES dbo.Comptes(id),

    CONSTRAINT FK_Transactions_Destination
        FOREIGN KEY (compte_dest_id)
        REFERENCES dbo.Comptes(id),

    CONSTRAINT CHK_Comptes_Differents
        CHECK (compte_source_id <> compte_dest_id)
);
GO

-- ============================================================
--  INDEX pour performance
-- ============================================================
CREATE INDEX IX_Transactions_Source   ON dbo.Transactions(compte_source_id);
CREATE INDEX IX_Transactions_Dest     ON dbo.Transactions(compte_dest_id);
CREATE INDEX IX_Transactions_Date     ON dbo.Transactions(date DESC);
CREATE INDEX IX_Comptes_Utilisateur   ON dbo.Comptes(utilisateur_id);
GO

-- ============================================================
--  DONNÉES DE TEST
-- ============================================================
INSERT INTO dbo.Utilisateurs (nom, email, mot_de_passe_hashe) VALUES
    ('Jean Dupont',   'jean@finflow.io',  '$2b$10$examplehash1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),
    ('Marie Martin',  'marie@finflow.io', '$2b$10$examplehash2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
GO

INSERT INTO dbo.Comptes (num_compte, solde, type_compte, utilisateur_id) VALUES
    ('FR7630006000011234567890189', 8450.30,  'Courant', 1),
    ('FR7630006000011234567890190', 15800.00, 'Epargne', 1),
    ('FR7630006000011234567890191', -1500.30, 'Credit',  1),
    ('FR7630006000011234567890192', 3200.00,  'Courant', 2);
GO

INSERT INTO dbo.Transactions (type, montant, motif, compte_source_id, compte_dest_id) VALUES
    ('credit',   3200.00, 'Salaire Juillet',       NULL, 1),
    ('debit',     950.00, 'Loyer Appartement',      1,   NULL),
    ('debit',     127.40, 'Carrefour Market',        1,   NULL),
    ('credit',     85.00, 'Remboursement Paul',     NULL, 1),
    ('debit',      15.99, 'Netflix',                 1,   NULL),
    ('virement',  500.00, 'Épargne mensuelle',       1,    2);
GO

PRINT 'FinFlowDB initialisée et créée avec succès.';
GO